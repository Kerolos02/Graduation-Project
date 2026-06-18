namespace TruckMate.Core.DriverSettings.Dtos;

public class UpdateContactResponseDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
    public bool EmailVerificationRequired { get; set; }
    public bool PhoneVerificationRequired { get; set; }
}
