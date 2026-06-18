namespace TruckMate.Core.DriverSettings.Dtos;

public class ScheduleAccountDeletionResponseDto
{
    public bool Success { get; set; } = true;
    public string Message { get; set; } = string.Empty;
    public DateTime ScheduledDeletionDate { get; set; }
}
