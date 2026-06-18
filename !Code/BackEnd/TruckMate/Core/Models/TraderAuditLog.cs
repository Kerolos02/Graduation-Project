namespace TruckMate.Core.Models;

public class TraderAuditLog
{
    public Guid Id { get; set; }

    public Guid TraderPublicId { get; set; }
    public Trader Trader { get; set; } = null!;

    public string Action { get; set; } = string.Empty;

    /// <remarks>UTC instant.</remarks>
    public DateTime PerformedAtUtc { get; set; }

    public string IpAddress { get; set; } = string.Empty;
    public string UserAgent { get; set; } = string.Empty;
    public string? AdditionalData { get; set; }
}
