using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverProfileRepository : IRepository<Driver>
{
    Task<Driver?> GetByUserIdWithUserAsync(int userId, CancellationToken cancellationToken);
    Task<Driver?> GetByUserIdForUpdateAsync(int userId, CancellationToken cancellationToken);
    Task<Driver?> GetByPublicIdWithUserAsync(Guid driverPublicId, CancellationToken cancellationToken);
}
