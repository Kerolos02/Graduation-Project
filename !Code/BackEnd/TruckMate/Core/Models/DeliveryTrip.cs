using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class DeliveryTrip
{
    public Guid Id { get; set; }

    public int? AssignedDriverId { get; set; }
    public Driver? AssignedDriver { get; set; }
    public int ShipmentNumericId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public CourierTripStatus Status { get; set; } = CourierTripStatus.Pending;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public decimal PaymentAmountEGP { get; set; }
    public string ScheduleStatus { get; set; } = string.Empty;
    public int TraderId { get; set; }
    public Trader Trader { get; set; } = null!;
    public DateTime DateUtc { get; set; }
    public TimeSpan? ScheduledStartTime { get; set; }
    public DateTime? StartedAtUtc { get; set; }
    public DateTime? PickedUpAtUtc { get; set; }
    public DateTime? InTransitAtUtc { get; set; }
    public DateTime? CompletedAtUtc { get; set; }
    public DateTime? CancelledAtUtc { get; set; }
    public DateTime? AssignedAtUtc { get; set; }
    public DateTime? EstimatedDeliveryTimeUtc { get; set; }
    public double? PickupCoordinatesLat { get; set; }
    public double? PickupCoordinatesLng { get; set; }
    public double? DropoffCoordinatesLat { get; set; }
    public double? DropoffCoordinatesLng { get; set; }
    public int PackagesCount { get; set; }
    public decimal TotalWeightLbs { get; set; }
    public string Zone { get; set; } = string.Empty;
    public DateTime OfferedAtUtc { get; set; }
    public decimal EarningsOnCompletionEgp { get; set; }
    public CourierShipment? CourierShipment { get; set; }
}
