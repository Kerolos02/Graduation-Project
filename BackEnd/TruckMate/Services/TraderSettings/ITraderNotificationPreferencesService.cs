using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.TraderSettings.Dtos;

namespace TruckMate.Services.TraderSettings;

public interface ITraderNotificationPreferencesService
{
    Task<TraderNotificationPreferencesResponseDto> GetAsync(int userId, CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> UpdateAsync(int userId, TraderNotificationPreferencesPatchDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);
}
