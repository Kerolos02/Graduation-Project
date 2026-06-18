namespace TruckMate.Core.Shipments
{
    public class CostTimeEstimateDto
    {
        public double DistanceMiles { get; set; }
        public string EstimatedTime { get; set; } = string.Empty;
        public decimal MinCost { get; set; }
        public decimal MaxCost { get; set; }
    }
}
