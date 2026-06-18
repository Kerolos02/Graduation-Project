using TruckMate.Core.Enums;

namespace TruckMate.Core.Models
{
    public class Trip
    {
        public int Id { get; set; }

        public int ShipmentRequestId { get; set; }
        public ShipmentRequest ShipmentRequest { get; set; } = null!;

        public int DriverId { get; set; }
        public Driver Driver { get; set; } = null!;

        public int OfferId { get; set; }
        public Offer Offer { get; set; } = null!;

        public TripStatus Status { get; set; } = TripStatus.created;

        public DateTime StartedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }
}
