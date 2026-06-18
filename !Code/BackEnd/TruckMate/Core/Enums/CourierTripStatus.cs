namespace TruckMate.Core.Enums;

/// <summary>Lifecycle for courier-facing delivery trips (driver mobile app).</summary>
public enum CourierTripStatus
{
    Pending = 0,
    Offered = 1,
    Assigned = 2,
    InProgress = 3,
    Completed = 4,
    Cancelled = 5
}
