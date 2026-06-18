namespace TruckMate.Core.Models;

public class TraderWallet
{
    public Guid Id { get; set; }
    public Guid TraderId { get; set; }
    public Trader Trader { get; set; } = null!;
    public decimal BalanceEGP { get; set; }
    public decimal TotalSpentEGP { get; set; }
    public DateTime LastUpdatedAt { get; set; }
}
