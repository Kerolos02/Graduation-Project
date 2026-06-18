using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class TripRequest
{
    public Guid Id { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public int TraderId { get; set; }
    public Trader Trader { get; set; } = null!;
    public TripRequestStatus Status { get; set; } = TripRequestStatus.Open;
    public string PickupLocation { get; set; } = string.Empty;
    public string PickupAddress { get; set; } = string.Empty;
    public double PickupLat { get; set; }
    public double PickupLng { get; set; }
    public string DropoffLocation { get; set; } = string.Empty;
    public string DropoffAddress { get; set; } = string.Empty;
    public double DropoffLat { get; set; }
    public double DropoffLng { get; set; }
    public decimal DistanceKm { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public decimal PaymentAmountEGP { get; set; }
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public int PackagesCount { get; set; }
    public string PackagesUnit { get; set; } = "pallets";
    public bool IsFragile { get; set; }
    public string? SpecialNotes { get; set; }
    public DateTime PostedAt { get; set; }
    public int? AcceptedByDriverId { get; set; }
    public Driver? AcceptedByDriver { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public string Zone { get; set; } = string.Empty;
    public string? RequiredTruckType { get; set; }
    public Guid? CreatedDeliveryTripId { get; set; }
    public DeliveryTrip? CreatedDeliveryTrip { get; set; }
    public ICollection<TripRequestRejection> Rejections { get; set; } = new List<TripRequestRejection>();
}
