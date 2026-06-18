namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletScreenResponseDto
{
    public string Title { get; set; } = "My Wallet";
    public string Subtitle { get; set; } = "Track your earnings and trip income";
    public DriverWalletSummaryResponseDto Summary { get; set; } = new();
    public string ActiveFilter { get; set; } = "all";
    public List<string> Filters { get; set; } = ["all", "this_week", "this_month"];
    public string RecentTripsLabel { get; set; } = "Recent Trips";
    public DriverWalletTripsResponseDto RecentTrips { get; set; } = new();
}
