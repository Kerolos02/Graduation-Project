using TruckMate.Core.Enums;

namespace TruckMate.Core.Models
{
    public class ShipmentRequest
    {
        public int Id { get; set; }

        public int TraderId { get; set; }
        public Trader Trader { get; set; } = null!;

        public string OriginCity { get; set; } = string.Empty;       // Pickup location
        public string DestinationCity { get; set; } = string.Empty;  // Drop-off location

        public DateTime ScheduledDate { get; set; }
        public TimeSpan ScheduledTime { get; set; }

        public int PackageCount { get; set; } = 1;
        public double Weight { get; set; }

        public bool IsFragile { get; set; }
        public bool IsRefrigerated { get; set; }
        public double? MinTemperature { get; set; }
        public double? MaxTemperature { get; set; }

        public string TruckType { get; set; } = string.Empty;
        public string ShipmentId { get; set; } = string.Empty;
        public decimal? FinalCost { get; set; }
        public int? AssignedDriverId { get; set; }
        public Driver? AssignedDriver { get; set; }

        public ShipmentStatus Status { get; set; } = ShipmentStatus.Pending;

        public bool IsReturnTrip { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<Offer> Offers { get; set; } = new List<Offer>();
    }
}
