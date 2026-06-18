using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderPrivacySettingRepository
{
    Task<TraderPrivacySetting?> GetByTraderPublicIdForReadAsync(Guid traderPublicId,
        CancellationToken cancellationToken);

    Task<TraderPrivacySetting?> GetByTraderPublicIdTrackedAsync(Guid traderPublicId,
        CancellationToken cancellationToken);

    void Add(TraderPrivacySetting entity);
}
