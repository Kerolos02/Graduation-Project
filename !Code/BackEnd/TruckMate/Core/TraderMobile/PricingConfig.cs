namespace TruckMate.Core.TraderMobile;

public class PricingConfig
{
    public decimal BaseFare { get; set; } = 50m;
    public decimal PerKmRate { get; set; } = 1.5m;
    public decimal PerKgRate { get; set; } = 0.05m;
    public decimal VanMultiplier { get; set; } = 1.0m;
    public decimal PickupTruckMultiplier { get; set; } = 1.2m;
    public decimal BoxTruckMultiplier { get; set; } = 1.5m;
    public decimal TruckMultiplier { get; set; } = 2.0m;
}
