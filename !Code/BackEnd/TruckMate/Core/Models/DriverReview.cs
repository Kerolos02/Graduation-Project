namespace TruckMate.Core.Models;

public class DriverReview
{
    public Guid Id { get; set; }
    public Guid DriverPublicId { get; set; }
    public Driver Driver { get; set; } = null!;
    public Guid TraderPublicId { get; set; }
    public Trader Trader { get; set; } = null!;
    public string TraderName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime ReviewedAt { get; set; }
    public Guid TripId { get; set; }
}
