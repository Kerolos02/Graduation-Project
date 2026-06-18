namespace TruckMate.Core.DriverSettings.Dtos;

public class NotificationPreferencesPatchDto
{
    public bool? TripAssignedEnabled { get; set; }
    public bool? TripOfferEnabled { get; set; }
    public bool? EarningsUpdateEnabled { get; set; }
    public bool? SystemAlertsEnabled { get; set; }
    public bool? PushNotificationsEnabled { get; set; }
    public bool? EmailNotificationsEnabled { get; set; }
    public bool? SmsNotificationsEnabled { get; set; }
}
