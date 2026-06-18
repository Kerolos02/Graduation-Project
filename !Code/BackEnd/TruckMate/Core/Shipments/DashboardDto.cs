namespace TruckMate.Core.Shipments
{
    public class DashboardDto
    {
        public ShipmentResponseDto? CurrentShipment { get; set; }
        public double AvgTimeHours { get; set; }
        public decimal AvgCost { get; set; }
        public int CompletedCount { get; set; }
        public List<ShipmentResponseDto> RecentActivity { get; set; } = new();
    }
}
