using Microsoft.AspNetCore.SignalR;
using TruckMate.Hubs;

namespace TruckMate.Services.TraderMobile;

public class TraderRealtimePublisher : ITraderRealtimePublisher
{
    private readonly IHubContext<TraderHub> _hubContext;

    public TraderRealtimePublisher(IHubContext<TraderHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public Task PublishShipmentStatusUpdatedAsync(Guid traderId, Guid shipmentId, string newStatus, DateTime occurredAt,
        CancellationToken cancellationToken) =>
        _hubContext.Clients.Group(TraderHub.TraderGroupName(traderId))
            .SendAsync("ShipmentStatusUpdated", new { shipmentId, newStatus, occurredAt }, cancellationToken);

    public Task PublishDriverLocationUpdatedAsync(Guid traderId, Guid shipmentId, double driverLat, double driverLng,
        DateTime updatedAt, CancellationToken cancellationToken) =>
        _hubContext.Clients.Group(TraderHub.TraderGroupName(traderId))
            .SendAsync("DriverLocationUpdated", new { shipmentId, driverLat, driverLng, updatedAt }, cancellationToken);

    public Task PublishInvoicePaidAsync(Guid traderId, Guid invoiceId, DateTime paidAt, string paidWith,
        CancellationToken cancellationToken) =>
        _hubContext.Clients.Group(TraderHub.TraderGroupName(traderId))
            .SendAsync("InvoicePaid", new { invoiceId, paidAt, paidWith }, cancellationToken);

    public Task PublishDeliveryConfirmedAsync(Guid traderId, Guid shipmentId, DateTime confirmedAt,
        CancellationToken cancellationToken) =>
        _hubContext.Clients.Group(TraderHub.TraderGroupName(traderId))
            .SendAsync("DeliveryConfirmed", new { shipmentId, confirmedAt }, cancellationToken);
}
