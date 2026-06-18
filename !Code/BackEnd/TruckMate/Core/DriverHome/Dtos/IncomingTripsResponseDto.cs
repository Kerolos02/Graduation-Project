namespace TruckMate.Core.DriverHome.Dtos;

public class IncomingTripsResponseDto
{
    public List<IncomingTripOfferDto> Trips { get; set; } = new();
}

public class IncomingTripOfferDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public bool IsFragile { get; set; }
    public DateTime OfferedAt { get; set; }
}
