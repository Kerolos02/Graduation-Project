using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class Invoice
{
    public Guid Id { get; set; }
    public string InvoiceNumber { get; set; } = string.Empty;
    public Guid ShipmentId { get; set; }
    public DeliveryTrip Shipment { get; set; } = null!;
    public Guid TraderId { get; set; }
    public Trader Trader { get; set; } = null!;
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;
    public DateTime InvoiceDate { get; set; }
    public decimal BasePriceEGP { get; set; }
    public decimal ServiceFeeEGP { get; set; }
    public decimal TaxEGP { get; set; }
    public decimal TotalAmountEGP { get; set; }
    public InvoiceStatus Status { get; set; } = InvoiceStatus.Unpaid;
    public DateTime? PaidAt { get; set; }
    public string? PaymentMethod { get; set; }
}
