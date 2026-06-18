namespace TruckMate.Core.Models;

public class TraderPrivacySetting
{
    public Guid Id { get; set; }

    public Guid TraderPublicId { get; set; }
    public Trader Trader { get; set; } = null!;

    public bool ShareBusinessDataWithPartners { get; set; }

    public bool AllowMarketingCommunications { get; set; }

    public bool AllowAnalyticsTracking { get; set; }

    public bool ShareShipmentDataForResearch { get; set; }

    public bool DataRetentionConsentGiven { get; set; }

    public DateTime? ConsentGivenAtUtc { get; set; }

    public DateTime? GdprDataExportRequestedAtUtc { get; set; }

    /// <summary>Set when compile-and-email completes (hosted worker).</summary>
    public DateTime? GdprDataExportDeliveredAtUtc { get; set; }
}
