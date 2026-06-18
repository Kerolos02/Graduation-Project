namespace TruckMate.Core.DriverTrips.Dtos;

public class AvailableTripRequestsResponseDto
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AvailableTripRequestCardDto> Requests { get; set; } = new();
}

public class AvailableTripRequestCardDto
{
    public Guid RequestId { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public decimal OfferedPaymentEGP { get; set; }
    public string OfferedPaymentFormatted { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public string DistanceFormatted { get; set; } = string.Empty;
    public int EstimatedDurationMinutes { get; set; }
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public string WeightFormatted { get; set; } = string.Empty;
    public string CargoType { get; set; } = string.Empty;
    public DateTime PostedAt { get; set; }
    public string PostedAgoFormatted { get; set; } = string.Empty;
}

public class TripRequestDetailResponseDto
{
    public Guid RequestId { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public decimal OfferedPaymentEGP { get; set; }
    public string OfferedPaymentFormatted { get; set; } = string.Empty;
    public DateTime PostedAt { get; set; }
    public string PostedAgoFormatted { get; set; } = string.Empty;
    public TripRequestRouteDetailDto Route { get; set; } = null!;
    public TripRequestCargoDetailDto CargoDetails { get; set; } = null!;
    public TripRequestTraderDetailDto Trader { get; set; } = null!;
    public string? SpecialNotes { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool CanAccept { get; set; }
    public bool CanReject { get; set; }
}

public class TripRequestRouteDetailDto
{
    public string PickupLocation { get; set; } = string.Empty;
    public string PickupAddress { get; set; } = string.Empty;
    public double PickupLat { get; set; }
    public double PickupLng { get; set; }
    public string DropoffLocation { get; set; } = string.Empty;
    public string DropoffAddress { get; set; } = string.Empty;
    public double DropoffLat { get; set; }
    public double DropoffLng { get; set; }
    public decimal DistanceKm { get; set; }
    public string DistanceFormatted { get; set; } = string.Empty;
    public int EstimatedDurationMinutes { get; set; }
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
}

public class TripRequestCargoDetailDto
{
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public string WeightFormatted { get; set; } = string.Empty;
    public int PackagesCount { get; set; }
    public string PackagesUnit { get; set; } = string.Empty;
    public string PackagesFormatted { get; set; } = string.Empty;
    public bool IsFragile { get; set; }
}

public class TripRequestTraderDetailDto
{
    public Guid TraderId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
}

public class AcceptTripRequestResponseDto
{
    public TripRequestAcceptanceDto Acceptance { get; set; } = null!;
}

public class TripRequestAcceptanceDto
{
    public Guid RequestId { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public Guid TripId { get; set; }
    public TripRequestAcceptanceRouteDto Route { get; set; } = null!;
    public decimal YoullEarnEGP { get; set; }
    public string YoullEarnFormatted { get; set; } = string.Empty;
    public string NextStep { get; set; } = string.Empty;
    public string PickupNavigationUrl { get; set; } = string.Empty;
}

public class TripRequestAcceptanceRouteDto
{
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
}

public class RejectTripRequestRequestDto
{
    public string? Reason { get; set; }
}

public class RejectTripRequestResponseDto
{
    public Guid RequestId { get; set; }
}

public class MyMarketplaceTripsResponseDto
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<MyMarketplaceTripItemDto> Trips { get; set; } = new();
}

public class MyMarketplaceTripItemDto
{
    public Guid TripId { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusLabel { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public string DistanceFormatted { get; set; } = string.Empty;
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
    public decimal PaymentAmountEGP { get; set; }
    public string PaymentFormatted { get; set; } = string.Empty;
    public string CargoType { get; set; } = string.Empty;
    public DateTime? AcceptedAt { get; set; }
    public string? AcceptedAtFormatted { get; set; }
}
