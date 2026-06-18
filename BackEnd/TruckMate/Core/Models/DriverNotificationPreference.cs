namespace TruckMate.Core.Models;

public class DriverNotificationPreference
{
    public Guid Id { get; set; }

    public Guid DriverPublicId { get; set; }
    public Driver Driver { get; set; } = null!;

    public bool TripAssignedEnabled { get; set; } = true;
    public bool TripOfferEnabled { get; set; } = true;
    public bool EarningsUpdateEnabled { get; set; } = true;
    public bool SystemAlertsEnabled { get; set; } = true;
    public bool PushNotificationsEnabled { get; set; } = true;
    public bool EmailNotificationsEnabled { get; set; } = true;
    public bool SmsNotificationsEnabled { get; set; } = true;
}
