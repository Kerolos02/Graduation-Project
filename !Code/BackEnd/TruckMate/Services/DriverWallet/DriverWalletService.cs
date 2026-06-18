using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using TruckMate.Core.DriverWallet.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.DriverWallet;

public class DriverWalletService : IDriverWalletService
{
    private static readonly TimeSpan SummaryCacheTtl = TimeSpan.FromSeconds(30);
    private readonly IUnitOfWork _uow;
    private readonly IMapper _mapper;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DriverWalletService> _logger;

    public DriverWalletService(IUnitOfWork uow, IMapper mapper, IMemoryCache cache, ILogger<DriverWalletService> logger)
    {
        _uow = uow;
        _mapper = mapper;
        _cache = cache;
        _logger = logger;
    }

    public async Task<DriverWalletScreenResponseDto> GetWalletScreenAsync(Guid driverId, string filter, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var normalized = NormalizeFilter(filter);
        var summary = await GetWalletSummaryAsync(driverId, cancellationToken).ConfigureAwait(false);
        var trips = await GetEarningTripsAsync(driverId, normalized, page, pageSize, cancellationToken).ConfigureAwait(false);

        return new DriverWalletScreenResponseDto
        {
            Summary = summary,
            ActiveFilter = normalized,
            RecentTrips = trips
        };
    }

    public async Task<DriverWalletSummaryResponseDto> GetWalletSummaryAsync(Guid driverId, CancellationToken cancellationToken)
    {
        var cacheKey = BuildSummaryCacheKey(driverId);
        if (_cache.TryGetValue(cacheKey, out DriverWalletSummaryResponseDto? cached) && cached != null)
        {
            _logger.LogDebug("Wallet summary cache hit for driver {DriverId}", driverId);
            return cached;
        }

        var now = DateTime.UtcNow;
        var thisWeekStart = GetStartOfIsoWeekUtc(now);
        var thisMonthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var lastWeekStart = thisWeekStart.AddDays(-7);

        var total = await _uow.DriverEarnings.GetTotalEarningsAsync(driverId, cancellationToken).ConfigureAwait(false);
        var thisWeek = await _uow.DriverEarnings.GetEarningsFromAsync(driverId, thisWeekStart, cancellationToken)
            .ConfigureAwait(false);
        var thisMonth = await _uow.DriverEarnings.GetEarningsFromAsync(driverId, thisMonthStart, cancellationToken)
            .ConfigureAwait(false);
        var lastWeek = await _uow.DriverEarnings
            .GetEarningsBetweenAsync(driverId, lastWeekStart, thisWeekStart, cancellationToken)
            .ConfigureAwait(false);
        var totalTrips = await _uow.DriverEarnings.CountAsync(driverId, null, cancellationToken).ConfigureAwait(false);

        var growthPercent = ComputeGrowthPercent(thisWeek, lastWeek);
        var response = new DriverWalletSummaryResponseDto
        {
            TotalEarningsEGP = decimal.Round(total, 2),
            ThisWeekEarningsEGP = decimal.Round(thisWeek, 2),
            ThisMonthEarningsEGP = decimal.Round(thisMonth, 2),
            TotalTripsCompleted = totalTrips,
            WeeklyGrowthPercent = growthPercent,
            WeeklyGrowthDirection = growthPercent > 0 ? "up" : growthPercent < 0 ? "down" : "neutral"
        };

        _cache.Set(cacheKey, response, SummaryCacheTtl);
        _logger.LogInformation("Computed wallet summary for driver {DriverId}", driverId);
        return response;
    }

    public async Task<DriverWalletTripsResponseDto> GetEarningTripsAsync(Guid driverId, string filter, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var normalizedFilter = NormalizeFilter(filter);
        var fromUtc = ResolveFilterStart(normalizedFilter, DateTime.UtcNow);
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 50);
        var skip = (safePage - 1) * safePageSize;

        var totalCount = await _uow.DriverEarnings.CountAsync(driverId, fromUtc, cancellationToken).ConfigureAwait(false);
        var entities = await _uow.DriverEarnings.GetPagedAsync(driverId, fromUtc, skip, safePageSize, cancellationToken)
            .ConfigureAwait(false);

        var trips = _mapper.Map<List<DriverWalletTripItemDto>>(entities);
        var totalPages = (int)Math.Ceiling(totalCount / (double)safePageSize);
        return new DriverWalletTripsResponseDto
        {
            Filter = normalizedFilter,
            TotalCount = totalCount,
            Page = safePage,
            PageSize = safePageSize,
            TotalPages = totalPages,
            Trips = trips
        };
    }

    public async Task<DriverWalletTripDetailResponseDto?> GetEarningTripDetailAsync(Guid driverId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var earning = await _uow.DriverEarnings.GetByTripIdAsync(driverId, tripId, cancellationToken).ConfigureAwait(false);
        if (earning == null)
        {
            return null;
        }

        return new DriverWalletTripDetailResponseDto
        {
            TripId = earning.TripId,
            ShipmentNumber = earning.ShipmentNumber,
            PickupLocation = earning.PickupLocation,
            DropoffLocation = earning.DropoffLocation,
            EarnedAt = DateTime.SpecifyKind(earning.EarnedAt, DateTimeKind.Utc),
            AmountEGP = decimal.Round(earning.AmountEGP, 2),
            Status = "Completed",
            DistanceKm = decimal.Round(earning.Trip.DistanceKm, 2),
            DurationMinutes = earning.Trip.EstimatedDurationMinutes,
            EstimatedDurationFormatted = FormatDuration(earning.Trip.EstimatedDurationMinutes)
        };
    }

    public async Task CreateEarningRecordAsync(Guid tripId, CancellationToken cancellationToken)
    {
        if (await _uow.DriverEarnings.ExistsByTripIdAsync(tripId, cancellationToken).ConfigureAwait(false))
        {
            _logger.LogDebug("Driver earning already exists for trip {TripId}", tripId);
            return;
        }

        var trip = await _uow.DeliveryTrips.Query()
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == tripId, cancellationToken)
            .ConfigureAwait(false);

        if (trip == null)
        {
            throw new InvalidOperationException("Trip not found.");
        }

        if (trip.Status != CourierTripStatus.Completed)
        {
            throw new InvalidOperationException("Trip must be completed before creating earning.");
        }

        if (!trip.CompletedAtUtc.HasValue)
        {
            throw new InvalidOperationException("Completed trip must have completion timestamp.");
        }

        if (!trip.AssignedDriverId.HasValue)
        {
            throw new InvalidOperationException("Completed trip must have assigned driver.");
        }

        var driver = await _uow.Drivers.Query()
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == trip.AssignedDriverId.Value, cancellationToken)
            .ConfigureAwait(false);

        if (driver == null)
        {
            throw new InvalidOperationException("Assigned driver not found.");
        }

        var earning = new DriverEarning
        {
            Id = Guid.NewGuid(),
            DriverId = driver.PublicId,
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            AmountEGP = decimal.Round(trip.PaymentAmountEGP, 2),
            EarnedAt = DateTime.SpecifyKind(trip.CompletedAtUtc.Value, DateTimeKind.Utc),
            Status = DriverEarningStatus.Pending
        };

        await _uow.DriverEarnings.AddAsync(earning, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        InvalidateSummaryCache(driver.PublicId);
        _logger.LogInformation("Created driver earning for trip {TripId}, driver {DriverPublicId}", tripId, driver.PublicId);
    }

    public async Task<bool> CanAccessTripAsync(Guid driverId, Guid tripId, CancellationToken cancellationToken)
    {
        var any = await _uow.DriverEarnings.GetByTripIdAnyDriverAsync(tripId, cancellationToken).ConfigureAwait(false);
        return any != null && any.DriverId == driverId;
    }

    private static string NormalizeFilter(string filter)
    {
        if (string.IsNullOrWhiteSpace(filter))
        {
            return "all";
        }

        return filter.Trim().ToLowerInvariant();
    }

    private static DateTime? ResolveFilterStart(string filter, DateTime nowUtc)
    {
        return filter switch
        {
            "all" => null,
            "this_week" => GetStartOfIsoWeekUtc(nowUtc),
            "this_month" => new DateTime(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc),
            _ => null
        };
    }

    private static DateTime GetStartOfIsoWeekUtc(DateTime valueUtc)
    {
        var date = valueUtc.Date;
        var day = (int)date.DayOfWeek;
        var diff = day == 0 ? 6 : day - 1;
        return DateTime.SpecifyKind(date.AddDays(-diff), DateTimeKind.Utc);
    }

    private static int ComputeGrowthPercent(decimal thisWeek, decimal lastWeek)
    {
        if (lastWeek == 0m)
        {
            return thisWeek > 0m ? 100 : 0;
        }

        var raw = ((thisWeek - lastWeek) / lastWeek) * 100m;
        return (int)Math.Round(raw, MidpointRounding.AwayFromZero);
    }

    private static string FormatDuration(int minutes)
    {
        var safe = Math.Max(0, minutes);
        var hours = safe / 60;
        var rem = safe % 60;
        if (hours == 0)
        {
            return $"{rem} min";
        }

        if (rem == 0)
        {
            return $"{hours} hr";
        }

        return $"{hours} hr {rem} min";
    }

    private static string BuildSummaryCacheKey(Guid driverId) => $"wallet:summary:{driverId:D}";

    private void InvalidateSummaryCache(Guid driverId) => _cache.Remove(BuildSummaryCacheKey(driverId));
}
