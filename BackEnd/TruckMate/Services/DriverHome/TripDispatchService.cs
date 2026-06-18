using Microsoft.EntityFrameworkCore;
using TruckMate.Core.DriverOffers.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.DriverHome;

public class TripDispatchService : ITripDispatchService
{
    private readonly IUnitOfWork _uow;
    private readonly IDriverRealtimePublisher _realtime;
    private readonly ILogger<TripDispatchService> _logger;

    public TripDispatchService(IUnitOfWork uow, IDriverRealtimePublisher realtime, ILogger<TripDispatchService> logger)
    {
        _uow = uow;
        _realtime = realtime;
        _logger = logger;
    }

    public Task DispatchTripToDriverAsync(Guid tripId, CancellationToken cancellationToken) =>
        DispatchInternalAsync(tripId, null, cancellationToken);

    public Task ReDispatchTripAsync(Guid tripId, int excludeDriverId, CancellationToken cancellationToken) =>
        DispatchInternalAsync(tripId, excludeDriverId, cancellationToken);

    public async Task CancelAllOffersForTripAsync(Guid tripId, string reason, CancellationToken cancellationToken)
    {
        var pending = await _uow.TripOffers.GetPendingByTripIdAsync(tripId, cancellationToken).ConfigureAwait(false);
        var now = DateTime.UtcNow;
        foreach (var offer in pending)
        {
            offer.Status = TripOfferStatus.Cancelled;
            offer.RespondedAtUtc = now;
            offer.CancelReason = reason;

            await _uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
            {
                Id = Guid.NewGuid(),
                DriverId = offer.DriverId,
                TripOfferId = offer.Id,
                Action = DriverOfferHistoryAction.Cancelled,
                TimestampUtc = now
            }, cancellationToken).ConfigureAwait(false);
        }

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _realtime.PublishTripOfferExpiredByReasonAsync(tripId, reason, cancellationToken).ConfigureAwait(false);
    }

    public async Task AssignDriverToShipmentAsync(Guid tripId, Guid driverPublicId, CancellationToken cancellationToken)
    {
        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken).ConfigureAwait(false)
                   ?? throw new InvalidOperationException("Shipment not found.");

        var driver = await _uow.Drivers.Query()
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.PublicId == driverPublicId, cancellationToken)
            .ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver not found.");

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online || driver.AssignedDeliveryTripId != null)
        {
            throw new InvalidOperationException("Driver is not available.");
        }

        trip.AssignedDriverId = driver.Id;
        trip.AssignedAtUtc = DateTime.UtcNow;
        trip.Status = CourierTripStatus.Assigned;
        driver.AssignedDeliveryTripId = trip.Id;

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _realtime.PublishTripAssignedAsync(driver.UserId, new TripAssignedSignalPayload
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation
        }, cancellationToken).ConfigureAwait(false);
    }

    private async Task DispatchInternalAsync(Guid tripId, int? excludeDriverId, CancellationToken cancellationToken)
    {
        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken).ConfigureAwait(false);
        if (trip == null || trip.Status == CourierTripStatus.Cancelled)
        {
            return;
        }

        var candidateQuery = _uow.Drivers.Query()
            .Include(x => x.User)
            .Where(x =>
                x.AvailabilityStatus == DriverAvailabilityStatus.Online &&
                x.AssignedDeliveryTripId == null &&
                x.CurrentZone == trip.Zone);

        if (excludeDriverId.HasValue)
        {
            candidateQuery = candidateQuery.Where(x => x.Id != excludeDriverId.Value);
        }

        var candidates = await candidateQuery
            .OrderByDescending(x => x.Rating)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        Driver? selected = null;
        foreach (var candidate in candidates)
        {
            if (await _uow.TripOffers.HasPendingOfferForDriverAsync(candidate.Id, cancellationToken).ConfigureAwait(false))
            {
                continue;
            }

            if (await _uow.TripOffers.DriverDeclinedTripBeforeAsync(candidate.Id, tripId, cancellationToken)
                .ConfigureAwait(false))
            {
                continue;
            }

            selected = candidate;
            break;
        }

        if (selected == null)
        {
            trip.Status = CourierTripStatus.Pending;
            await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            await _realtime.PublishNoDriversAvailableAsync(tripId, cancellationToken).ConfigureAwait(false);
            _logger.LogInformation("No available drivers for trip {TripId}", tripId);
            return;
        }

        var now = DateTime.UtcNow;
        var offer = new TripOffer
        {
            Id = Guid.NewGuid(),
            TripId = tripId,
            DriverId = selected.Id,
            OfferedAtUtc = now,
            ExpiresAtUtc = now.AddSeconds(45),
            Status = TripOfferStatus.Pending
        };

        trip.Status = CourierTripStatus.Pending == trip.Status ? CourierTripStatus.Offered : trip.Status;
        await _uow.TripOffers.AddAsync(offer, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _uow.DriverAuditLogs.AddAsync(new DriverAuditLog
        {
            Id = Guid.NewGuid(),
            DriverPublicId = selected.PublicId,
            Action = "OfferCreated",
            PerformedAtUtc = now,
            IpAddress = "system",
            UserAgent = "backend",
            AdditionalData = $"offerId={offer.Id};tripId={tripId}"
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _realtime.PublishNewTripOfferAsync(selected.UserId, BuildSignalPayload(offer, trip), cancellationToken)
            .ConfigureAwait(false);
    }

    private static IncomingDriverOfferDto BuildSignalPayload(TripOffer offer, DeliveryTrip trip)
    {
        return new IncomingDriverOfferDto
        {
            OfferId = offer.Id,
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            DistanceKm = trip.DistanceKm,
            EstimatedDurationMinutes = trip.EstimatedDurationMinutes,
            EstimatedDurationFormatted = FormatDuration(trip.EstimatedDurationMinutes),
            PaymentAmountEGP = trip.PaymentAmountEGP,
            ExpiresAt = offer.ExpiresAtUtc,
            SecondsRemaining = 45,
            Shipment = new ShipmentSnapshotDto
            {
                CargoType = trip.CourierShipment?.CargoType ?? string.Empty,
                WeightLbs = trip.CourierShipment?.WeightLbs ?? 0,
                IsFragile = trip.CourierShipment?.IsFragile ?? false
            },
            Trader = new TraderSnapshotDto { BusinessName = trip.Trader.BusinessName }
        };
    }

    private static string FormatDuration(int minutes)
    {
        var safe = Math.Max(0, minutes);
        var hours = safe / 60;
        var rem = safe % 60;
        return rem == 0 ? $"{hours} hr" : $"{hours} hr {rem} min";
    }
}
