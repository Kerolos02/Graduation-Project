using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class LegalDocument
{
    public Guid Id { get; set; }

    public LegalDocumentType Type { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public DateTime EffectiveDateUtc { get; set; }
    public bool IsActive { get; set; }
}
