using TruckMate.Core.Enums;

namespace TruckMate.Core.Models
{
    public class Driver
    {
        public int Id { get; set; }

        /// <summary>Stable public identifier exposed to mobile clients alongside legacy int FK.</summary>
        public Guid PublicId { get; set; } = Guid.NewGuid();

        public string LicenseNumber { get; set; } = string.Empty;

        public string LicenseType { get; set; } = string.Empty;

        public string PlateNumber { get; set; } = string.Empty;

        public string TruckType { get; set; } = string.Empty;

        public double Capacity { get; set; }

        public int UserId { get; set; }

        public People User { get; set; } = null!;

        public string? AvatarUrl { get; set; }

        public decimal Rating { get; set; }
        public int ReviewCount { get; set; }
        public bool IsVerified { get; set; }
        public string AvatarColor { get; set; } = "#00BFA5";
        public VehicleType VehicleType { get; set; } = VehicleType.Van;
        public int TotalTrips { get; set; }
        public int TotalYears { get; set; }
        public double? LastKnownLatitude { get; set; }
        public double? LastKnownLongitude { get; set; }
        public DateTime? LastLocationUpdatedAtUtc { get; set; }

        public DriverAvailabilityStatus AvailabilityStatus { get; set; } = DriverAvailabilityStatus.Offline;

        public string CurrentZone { get; set; } = string.Empty;

        /// <summary>Courier trip currently assigned/in progress for this driver (max one).</summary>
        public Guid? AssignedDeliveryTripId { get; set; }
        public DeliveryTrip? AssignedDeliveryTrip { get; set; }

        /// <summary>Last transition to Online; used together with Offline transitions for session tracking.</summary>
        public DateTime? LastAvailabilityChangeUtc { get; set; }
    }
}
