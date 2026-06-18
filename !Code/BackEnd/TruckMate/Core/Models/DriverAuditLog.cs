namespace TruckMate.Core.Models;

public class DriverAuditLog
{
    public Guid Id { get; set; }

    public Guid DriverPublicId { get; set; }
    public Driver Driver { get; set; } = null!;

    public string Action { get; set; } = string.Empty;
    public DateTime PerformedAtUtc { get; set; }
    public string IpAddress { get; set; } = string.Empty;
    public string UserAgent { get; set; } = string.Empty;
    public string? AdditionalData { get; set; }
}
