namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletSummaryResponseDto
{
    public decimal TotalEarningsEGP { get; set; }
    public int WeeklyGrowthPercent { get; set; }
    public string WeeklyGrowthDirection { get; set; } = "neutral";
    public decimal ThisWeekEarningsEGP { get; set; }
    public decimal ThisMonthEarningsEGP { get; set; }
    public int TotalTripsCompleted { get; set; }
}
