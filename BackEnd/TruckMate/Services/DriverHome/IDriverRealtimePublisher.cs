using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.DriverOffers.Dtos;

namespace TruckMate.Services.DriverHome;

public interface IDriverRealtimePublisher
{
    /// <summary>Notifies the dispatcher dashboard that a driver toggled availability.</summary>
    Task PublishDriverAvailabilityChangedAsync(int userId, string status, CancellationToken cancellationToken);

    /// <summary>Notifies a specific driver that a trip was assigned.</summary>
    Task PublishTripAssignedAsync(int userId, TripAssignedSignalPayload payload, CancellationToken cancellationToken);

    /// <summary>Announces a new pending trip for drivers in a zone (online clients should filter client-side).</summary>
    Task PublishTripOfferAsync(string zone, TripOfferSignalPayload payload, CancellationToken cancellationToken);

    /// <summary>Dispatcher + monitoring: trip moved to InProgress.</summary>
    Task PublishTripStartedAsync(Guid tripId, int driverDbId, DateTime startedAtUtc, CancellationToken cancellationToken);

    Task PublishNewTripOfferAsync(int userId, IncomingDriverOfferDto payload, CancellationToken cancellationToken);
    Task PublishTripOfferExpiredAsync(int userId, Guid offerId, Guid tripId, string reason, CancellationToken cancellationToken);
    Task PublishTripAcceptedAsync(int userId, Guid offerId, Guid tripId, AcceptOfferResponseDto payload,
        CancellationToken cancellationToken);
    Task PublishTripOfferCancelledForOtherDriversAsync(Guid tripId, Guid acceptedOfferId, string reason,
        CancellationToken cancellationToken);
    Task PublishDispatcherDriverAcceptedTripAsync(int driverId, Guid tripId, CancellationToken cancellationToken);
    Task PublishTraderDriverAssignedAsync(int traderId, string driverName, Guid tripId, string eta,
        CancellationToken cancellationToken);
    Task PublishDispatcherDriverDeclinedTripAsync(int driverId, Guid tripId, CancellationToken cancellationToken);
    Task PublishNoDriversAvailableAsync(Guid tripId, CancellationToken cancellationToken);
    Task PublishTripOfferExpiredByReasonAsync(Guid tripId, string reason, CancellationToken cancellationToken);
}

public class TripAssignedSignalPayload
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public ShipmentDetailsDto Shipment { get; set; } = null!;
}

public class TripOfferSignalPayload
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
}
