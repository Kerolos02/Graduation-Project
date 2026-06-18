namespace TruckMate.Core.DriverHome.Dtos;

public class DriverTripExecutionScreenDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string ScreenState { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public int EtaMinutes { get; set; }
    public string EtaFormatted { get; set; } = string.Empty;
    public DriverTripExecutionDriverDto Driver { get; set; } = new();
    public DriverTripExecutionShipmentDto Shipment { get; set; } = new();
    public DriverTripExecutionActionsDto Actions { get; set; } = new();
}

public class DriverTripExecutionDriverDto
{
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
}

public class DriverTripExecutionShipmentDto
{
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public int PackagesCount { get; set; }
}

public class DriverTripExecutionActionsDto
{
    public bool CanMarkArrived { get; set; }
    public bool CanConfirmPickup { get; set; }
    public bool CanStartDelivery { get; set; }
    public bool CanMarkDelivered { get; set; }
    public bool CanCompleteTrip { get; set; }
}
