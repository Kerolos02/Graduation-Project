using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.TraderSettings.Dtos;

namespace TruckMate.Services.TraderSettings;

public interface ITraderPrivacyService
{
    Task<TraderPrivacySettingsResponseDto> GetAsync(int userId, CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> UpdateAsync(int userId, TraderPrivacySettingsPatchDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> RequestDataExportAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken);
}
