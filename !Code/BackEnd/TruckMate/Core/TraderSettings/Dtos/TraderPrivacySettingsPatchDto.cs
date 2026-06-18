namespace TruckMate.Core.TraderSettings.Dtos;

public class TraderPrivacySettingsPatchDto
{
    public bool? ShareBusinessDataWithPartners { get; set; }
    public bool? AllowMarketingCommunications { get; set; }
    public bool? AllowAnalyticsTracking { get; set; }
    public bool? ShareShipmentDataForResearch { get; set; }
    public bool? DataRetentionConsentGiven { get; set; }
}
