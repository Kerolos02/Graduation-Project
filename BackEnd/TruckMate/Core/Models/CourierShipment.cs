namespace TruckMate.Core.Models;

public class CourierShipment
{
    public Guid Id { get; set; }

    public Guid TripId { get; set; }
    public DeliveryTrip Trip { get; set; } = null!;

    public string ClientName { get; set; } = string.Empty;
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public bool IsFragile { get; set; }
}
