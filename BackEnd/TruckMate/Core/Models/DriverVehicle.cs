using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class DriverVehicle
{
    public Guid Id { get; set; }
    public Guid DriverPublicId { get; set; }
    public Driver Driver { get; set; } = null!;
    public VehicleType Type { get; set; }
    public string Model { get; set; } = string.Empty;
    public string LicensePlate { get; set; } = string.Empty;
}
