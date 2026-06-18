namespace TruckMate.Core.TraderSettings.Dtos;

public class TraderNotificationPreferencesResponseDto
{
    public bool ShipmentCreatedConfirmation { get; set; }
    public bool ShipmentAssignedToDriver { get; set; }
    public bool ShipmentPickedUp { get; set; }
    public bool ShipmentInTransit { get; set; }

    public bool ShipmentDelivered { get; set; }
    public bool ShipmentDelayed { get; set; }
    public bool ShipmentCancelled { get; set; }

    public bool InvoiceGenerated { get; set; }
    public bool PaymentConfirmed { get; set; }
    public bool PaymentFailed { get; set; }

    public bool PushNotificationsEnabled { get; set; }
    public bool EmailNotificationsEnabled { get; set; }
    public bool SmsNotificationsEnabled { get; set; }
}
