using Microsoft.AspNetCore.SignalR;
using TruckMate.Core.DriverOffers.Dtos;
using TruckMate.Hubs;

namespace TruckMate.Services.DriverHome;

public class DriverRealtimePublisher : IDriverRealtimePublisher
{
    private readonly IHubContext<DriverHub> _hub;
    private readonly IDriverNotificationPreferenceGate _gate;

    public DriverRealtimePublisher(IHubContext<DriverHub> hub, IDriverNotificationPreferenceGate gate)
    {
        _hub = hub;
        _gate = gate;
    }

    public Task PublishDriverAvailabilityChangedAsync(int userId, string status,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("DriverAvailabilityChanged", new { userId, status }, cancellationToken);

    public async Task PublishTripAssignedAsync(int userId, TripAssignedSignalPayload payload,
        CancellationToken cancellationToken)
    {
        if (!await _gate.CanSendTripAssignedForUserAsync(userId, cancellationToken).ConfigureAwait(false))
        {
            return;
        }

        await _hub.Clients.Group(DriverHub.DriverUserGroupName(userId))
            .SendAsync("TripAssigned", payload, cancellationToken).ConfigureAwait(false);
    }

    public Task PublishTripOfferAsync(string zone, TripOfferSignalPayload payload,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.OperationalZoneGroupName(zone))
            .SendAsync("TripOffer", payload, cancellationToken);

    public Task PublishTripStartedAsync(Guid tripId, int driverDbId, DateTime startedAtUtc,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName).SendAsync("CourierTripStarted",
            new { tripId, driverDbId, startedAtUtc },
            cancellationToken);

    public Task PublishNewTripOfferAsync(int userId, IncomingDriverOfferDto payload, CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DriverUserGroupName(userId))
            .SendAsync("NewTripOffer", payload, cancellationToken);

    public Task PublishTripOfferExpiredAsync(int userId, Guid offerId, Guid tripId, string reason,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DriverUserGroupName(userId))
            .SendAsync("TripOfferExpired", new { offerId, tripId, reason }, cancellationToken);

    public Task PublishTripAcceptedAsync(int userId, Guid offerId, Guid tripId, AcceptOfferResponseDto payload,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DriverUserGroupName(userId))
            .SendAsync("TripAccepted", new { offerId, tripId, fullTripDetails = payload }, cancellationToken);

    public Task PublishTripOfferCancelledForOtherDriversAsync(Guid tripId, Guid acceptedOfferId, string reason,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("TripOfferCancelled", new { tripId, acceptedOfferId, reason }, cancellationToken);

    public Task PublishDispatcherDriverAcceptedTripAsync(int driverId, Guid tripId, CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("DriverAcceptedTrip", new { driverId, tripId }, cancellationToken);

    public Task PublishTraderDriverAssignedAsync(int traderId, string driverName, Guid tripId, string eta,
        CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.TraderGroupName(traderId))
            .SendAsync("DriverAssigned", new { driverName, tripId, eta }, cancellationToken);

    public Task PublishDispatcherDriverDeclinedTripAsync(int driverId, Guid tripId, CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("DriverDeclinedTrip", new { driverId, tripId }, cancellationToken);

    public Task PublishNoDriversAvailableAsync(Guid tripId, CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("NoDriversAvailable", new { tripId }, cancellationToken);

    public Task PublishTripOfferExpiredByReasonAsync(Guid tripId, string reason, CancellationToken cancellationToken) =>
        _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("TripOfferExpired", new { tripId, reason }, cancellationToken);
}
