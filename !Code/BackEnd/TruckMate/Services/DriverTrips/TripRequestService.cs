using System.Text.Json;
using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using TruckMate.Common.Exceptions;
using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.DriverTrips.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;
using TruckMate.Data.Helpers;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.Audit;
using TruckMate.Services.DriverHome;

namespace TruckMate.Services.DriverTrips;

public class TripRequestService : ITripRequestService
{
    private readonly TruckMateDbContext _db;
    private readonly IUnitOfWork _uow;
    private readonly IMemoryCache _cache;
    private readonly IMarketplaceRequestCacheBumper _cacheBumper;
    private readonly IDriverMarketplacePublisher _marketplace;
    private readonly IDriverRealtimePublisher _driverRealtime;
    private readonly IAuditLogService _audit;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IMapper _mapper;
    private readonly ILogger<TripRequestService> _logger;

    public TripRequestService(
        TruckMateDbContext db,
        IUnitOfWork uow,
        IMemoryCache cache,
        IMarketplaceRequestCacheBumper cacheBumper,
        IDriverMarketplacePublisher marketplace,
        IDriverRealtimePublisher driverRealtime,
        IAuditLogService audit,
        IHttpContextAccessor httpContextAccessor,
        IMapper mapper,
        ILogger<TripRequestService> logger)
    {
        _db = db;
        _uow = uow;
        _cache = cache;
        _cacheBumper = cacheBumper;
        _marketplace = marketplace;
        _driverRealtime = driverRealtime;
        _audit = audit;
        _httpContextAccessor = httpContextAccessor;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<AvailableTripRequestsResponseDto> GetAvailableRequestsAsync(int userId, string sortBy, int page,
        int pageSize, CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new NotFoundApiException("Driver profile not found.");

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online)
        {
            throw new ForbiddenAccessException("You must be online to browse available requests.");
        }

        if (driver.AssignedDeliveryTripId != null)
        {
            return new AvailableTripRequestsResponseDto
            {
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                Requests = new List<AvailableTripRequestCardDto>()
            };
        }

        var cacheKey =
            $"avail:{_cacheBumper.CurrentVersion}:{driver.PublicId}:{sortBy}:{page}:{pageSize}:{driver.CurrentZone}:{driver.TruckType}";
        if (_cache.TryGetValue(cacheKey, out AvailableTripRequestsResponseDto? cached) && cached != null)
        {
            return cached;
        }

        var (items, total) = await _uow.TripRequests
            .GetOpenForDriverAsync(driver.Id, driver.CurrentZone, driver.TruckType, sortBy, page, pageSize,
                cancellationToken)
            .ConfigureAwait(false);

        var now = DateTime.UtcNow;
        var dto = new AvailableTripRequestsResponseDto
        {
            TotalCount = total,
            Page = page,
            PageSize = pageSize,
            Requests = items.Select(t => new AvailableTripRequestCardDto
            {
                RequestId = t.Id,
                RequestNumber = t.RequestNumber,
                OfferedPaymentEGP = t.PaymentAmountEGP,
                OfferedPaymentFormatted = TripMarketplaceFormatter.FormatPaymentEgp(t.PaymentAmountEGP),
                PickupLocation = t.PickupLocation,
                DropoffLocation = t.DropoffLocation,
                DistanceKm = t.DistanceKm,
                DistanceFormatted = TripMarketplaceFormatter.FormatDistanceKm(t.DistanceKm),
                EstimatedDurationMinutes = t.EstimatedDurationMinutes,
                EstimatedDurationFormatted =
                    TripMarketplaceFormatter.FormatEstimatedDuration(t.EstimatedDurationMinutes),
                WeightLbs = t.WeightLbs,
                WeightFormatted = TripMarketplaceFormatter.FormatWeightLbs(t.WeightLbs),
                CargoType = t.CargoType,
                PostedAt = t.PostedAt,
                PostedAgoFormatted = TripMarketplaceFormatter.FormatPostedAgo(t.PostedAt, now)
            }).ToList()
        };

        _cache.Set(cacheKey, dto, new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(10) });
        return dto;
    }

    public async Task<TripRequestDetailResponseDto> GetRequestDetailAsync(Guid requestId, int userId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new NotFoundApiException("Driver profile not found.");

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online)
        {
            throw new ForbiddenAccessException("You must be online to view request details.");
        }

        var req = await _uow.TripRequests.GetByIdForDetailAsync(requestId, cancellationToken)
            .ConfigureAwait(false);

        if (req == null)
        {
            throw new NotFoundApiException("Request not found.");
        }

        if (await _uow.TripRequests.HasDriverRejectedAsync(requestId, driver.Id, cancellationToken)
                .ConfigureAwait(false))
        {
            throw new NotFoundApiException("Request is not available.");
        }

        if (req.Status == TripRequestStatus.Expired || req.Status == TripRequestStatus.Cancelled)
        {
            throw new GoneApiException("This request is no longer available.");
        }

        if (req.Status == TripRequestStatus.Accepted)
        {
            throw new ConflictApiException(
                req.AcceptedByDriverId == driver.Id
                    ? "You have already accepted this request."
                    : "This request was already accepted by another driver.");
        }

        if (!string.Equals(req.Zone, driver.CurrentZone, StringComparison.OrdinalIgnoreCase))
        {
            throw new NotFoundApiException("Request not found.");
        }

        if (!string.IsNullOrEmpty(req.RequiredTruckType) &&
            !string.Equals(req.RequiredTruckType, driver.TruckType, StringComparison.OrdinalIgnoreCase))
        {
            throw new NotFoundApiException("Request not found.");
        }

        var now = DateTime.UtcNow;
        var phone = string.IsNullOrWhiteSpace(req.Trader.PhoneNumber)
            ? req.Trader.User.Phone
            : req.Trader.PhoneNumber!;

        var canAct = driver.AssignedDeliveryTripId == null;
        return new TripRequestDetailResponseDto
        {
            RequestId = req.Id,
            RequestNumber = req.RequestNumber,
            OfferedPaymentEGP = req.PaymentAmountEGP,
            OfferedPaymentFormatted = TripMarketplaceFormatter.FormatPaymentEgp(req.PaymentAmountEGP),
            PostedAt = req.PostedAt,
            PostedAgoFormatted = TripMarketplaceFormatter.FormatPostedAgo(req.PostedAt, now),
            Route = _mapper.Map<TripRequestRouteDetailDto>(req),
            CargoDetails = _mapper.Map<TripRequestCargoDetailDto>(req),
            Trader = new TripRequestTraderDetailDto
            {
                TraderId = req.Trader.PublicId,
                BusinessName = req.Trader.BusinessName,
                PhoneNumber = phone
            },
            SpecialNotes = req.SpecialNotes,
            Status = req.Status.ToString(),
            CanAccept = canAct,
            CanReject = canAct
        };
    }

    public async Task<AcceptTripRequestResponseDto> AcceptRequestAsync(Guid requestId, int userId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new NotFoundApiException("Driver profile not found.");

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online)
        {
            throw new ConflictApiException("You must be online to accept a request.");
        }

        if (driver.AssignedDeliveryTripId != null)
        {
            throw new ConflictApiException("You already have an active trip.");
        }

        if (await _uow.TripRequests.HasDriverRejectedAsync(requestId, driver.Id, cancellationToken)
                .ConfigureAwait(false))
        {
            throw new ConflictApiException("You have already rejected this request.");
        }

        var snapshot = await _uow.TripRequests.GetByIdAsync(requestId, cancellationToken).ConfigureAwait(false);
        if (snapshot == null)
        {
            throw new NotFoundApiException("Request not found.");
        }

        if (snapshot.Status == TripRequestStatus.Expired || snapshot.Status == TripRequestStatus.Cancelled)
        {
            throw new GoneApiException("This request is no longer available.");
        }

        if (snapshot.Status == TripRequestStatus.Accepted)
        {
            throw new ConflictApiException("This request was just accepted by another driver");
        }

        if (!string.Equals(snapshot.Zone, driver.CurrentZone, StringComparison.OrdinalIgnoreCase))
        {
            throw new ConflictApiException("Your zone does not match this request.");
        }

        if (!string.IsNullOrEmpty(snapshot.RequiredTruckType) &&
            !string.Equals(snapshot.RequiredTruckType, driver.TruckType, StringComparison.OrdinalIgnoreCase))
        {
            throw new ConflictApiException("Your vehicle is not compatible with this request.");
        }

        await using var tx = await _db.Database.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var acceptedAt = DateTime.UtcNow;
            var updated = await _uow.TripRequests.TryMarkAcceptedAsync(requestId, driver.Id, acceptedAt,
                    cancellationToken)
                .ConfigureAwait(false);

            if (updated == 0)
            {
                var again = await _uow.TripRequests.GetByIdAsync(requestId, cancellationToken).ConfigureAwait(false);
                if (again == null)
                {
                    throw new NotFoundApiException("Request not found.");
                }

                if (again.Status == TripRequestStatus.Expired || again.Status == TripRequestStatus.Cancelled)
                {
                    throw new GoneApiException("This request is no longer available.");
                }

                throw new ConflictApiException("This request was just accepted by another driver");
            }

            var req = await _uow.TripRequests.GetByIdTrackedAsync(requestId, cancellationToken).ConfigureAwait(false)
                      ?? throw new InvalidOperationException("Trip request disappeared after accept lock.");

            var nextNumeric = await _uow.DeliveryTrips.GetNextShipmentNumericAsync(cancellationToken)
                .ConfigureAwait(false);
            var tripId = Guid.NewGuid();
            var shipmentNumber = ShipmentNumberFormatter.Format(nextNumeric);

            var trip = new DeliveryTrip
            {
                Id = tripId,
                AssignedDriverId = driver.Id,
                ShipmentNumericId = nextNumeric,
                ShipmentNumber = shipmentNumber,
                Status = CourierTripStatus.Assigned,
                PickupLocation = req.PickupLocation,
                DropoffLocation = req.DropoffLocation,
                DistanceKm = req.DistanceKm,
                EstimatedDurationMinutes = req.EstimatedDurationMinutes,
                PaymentAmountEGP = req.PaymentAmountEGP,
                ScheduleStatus = "Ready to start",
                TraderId = req.TraderId,
                DateUtc = new DateTime(acceptedAt.Year, acceptedAt.Month, acceptedAt.Day, 0, 0, 0, DateTimeKind.Utc),
                AssignedAtUtc = acceptedAt,
                PickupCoordinatesLat = req.PickupLat,
                PickupCoordinatesLng = req.PickupLng,
                DropoffCoordinatesLat = req.DropoffLat,
                DropoffCoordinatesLng = req.DropoffLng,
                PackagesCount = req.PackagesCount,
                TotalWeightLbs = req.WeightLbs,
                Zone = req.Zone,
                OfferedAtUtc = acceptedAt,
                EarningsOnCompletionEgp = req.PaymentAmountEGP
            };

            var shipment = new CourierShipment
            {
                Id = Guid.NewGuid(),
                TripId = tripId,
                ClientName = req.Trader.BusinessName,
                CargoType = req.CargoType,
                WeightLbs = req.WeightLbs,
                IsFragile = req.IsFragile
            };

            await _uow.DeliveryTrips.AddAsync(trip, cancellationToken).ConfigureAwait(false);
            await _db.CourierShipments.AddAsync(shipment, cancellationToken).ConfigureAwait(false);

            driver.AssignedDeliveryTripId = tripId;

            await _db.TripRequests.Where(t => t.Id == requestId)
                .ExecuteUpdateAsync(
                    s => s.SetProperty(t => t.CreatedDeliveryTripId, tripId),
                    cancellationToken)
                .ConfigureAwait(false);

            await _uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
            {
                Id = Guid.NewGuid(),
                DriverId = driver.Id,
                TripOfferId = null,
                TripRequestId = requestId,
                Action = DriverOfferHistoryAction.Accepted,
                TimestampUtc = acceptedAt
            }, cancellationToken).ConfigureAwait(false);

            await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }

        _cacheBumper.Bump();

        var http = _httpContextAccessor.HttpContext;
        var ip = http?.Connection.RemoteIpAddress?.ToString() ?? string.Empty;
        var ua = http?.Request.Headers.UserAgent.ToString() ?? string.Empty;
        await _audit.LogDriverActionAsync(driver.PublicId, "MarketplaceTripRequestAccepted",
            JsonSerializer.Serialize(new { requestId, tripId = driver.AssignedDeliveryTripId }),
            ip, ua, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Driver {DriverId} accepted marketplace request {RequestId}", driver.Id, requestId);

        var reqFinal = await _uow.TripRequests.GetByIdAsync(requestId, cancellationToken).ConfigureAwait(false)
                       ?? throw new InvalidOperationException("Trip request not found after accept.");

        await _marketplace.PublishRequestTakenAsync(reqFinal.Zone, requestId, reqFinal.RequestNumber, cancellationToken)
            .ConfigureAwait(false);
        await _marketplace.PublishDriverAcceptedToTraderAsync(reqFinal.TraderId, driver.User.FullName, DateTime.UtcNow,
                cancellationToken)
            .ConfigureAwait(false);
        await _marketplace.PublishRequestAcceptedToDispatchersAsync(requestId, driver.Id, cancellationToken)
            .ConfigureAwait(false);

        var tripEntity = await _uow.DeliveryTrips.GetByIdWithShipmentAsync(driver.AssignedDeliveryTripId!.Value,
            cancellationToken).ConfigureAwait(false);
        if (tripEntity?.CourierShipment != null)
        {
            await _driverRealtime.PublishTripAssignedAsync(driver.UserId, new TripAssignedSignalPayload
            {
                TripId = tripEntity.Id,
                ShipmentNumber = tripEntity.ShipmentNumber,
                PickupLocation = tripEntity.PickupLocation,
                DropoffLocation = tripEntity.DropoffLocation,
                Shipment = _mapper.Map<ShipmentDetailsDto>(tripEntity.CourierShipment)
            }, cancellationToken).ConfigureAwait(false);
        }

        return new AcceptTripRequestResponseDto
        {
            Acceptance = new TripRequestAcceptanceDto
            {
                RequestId = requestId,
                RequestNumber = reqFinal.RequestNumber,
                TripId = driver.AssignedDeliveryTripId!.Value,
                Route = new TripRequestAcceptanceRouteDto
                {
                    PickupLocation = reqFinal.PickupLocation,
                    DropoffLocation = reqFinal.DropoffLocation
                },
                YoullEarnEGP = reqFinal.PaymentAmountEGP,
                YoullEarnFormatted = TripMarketplaceFormatter.FormatEarnEgp(reqFinal.PaymentAmountEGP),
                NextStep = "Navigate to the pickup location and confirm arrival",
                PickupNavigationUrl =
                    TripMarketplaceFormatter.BuildGoogleMapsUrl(reqFinal.PickupLat, reqFinal.PickupLng)
            }
        };
    }

    public async Task<(string Message, Guid RequestId)> RejectRequestAsync(Guid requestId, int userId,
        string? reason, CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new NotFoundApiException("Driver profile not found.");

        var req = await _uow.TripRequests.GetByIdAsync(requestId, cancellationToken).ConfigureAwait(false);
        if (req == null)
        {
            throw new NotFoundApiException("Request not found.");
        }

        if (req.Status != TripRequestStatus.Open)
        {
            if (req.Status == TripRequestStatus.Expired || req.Status == TripRequestStatus.Cancelled)
            {
                throw new GoneApiException("This request is no longer available.");
            }

            throw new ConflictApiException("This request can no longer be rejected.");
        }

        if (await _uow.TripRequests.HasDriverRejectedAsync(requestId, driver.Id, cancellationToken)
                .ConfigureAwait(false))
        {
            throw new ConflictApiException("You have already rejected this request.");
        }

        await _uow.TripRequests.AddRejectionAsync(new TripRequestRejection
        {
            Id = Guid.NewGuid(),
            TripRequestId = requestId,
            DriverId = driver.Id,
            RejectedAt = DateTime.UtcNow,
            Reason = reason
        }, cancellationToken).ConfigureAwait(false);

        await _uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
        {
            Id = Guid.NewGuid(),
            DriverId = driver.Id,
            TripOfferId = null,
            TripRequestId = requestId,
            Action = DriverOfferHistoryAction.Declined,
            TimestampUtc = DateTime.UtcNow
        }, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _cacheBumper.Bump();

        var http = _httpContextAccessor.HttpContext;
        var ip = http?.Connection.RemoteIpAddress?.ToString() ?? string.Empty;
        var ua = http?.Request.Headers.UserAgent.ToString() ?? string.Empty;
        await _audit.LogDriverActionAsync(driver.PublicId, "MarketplaceTripRequestRejected",
            JsonSerializer.Serialize(new { requestId, reason }),
            ip, ua, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _marketplace.PublishDriverRejectedRequestAsync(requestId, driver.Id, cancellationToken)
            .ConfigureAwait(false);

        _logger.LogInformation("Driver {DriverId} rejected marketplace request {RequestId}", driver.Id, requestId);

        return ("Request rejected", requestId);
    }

    public async Task<MyMarketplaceTripsResponseDto> GetMyTripsAsync(int userId, string status, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new NotFoundApiException("Driver profile not found.");

        var (rows, total) = await _uow.DeliveryTrips
            .GetMyTripsPagedAsync(driver.Id, status, page, pageSize, cancellationToken)
            .ConfigureAwait(false);

        var list = rows.Select(x =>
        {
            var t = x.Trip;
            var reqNo = x.MarketplaceRequestNumber ?? t.ShipmentNumber;
            return new MyMarketplaceTripItemDto
            {
                TripId = t.Id,
                RequestNumber = reqNo,
                Status = t.Status.ToString(),
                StatusLabel = StatusLabel(t.Status),
                PickupLocation = t.PickupLocation,
                DropoffLocation = t.DropoffLocation,
                DistanceKm = t.DistanceKm,
                DistanceFormatted = TripMarketplaceFormatter.FormatDistanceKm(t.DistanceKm),
                EstimatedDurationFormatted = TripMarketplaceFormatter.FormatEstimatedDuration(t.EstimatedDurationMinutes),
                PaymentAmountEGP = t.PaymentAmountEGP,
                PaymentFormatted = TripMarketplaceFormatter.FormatEarnEgp(t.PaymentAmountEGP),
                CargoType = t.CourierShipment?.CargoType ?? string.Empty,
                AcceptedAt = t.AssignedAtUtc,
                AcceptedAtFormatted = t.AssignedAtUtc.HasValue
                    ? TripMarketplaceFormatter.FormatAcceptedAt(t.AssignedAtUtc.Value)
                    : null
            };
        }).ToList();

        return new MyMarketplaceTripsResponseDto
        {
            TotalCount = total,
            Page = page,
            PageSize = pageSize,
            Trips = list
        };
    }

    private static string StatusLabel(CourierTripStatus status) =>
        status switch
        {
            CourierTripStatus.Pending => "Pending",
            CourierTripStatus.Offered => "Offered",
            CourierTripStatus.Assigned => "Assigned",
            CourierTripStatus.InProgress => "In Progress",
            CourierTripStatus.Completed => "Completed",
            CourierTripStatus.Cancelled => "Cancelled",
            _ => status.ToString()
        };
}
