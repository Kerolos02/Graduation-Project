namespace TruckMate.Core.Models;

public class TripRequestRejection
{
    public Guid Id { get; set; }

    public Guid TripRequestId { get; set; }
    public TripRequest TripRequest { get; set; } = null!;

    public int DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public DateTime RejectedAt { get; set; }
    public string? Reason { get; set; }
}
