using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using TruckMate.Core.DriverOffers.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.DriverHome;

public class DriverOfferService : IDriverOfferService
{
    private const int OfferLifetimeSeconds = 45;
    private readonly IUnitOfWork _uow;
    private readonly TruckMateDbContext _db;
    private readonly ITripDispatchService _dispatchService;
    private readonly IDriverRealtimePublisher _realtime;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DriverOfferService> _logger;

    public DriverOfferService(IUnitOfWork uow, TruckMateDbContext db, ITripDispatchService dispatchService,
        IDriverRealtimePublisher realtime, IMemoryCache cache, ILogger<DriverOfferService> logger)
    {
        _uow = uow;
        _db = db;
        _dispatchService = dispatchService;
        _realtime = realtime;
        _cache = cache;
        _logger = logger;
    }

    public async Task<CurrentDriverOfferResponseDto> GetCurrentOfferAsync(int userId, CancellationToken cancellationToken)
    {
        var driver = await GetDriverOrThrowAsync(userId, cancellationToken).ConfigureAwait(false);
        var pending = await _uow.TripOffers.GetPendingByDriverIdAsync(driver.Id, cancellationToken).ConfigureAwait(false);
        if (pending == null)
        {
            return BuildNoRequestState(driver);
        }

        if (pending.ExpiresAtUtc <= DateTime.UtcNow)
        {
            await ExpireOfferIfStillPendingAsync(pending.Id, cancellationToken).ConfigureAwait(false);
            return BuildNoRequestState(driver);
        }

        CacheCountdown(pending.Id, pending.ExpiresAtUtc);
        return new CurrentDriverOfferResponseDto { HasOffer = true, Offer = MapIncomingOffer(pending) };
    }

    public async Task<AcceptOfferResponseDto> AcceptOfferAsync(int userId, Guid offerId, CancellationToken cancellationToken)
    {
        var driver = await GetDriverOrThrowAsync(userId, cancellationToken).ConfigureAwait(false);
        if (driver.AssignedDeliveryTripId != null)
        {
            throw new InvalidOperationException("DRIVER_HAS_ACTIVE_TRIP");
        }

        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken)
            .ConfigureAwait(false);

        var offer = await _uow.TripOffers.GetByIdTrackedAsync(offerId, cancellationToken).ConfigureAwait(false);
        if (offer == null || offer.DriverId != driver.Id)
        {
            throw new KeyNotFoundException("OFFER_NOT_FOUND");
        }

        if (offer.Status != TripOfferStatus.Pending)
        {
            throw new InvalidOperationException("OFFER_NOT_PENDING");
        }

        if (offer.ExpiresAtUtc <= DateTime.UtcNow)
        {
            throw new InvalidOperationException("OFFER_EXPIRED");
        }

        var trip = offer.Trip;
        if (trip.Status == CourierTripStatus.Cancelled)
        {
            throw new InvalidOperationException("TRIP_CANCELLED");
        }

        if (trip.AssignedDriverId != null && trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("TRIP_ALREADY_ASSIGNED");
        }

        offer.Status = TripOfferStatus.Accepted;
        offer.RespondedAtUtc = DateTime.UtcNow;
        trip.Status = CourierTripStatus.Assigned;
        trip.AssignedDriverId = driver.Id;
        driver.AssignedDeliveryTripId = trip.Id;

        await _uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
        {
            Id = Guid.NewGuid(),
            DriverId = driver.Id,
            TripOfferId = offer.Id,
            Action = DriverOfferHistoryAction.Accepted,
            TimestampUtc = DateTime.UtcNow
        }, cancellationToken).ConfigureAwait(false);

        await _uow.DriverAuditLogs.AddAsync(new DriverAuditLog
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driver.PublicId,
            Action = "OfferAccepted",
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = "system",
            UserAgent = "backend",
            AdditionalData = $"offerId={offer.Id};tripId={trip.Id}"
        }, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _uow.TripOffers.MarkPendingByTripAsCancelledAsync(trip.Id, offer.Id, "AssignedToOther", DateTime.UtcNow,
            cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await tx.CommitAsync(cancellationToken).ConfigureAwait(false);

        if (trip.CourierShipment != null)
        {
            await _realtime.PublishTripAcceptedAsync(driver.UserId, offer.Id, trip.Id, MapAcceptResponse(trip),
                cancellationToken).ConfigureAwait(false);
        }

        await _realtime.PublishDispatcherDriverAcceptedTripAsync(driver.Id, trip.Id, cancellationToken).ConfigureAwait(false);
        await _realtime.PublishTraderDriverAssignedAsync(trip.TraderId, driver.User.FullName, trip.Id,
            FormatDuration(trip.EstimatedDurationMinutes), cancellationToken).ConfigureAwait(false);
        await _realtime.PublishTripOfferCancelledForOtherDriversAsync(trip.Id, offer.Id, "AssignedToOther",
            cancellationToken).ConfigureAwait(false);

        return MapAcceptResponse(trip);
    }

    public async Task<DriverOfferStatusCardDto> DeclineOfferAsync(int userId, Guid offerId, string? reason,
        CancellationToken cancellationToken)
    {
        var driver = await GetDriverOrThrowAsync(userId, cancellationToken).ConfigureAwait(false);
        var offer = await _uow.TripOffers.GetByIdTrackedAsync(offerId, cancellationToken).ConfigureAwait(false);
        if (offer == null || offer.DriverId != driver.Id)
        {
            throw new KeyNotFoundException("OFFER_NOT_FOUND");
        }

        if (offer.Status != TripOfferStatus.Pending)
        {
            throw new InvalidOperationException("OFFER_NOT_PENDING");
        }

        offer.Status = TripOfferStatus.Declined;
        offer.RespondedAtUtc = DateTime.UtcNow;
        offer.DeclineReason = reason;

        await _uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
        {
            Id = Guid.NewGuid(),
            DriverId = driver.Id,
            TripOfferId = offer.Id,
            Action = DriverOfferHistoryAction.Declined,
            TimestampUtc = DateTime.UtcNow
        }, cancellationToken).ConfigureAwait(false);

        await _uow.DriverAuditLogs.AddAsync(new DriverAuditLog
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driver.PublicId,
            Action = "OfferDeclined",
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = "system",
            UserAgent = "backend",
            AdditionalData = $"offerId={offer.Id};tripId={offer.TripId};reason={reason}"
        }, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _realtime.PublishDispatcherDriverDeclinedTripAsync(driver.Id, offer.TripId, cancellationToken)
            .ConfigureAwait(false);
        await _dispatchService.ReDispatchTripAsync(offer.TripId, driver.Id, cancellationToken).ConfigureAwait(false);

        return new DriverOfferStatusCardDto
        {
            IsOnline = driver.AvailabilityStatus == DriverAvailabilityStatus.Online,
            CurrentZone = driver.CurrentZone,
            Message = "You're Online & Ready"
        };
    }

    public async Task<OfferStatusResponseDto> GetOfferStatusAsync(int userId, Guid offerId, CancellationToken cancellationToken)
    {
        var driver = await GetDriverOrThrowAsync(userId, cancellationToken).ConfigureAwait(false);
        var offer = await _uow.TripOffers.GetByIdForDriverAsync(offerId, driver.Id, cancellationToken).ConfigureAwait(false);
        if (offer == null)
        {
            throw new KeyNotFoundException("OFFER_NOT_FOUND");
        }

        if (offer.Status == TripOfferStatus.Pending && offer.ExpiresAtUtc <= DateTime.UtcNow)
        {
            await ExpireOfferIfStillPendingAsync(offer.Id, cancellationToken).ConfigureAwait(false);
            offer = await _uow.TripOffers.GetByIdForDriverAsync(offerId, driver.Id, cancellationToken).ConfigureAwait(false);
            if (offer == null)
            {
                throw new KeyNotFoundException("OFFER_NOT_FOUND");
            }
        }

        return new OfferStatusResponseDto
        {
            OfferId = offer.Id,
            Status = offer.Status,
            SecondsRemaining = GetSecondsRemaining(offer.ExpiresAtUtc),
            ExpiredReason = offer.Status == TripOfferStatus.Cancelled
                ? (offer.CancelReason == "TraderCancelled" ? "TraderCancelled" : "AssignedToOther")
                : offer.Status == TripOfferStatus.Expired ? "Timeout" : null
        };
    }

    private async Task<Driver> GetDriverOrThrowAsync(int userId, CancellationToken cancellationToken)
    {
        return await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
               ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");
    }

    private async Task ExpireOfferIfStillPendingAsync(Guid offerId, CancellationToken cancellationToken)
    {
        var changed = await _uow.TripOffers.ExecuteExpirePendingAsync(offerId, DateTime.UtcNow, cancellationToken)
            .ConfigureAwait(false);
        if (changed > 0)
        {
            _logger.LogInformation("Offer {OfferId} auto-expired from read path.", offerId);
        }
    }

    private CurrentDriverOfferResponseDto BuildNoRequestState(Driver driver)
    {
        return new CurrentDriverOfferResponseDto
        {
            HasOffer = false,
            Offer = null,
            DriverStatus = new DriverOfferStatusCardDto
            {
                IsOnline = driver.AvailabilityStatus == DriverAvailabilityStatus.Online,
                CurrentZone = driver.CurrentZone,
                Message = "You're Online & Ready"
            }
        };
    }

    private IncomingDriverOfferDto MapIncomingOffer(TripOffer offer)
    {
        var shipment = offer.Trip.CourierShipment;
        return new IncomingDriverOfferDto
        {
            OfferId = offer.Id,
            TripId = offer.TripId,
            ShipmentNumber = offer.Trip.ShipmentNumber,
            PickupLocation = offer.Trip.PickupLocation,
            DropoffLocation = offer.Trip.DropoffLocation,
            DistanceKm = offer.Trip.DistanceKm,
            EstimatedDurationMinutes = offer.Trip.EstimatedDurationMinutes,
            EstimatedDurationFormatted = FormatDuration(offer.Trip.EstimatedDurationMinutes),
            PaymentAmountEGP = offer.Trip.PaymentAmountEGP,
            Shipment = new ShipmentSnapshotDto
            {
                CargoType = shipment?.CargoType ?? string.Empty,
                WeightLbs = shipment?.WeightLbs ?? 0,
                IsFragile = shipment?.IsFragile ?? false
            },
            Trader = new TraderSnapshotDto { BusinessName = offer.Trip.Trader.BusinessName },
            ExpiresAt = offer.ExpiresAtUtc,
            SecondsRemaining = GetSecondsRemaining(offer.ExpiresAtUtc)
        };
    }

    private AcceptOfferResponseDto MapAcceptResponse(DeliveryTrip trip)
    {
        return new AcceptOfferResponseDto
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            Status = CourierTripStatus.Assigned.ToString(),
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            PaymentAmountEGP = trip.PaymentAmountEGP,
            Shipment = new ShipmentSnapshotDto
            {
                CargoType = trip.CourierShipment?.CargoType ?? string.Empty,
                WeightLbs = trip.CourierShipment?.WeightLbs ?? 0,
                IsFragile = trip.CourierShipment?.IsFragile ?? false
            }
        };
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

    private static int GetSecondsRemaining(DateTime expiresAtUtc)
    {
        var seconds = (int)Math.Floor((expiresAtUtc - DateTime.UtcNow).TotalSeconds);
        return Math.Max(0, seconds);
    }

    private void CacheCountdown(Guid offerId, DateTime expiresAtUtc)
    {
        _cache.Set($"offer:{offerId}:expires", expiresAtUtc, TimeSpan.FromSeconds(OfferLifetimeSeconds));
    }
}
