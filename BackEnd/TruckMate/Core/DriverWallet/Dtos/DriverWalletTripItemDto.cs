namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletTripItemDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public DateTime EarnedAt { get; set; }
    public string EarnedAtFormatted { get; set; } = string.Empty;
    public decimal AmountEGP { get; set; }
    public string AmountFormatted { get; set; } = string.Empty;
    public string Status { get; set; } = "Completed";
}
