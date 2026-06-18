using TruckMate.Core.Enums;

namespace TruckMate.Core.DriverOffers.Dtos;

public class CurrentDriverOfferResponseDto
{
    public bool HasOffer { get; set; }
    public IncomingDriverOfferDto? Offer { get; set; }
    public DriverOfferStatusCardDto? DriverStatus { get; set; }
}

public class IncomingDriverOfferDto
{
    public Guid OfferId { get; set; }
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Badge { get; set; } = "NEW SHIPMENT REQUEST";
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
    public decimal PaymentAmountEGP { get; set; }
    public ShipmentSnapshotDto Shipment { get; set; } = new();
    public TraderSnapshotDto Trader { get; set; } = new();
    public DateTime ExpiresAt { get; set; }
    public int SecondsRemaining { get; set; }
}

public class ShipmentSnapshotDto
{
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public bool IsFragile { get; set; }
}

public class TraderSnapshotDto
{
    public string BusinessName { get; set; } = string.Empty;
}

public class DriverOfferStatusCardDto
{
    public bool IsOnline { get; set; }
    public string CurrentZone { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class AcceptOfferResponseDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal PaymentAmountEGP { get; set; }
    public ShipmentSnapshotDto Shipment { get; set; } = new();
}

public class DeclineOfferRequestDto
{
    public string? Reason { get; set; }
}

public class OfferStatusResponseDto
{
    public Guid OfferId { get; set; }
    public TripOfferStatus Status { get; set; }
    public int SecondsRemaining { get; set; }
    public string? ExpiredReason { get; set; }
}
