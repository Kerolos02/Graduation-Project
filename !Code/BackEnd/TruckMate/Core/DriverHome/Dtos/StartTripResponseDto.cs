namespace TruckMate.Core.DriverHome.Dtos;

public class StartTripResponseDto
{
    public Guid TripId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
}
