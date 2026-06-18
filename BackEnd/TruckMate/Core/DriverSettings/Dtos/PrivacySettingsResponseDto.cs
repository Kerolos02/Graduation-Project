namespace TruckMate.Core.DriverSettings.Dtos;

public class PrivacySettingsResponseDto
{
    public bool ShareLocationWithDispatcher { get; set; } = true;
    public bool ShareTripHistoryWithThirdParties { get; set; }
    public bool AllowAnalyticsTracking { get; set; }
    public bool DataRetentionConsentGiven { get; set; }
    public DateTime? ConsentGivenAt { get; set; }
}
