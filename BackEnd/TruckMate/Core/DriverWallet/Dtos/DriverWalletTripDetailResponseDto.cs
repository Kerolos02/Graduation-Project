namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletTripDetailResponseDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public DateTime EarnedAt { get; set; }
    public decimal AmountEGP { get; set; }
    public string Status { get; set; } = "Completed";
    public decimal DistanceKm { get; set; }
    public int DurationMinutes { get; set; }
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
}
