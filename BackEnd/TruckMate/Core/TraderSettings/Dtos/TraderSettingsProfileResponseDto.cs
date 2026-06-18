namespace TruckMate.Core.TraderSettings.Dtos;

public class TraderSettingsProfileResponseDto
{
    public string FullName { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string Role { get; set; } = "Trader";

    /// <summary>Optional company trade name for business traders.</summary>
    public string? BusinessName { get; set; }

    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
}
