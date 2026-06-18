using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderNotificationPreferenceRepository
{
    Task<TraderNotificationPreference?> GetByTraderPublicIdForReadAsync(Guid traderPublicId,
        CancellationToken cancellationToken);

    Task<TraderNotificationPreference?> GetByTraderPublicIdTrackedAsync(Guid traderPublicId,
        CancellationToken cancellationToken);

    void Add(TraderNotificationPreference entity);
}
