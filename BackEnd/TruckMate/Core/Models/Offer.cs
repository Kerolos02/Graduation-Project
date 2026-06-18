using TruckMate.Core.Enums;

namespace TruckMate.Core.Models
{
    public class Offer
    {
        public int Id { get; set; }
        public int ShipmentRequestId { get; set; }
        public ShipmentRequest ShipmentRequest { get; set; } = null!;

        public int DriverId { get; set; }
        public Driver Driver { get; set; } = null!;

        public decimal Price { get; set; }

        public OfferStatus Status { get; set; } = OfferStatus.pending;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    }
}
