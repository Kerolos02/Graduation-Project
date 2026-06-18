using System.ComponentModel.DataAnnotations;

namespace TruckMate.Core.Shipments
{
    public class CreateShipmentRequestDto
    {
        [Required]
        [StringLength(200)]
        public string PickupLocation { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string DropOffLocation { get; set; } = string.Empty;

        [Required]
        public DateTime ScheduledDate { get; set; }

        [Required]
        public TimeSpan ScheduledTime { get; set; }

        [Range(1, 1000)]
        public int PackageCount { get; set; } = 1;

        [Range(0.1, 10000)]
        public double Weight { get; set; }

        public bool IsFragile { get; set; }
        public bool IsRefrigerated { get; set; }

        [Range(-50, 50)]
        public double? MinTemperature { get; set; }

        [Range(-50, 50)]
        public double? MaxTemperature { get; set; }
    }
}
