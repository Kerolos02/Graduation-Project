using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.TraderSettings.Dtos;

namespace TruckMate.Services.TraderSettings;

public interface ITraderSettingsService
{
    Task<TraderSettingsProfileResponseDto> GetProfileAsync(int userId, CancellationToken cancellationToken);

    Task<ChangePasswordResponseDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task<UpdateContactResponseDto> UpdateContactAsync(int userId, UpdateContactRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task<ScheduleAccountDeletionResponseDto> ScheduleAccountDeletionAsync(int userId,
        ScheduleAccountDeletionRequestDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> CancelAccountDeletionAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken);
}
