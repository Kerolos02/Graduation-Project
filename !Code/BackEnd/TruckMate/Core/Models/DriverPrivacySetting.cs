namespace TruckMate.Core.Models;

public class DriverPrivacySetting
{
    public Guid Id { get; set; }

    public Guid DriverPublicId { get; set; }
    public Driver Driver { get; set; } = null!;

    public bool ShareLocationWithDispatcher { get; set; } = true;
    public bool ShareTripHistoryWithThirdParties { get; set; }
    public bool AllowAnalyticsTracking { get; set; }
    public bool DataRetentionConsentGiven { get; set; }
    public DateTime? ConsentGivenAtUtc { get; set; }
}
