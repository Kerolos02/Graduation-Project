using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverEarningRepository : IRepository<DriverEarning>
{
    Task<decimal> GetTotalEarningsAsync(Guid driverId, CancellationToken cancellationToken);
    Task<decimal> GetEarningsFromAsync(Guid driverId, DateTime fromUtc, CancellationToken cancellationToken);
    Task<decimal> GetEarningsBetweenAsync(Guid driverId, DateTime fromUtc, DateTime toUtc, CancellationToken cancellationToken);
    Task<int> CountAsync(Guid driverId, DateTime? fromUtc, CancellationToken cancellationToken);
    Task<IReadOnlyList<DriverEarning>> GetPagedAsync(Guid driverId, DateTime? fromUtc, int skip, int take,
        CancellationToken cancellationToken);
    Task<DriverEarning?> GetByTripIdAsync(Guid driverId, Guid tripId, CancellationToken cancellationToken);
    Task<DriverEarning?> GetByTripIdAnyDriverAsync(Guid tripId, CancellationToken cancellationToken);
    Task<bool> ExistsByTripIdAsync(Guid tripId, CancellationToken cancellationToken);
}
