namespace TruckMate.Core.DriverHome.Dtos;

public class TripDetailsResponseDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public string ScheduleStatus { get; set; } = string.Empty;
    public ShipmentDetailsDto Shipment { get; set; } = null!;
    public string Status { get; set; } = string.Empty;
}
