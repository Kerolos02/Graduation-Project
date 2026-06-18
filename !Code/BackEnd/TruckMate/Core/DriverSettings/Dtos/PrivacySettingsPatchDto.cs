namespace TruckMate.Core.DriverSettings.Dtos;

public class PrivacySettingsPatchDto
{
    public bool? ShareLocationWithDispatcher { get; set; }
    public bool? ShareTripHistoryWithThirdParties { get; set; }
    public bool? AllowAnalyticsTracking { get; set; }
    public bool? DataRetentionConsentGiven { get; set; }
}
