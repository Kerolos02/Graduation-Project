using System.ComponentModel.DataAnnotations;

namespace TruckMate.Core.Shipments
{
    public class ConfirmShipmentDto
    {
        [Required]
        [StringLength(100)]
        public string VehicleType { get; set; } = string.Empty;

        public decimal FinalCost { get; set; }

        public int DriverId { get; set; }
    }
}
