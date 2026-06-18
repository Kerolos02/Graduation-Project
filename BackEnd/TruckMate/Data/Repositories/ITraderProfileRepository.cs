using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderProfileRepository : IRepository<Trader>
{
    Task<Trader?> GetByUserIdWithUserAsync(int userId, CancellationToken cancellationToken);

    Task<Trader?> GetByUserIdTrackedWithUserAsync(int userId, CancellationToken cancellationToken);

    Task<Trader?> GetByPublicIdWithUserAsync(Guid traderPublicId, CancellationToken cancellationToken);
}
