namespace TruckMate.Core.DriverSettings.Dtos;

public class ScheduleAccountDeletionRequestDto
{
    public string Password { get; set; } = string.Empty;
    public string ConfirmationPhrase { get; set; } = string.Empty;
}
