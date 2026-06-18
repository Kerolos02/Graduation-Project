namespace TruckMate.Core.TraderMobile.Dtos;

public class SuggestedDriversResponseDto
{
    public Guid ShipmentId { get; set; }
    public int AvailableCount { get; set; }
    public List<SuggestedDriverItemDto> Drivers { get; set; } = new();
}

public class SuggestedDriverItemDto
{
    public Guid DriverId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string AvatarColor { get; set; } = "#00BFA5";
    public bool IsBestMatch { get; set; }
    public decimal Rating { get; set; }
    public int ReviewCount { get; set; }
    public decimal DistanceKm { get; set; }
    public string VehicleType { get; set; } = string.Empty;
    public string VehicleTypeLabel { get; set; } = string.Empty;
    public decimal TotalCostEGP { get; set; }
    public bool IsVerified { get; set; }
}

public class DriverDetailsResponseDto
{
    public Guid DriverId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string AvatarColor { get; set; } = "#00BFA5";
    public bool IsVerified { get; set; }
    public decimal Rating { get; set; }
    public int ReviewCount { get; set; }
    public decimal TotalCostEGP { get; set; }
    public int TotalTrips { get; set; }
    public int TotalYears { get; set; }
    public decimal DistanceKm { get; set; }
    public DriverVehicleDto Vehicle { get; set; } = new();
    public List<DriverRecentReviewDto> RecentReviews { get; set; } = new();
}

public class DriverVehicleDto
{
    public string Type { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string LicensePlate { get; set; } = string.Empty;
}

public class DriverRecentReviewDto
{
    public Guid ReviewId { get; set; }
    public string TraderName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public string ReviewedAt { get; set; } = string.Empty;
}

public class SelectDriverRequestDto
{
    public Guid DriverId { get; set; }
}

public class SelectDriverResponseDto
{
    public Guid ShipmentId { get; set; }
    public Guid DriverId { get; set; }
    public string DriverName { get; set; } = string.Empty;
    public DateTime EstimatedPickupAt { get; set; }
    public Guid InvoiceId { get; set; }
}

public class ShipmentTrackingResponseDto
{
    public Guid ShipmentId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusLabel { get; set; } = string.Empty;
    public int EstimatedTimeRemainingMinutes { get; set; }
    public DriverLocationDto DriverLocation { get; set; } = new();
    public TrackingRouteDto Route { get; set; } = new();
    public List<TrackingTimelineStepDto> Timeline { get; set; } = new();
    public TrackingActionsDto Actions { get; set; } = new();
}

public class DriverLocationDto
{
    public double Lat { get; set; }
    public double Lng { get; set; }
    public DateTime? LastUpdatedAt { get; set; }
}

public class TrackingRouteDto
{
    public double PickupLat { get; set; }
    public double PickupLng { get; set; }
    public double DropoffLat { get; set; }
    public double DropoffLng { get; set; }
}

public class TrackingTimelineStepDto
{
    public int Step { get; set; }
    public string Label { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? OccurredAt { get; set; }
}

public class TrackingActionsDto
{
    public bool CanMarkDelivered { get; set; }
    public bool CanCancelShipment { get; set; }
}

public class CancelShipmentRequestDto
{
    public string? Reason { get; set; }
}

public class DeliverySummaryResponseDto
{
    public Guid ShipmentId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public DateTime DeliveredAt { get; set; }
    public string DeliveredAtFormatted { get; set; } = string.Empty;
    public string From { get; set; } = string.Empty;
    public string To { get; set; } = string.Empty;
    public DeliveryDriverDto Driver { get; set; } = new();
    public Guid InvoiceId { get; set; }
    public bool CanRate { get; set; }
}

public class DeliveryDriverDto
{
    public Guid DriverId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string AvatarColor { get; set; } = "#00BFA5";
    public bool HasBeenRated { get; set; }
}

public class RateDriverRequestDto
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
}

public class InvoiceDetailsResponseDto
{
    public Guid InvoiceId { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public string InvoiceDate { get; set; } = string.Empty;
    public Guid ShipmentId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public InvoiceRouteDto Route { get; set; } = new();
    public InvoiceShipmentDetailsDto ShipmentDetails { get; set; } = new();
    public InvoiceDriverDto Driver { get; set; } = new();
    public InvoicePricingDto Pricing { get; set; } = new();
    public string Status { get; set; } = string.Empty;
    public string? PaidWith { get; set; }
    public bool CanPay { get; set; }
    public bool CanDownloadPdf { get; set; }
    public bool CanShare { get; set; }
}

public class InvoiceRouteDto
{
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
}

public class InvoiceShipmentDetailsDto
{
    public decimal DistanceKm { get; set; }
    public int PackagesCount { get; set; }
    public decimal TotalWeightLbs { get; set; }
}

public class InvoiceDriverDto
{
    public string FullName { get; set; } = string.Empty;
    public string VehicleType { get; set; } = string.Empty;
    public string LicensePlate { get; set; } = string.Empty;
}

public class InvoicePricingDto
{
    public decimal BasePriceEGP { get; set; }
    public decimal ServiceFeeEGP { get; set; }
    public decimal TaxEGP { get; set; }
    public decimal TotalAmountEGP { get; set; }
}

public class PayInvoiceRequestDto
{
    public Guid PaymentCardId { get; set; }
}

public class ShareInvoiceRequestDto
{
    public string Method { get; set; } = string.Empty;
}

public class TraderWalletResponseDto
{
    public decimal BalanceEGP { get; set; }
    public decimal TotalSpentEGP { get; set; }
    public List<SavedCardDto> SavedCards { get; set; } = new();
}

public class SavedCardDto
{
    public Guid CardId { get; set; }
    public string CardBrand { get; set; } = string.Empty;
    public string Last4Digits { get; set; } = string.Empty;
    public int ExpiryMonth { get; set; }
    public int ExpiryYear { get; set; }
    public bool IsDefault { get; set; }
    public string CardBrandLogoUrl { get; set; } = string.Empty;
}

public class AddCardRequestDto
{
    public string CardHolderName { get; set; } = string.Empty;
    public string CardNumber { get; set; } = string.Empty;
    public int ExpiryMonth { get; set; }
    public int ExpiryYear { get; set; }
    public string Cvv { get; set; } = string.Empty;
}

public class TraderHomeCurrentShipmentResponseDto
{
    public string TraderName { get; set; } = string.Empty;
    public CurrentShipmentCardDto? CurrentShipment { get; set; }
    public TraderQuickInsightsDto QuickInsights { get; set; } = new();
    public List<TraderRecentActivityDto> RecentActivity { get; set; } = new();
}

public class CurrentShipmentCardDto
{
    public Guid ShipmentId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string RouteFrom { get; set; } = string.Empty;
    public string RouteTo { get; set; } = string.Empty;
    public string DriverName { get; set; } = string.Empty;
    public decimal TotalCostEGP { get; set; }
}

public class TraderQuickInsightsDto
{
    public decimal AvgTimeHours { get; set; }
    public decimal AvgCostEGP { get; set; }
    public int CompletedShipments { get; set; }
}

public class TraderRecentActivityDto
{
    public Guid ShipmentId { get; set; }
    public string Route { get; set; } = string.Empty;
    public string DateLabel { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class TraderShipmentDetailsResponseDto
{
    public Guid ShipmentId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public List<TrackingTimelineStepDto> Timeline { get; set; } = new();
    public string RouteFrom { get; set; } = string.Empty;
    public string RouteTo { get; set; } = string.Empty;
    public string DateLabel { get; set; } = string.Empty;
    public string TimeLabel { get; set; } = string.Empty;
    public int PackagesCount { get; set; }
    public decimal WeightLbs { get; set; }
    public ShipmentDetailsDriverDto Driver { get; set; } = new();
    public decimal TotalCostEGP { get; set; }
}

public class ShipmentDetailsDriverDto
{
    public Guid? DriverId { get; set; }
    public string DriverName { get; set; } = "Pending Assignment";
    public string Type { get; set; } = "TBD";
    public string Model { get; set; } = "TBD";
    public string LicensePlate { get; set; } = "TBD";
}

public class DriverOffersResponseDto
{
    public Guid ShipmentId { get; set; }
    public string Tab { get; set; } = "pending";
    public int TotalCount { get; set; }
    public List<DriverOfferItemDto> Offers { get; set; } = new();
}

public class DriverOfferItemDto
{
    public Guid OfferId { get; set; }
    public Guid DriverId { get; set; }
    public string DriverName { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public decimal Rating { get; set; }
    public int ReviewCount { get; set; }
    public string VehicleTypeLabel { get; set; } = string.Empty;
    public decimal OfferPriceEGP { get; set; }
    public int EtaMinutes { get; set; }
    public string Status { get; set; } = string.Empty;
}
