using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class DriverEarning
{
    public Guid Id { get; set; }
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;
    public Guid TripId { get; set; }
    public DeliveryTrip Trip { get; set; } = null!;
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal AmountEGP { get; set; }
    public DateTime EarnedAt { get; set; }
    public DriverEarningStatus Status { get; set; } = DriverEarningStatus.Pending;
}
