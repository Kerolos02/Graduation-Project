namespace TruckMate.Core.Enums;

/// <summary>Lifecycle for marketplace trip requests (driver browses and accepts).</summary>
public enum TripRequestStatus
{
    Open = 0,
    Accepted = 1,
    Expired = 2,
    Cancelled = 3
}
