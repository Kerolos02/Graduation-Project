namespace TruckMate.Core.Models;

public class DriverDailySummary
{
    public Guid Id { get; set; }

    public int DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public DateOnly SummaryDate { get; set; }

    public int TripsCompleted { get; set; }
    public decimal EarningsEGP { get; set; }
    public int OnlineTimeMinutes { get; set; }
}
