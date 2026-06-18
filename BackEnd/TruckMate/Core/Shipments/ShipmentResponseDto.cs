using TruckMate.Core.Enums;

namespace TruckMate.Core.Shipments
{
    public class ShipmentResponseDto
    {
        public int Id { get; set; }
        public string ShipmentId { get; set; } = string.Empty;
        public string PickupLocation { get; set; } = string.Empty;
        public string DropOffLocation { get; set; } = string.Empty;
        public DateTime ScheduledDate { get; set; }
        public TimeSpan ScheduledTime { get; set; }
        public int PackageCount { get; set; }
        public double Weight { get; set; }
        public string VehicleType { get; set; } = string.Empty;
        public decimal? FinalCost { get; set; }
        public ShipmentStatus Status { get; set; }
        public string? DriverName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
