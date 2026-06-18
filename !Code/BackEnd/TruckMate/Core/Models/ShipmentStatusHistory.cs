using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class ShipmentStatusHistory
{
    public Guid Id { get; set; }
    public Guid ShipmentId { get; set; }
    public DeliveryTrip Shipment { get; set; } = null!;
    public TraderShipmentStatus Status { get; set; }
    public DateTime OccurredAt { get; set; }
    public string? Note { get; set; }
}
