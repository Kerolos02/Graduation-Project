namespace TruckMate.Core.DriverHome.Dtos;

public class DriverHomeResponseDto
{
    public string DriverName { get; set; } = string.Empty;
    public decimal Rating { get; set; }
    public string Status { get; set; } = string.Empty;
    public string CurrentZone { get; set; } = string.Empty;
    public ActiveTripCardDto? ActiveTrip { get; set; }
    public TodaySummaryDto TodaySummary { get; set; } = null!;
    public List<RecentTripListItemDto> RecentTrips { get; set; } = new();
}

public class ActiveTripCardDto
{
    public Guid TripId { get; set; }
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ScheduleStatus { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public ShipmentDetailsDto Shipment { get; set; } = null!;
}

public class ShipmentDetailsDto
{
    public string ClientName { get; set; } = string.Empty;
    public string CargoType { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public bool IsFragile { get; set; }
}

public class TodaySummaryDto
{
    public int TripsCompleted { get; set; }
    public decimal EarningsEGP { get; set; }
    public string OnlineTimeFormatted { get; set; } = string.Empty;
}

public class RecentTripListItemDto
{
    public string ShipmentNumber { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Date { get; set; } = string.Empty;
    public string Time { get; set; } = string.Empty;
}
