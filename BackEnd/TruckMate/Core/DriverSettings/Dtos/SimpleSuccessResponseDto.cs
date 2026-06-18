namespace TruckMate.Core.DriverSettings.Dtos;

public class SimpleSuccessResponseDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
}
