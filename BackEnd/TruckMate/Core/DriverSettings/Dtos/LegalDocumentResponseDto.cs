namespace TruckMate.Core.DriverSettings.Dtos;

public class LegalDocumentResponseDto
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public DateTime EffectiveDate { get; set; }
}
