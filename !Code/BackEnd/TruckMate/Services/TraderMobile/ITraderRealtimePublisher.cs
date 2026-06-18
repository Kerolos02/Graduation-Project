namespace TruckMate.Services.TraderMobile;

public interface ITraderRealtimePublisher
{
    Task PublishShipmentStatusUpdatedAsync(Guid traderId, Guid shipmentId, string newStatus, DateTime occurredAt,
        CancellationToken cancellationToken);
    Task PublishDriverLocationUpdatedAsync(Guid traderId, Guid shipmentId, double driverLat, double driverLng,
        DateTime updatedAt, CancellationToken cancellationToken);
    Task PublishInvoicePaidAsync(Guid traderId, Guid invoiceId, DateTime paidAt, string paidWith,
        CancellationToken cancellationToken);
    Task PublishDeliveryConfirmedAsync(Guid traderId, Guid shipmentId, DateTime confirmedAt,
        CancellationToken cancellationToken);
}
