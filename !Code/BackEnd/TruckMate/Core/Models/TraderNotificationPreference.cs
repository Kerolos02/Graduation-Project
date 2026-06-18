namespace TruckMate.Core.Models;

public class TraderNotificationPreference
{
    public Guid Id { get; set; }

    public Guid TraderPublicId { get; set; }
    public Trader Trader { get; set; } = null!;

    public bool ShipmentCreatedConfirmation { get; set; } = true;
    public bool ShipmentAssignedToDriver { get; set; } = true;
    public bool ShipmentPickedUp { get; set; } = true;
    public bool ShipmentInTransit { get; set; }

    public bool ShipmentDelivered { get; set; } = true;
    public bool ShipmentDelayed { get; set; } = true;
    public bool ShipmentCancelled { get; set; } = true;

    public bool InvoiceGenerated { get; set; } = true;
    public bool PaymentConfirmed { get; set; } = true;
    public bool PaymentFailed { get; set; } = true;

    public bool PushNotificationsEnabled { get; set; } = true;
    public bool EmailNotificationsEnabled { get; set; } = true;
    public bool SmsNotificationsEnabled { get; set; } = true;
}
