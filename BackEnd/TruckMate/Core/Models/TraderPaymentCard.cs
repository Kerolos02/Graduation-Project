using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class TraderPaymentCard
{
    public Guid Id { get; set; }
    public Guid TraderId { get; set; }
    public Trader Trader { get; set; } = null!;
    public string CardHolderName { get; set; } = string.Empty;
    public string Last4Digits { get; set; } = string.Empty;
    public CardBrand CardBrand { get; set; }
    public int ExpiryMonth { get; set; }
    public int ExpiryYear { get; set; }
    public bool IsDefault { get; set; }
    public string TokenizedCardId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
