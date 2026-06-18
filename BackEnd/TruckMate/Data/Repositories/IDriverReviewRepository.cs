using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverReviewRepository : IRepository<DriverReview>
{
    Task<IReadOnlyList<DriverReview>> GetRecentByDriverAsync(Guid driverPublicId, int take, CancellationToken cancellationToken);
    Task<bool> ExistsForTripAndTraderAsync(Guid tripId, Guid traderPublicId, CancellationToken cancellationToken);
    Task<(decimal average, int count)> GetDriverRatingStatsAsync(Guid driverPublicId, CancellationToken cancellationToken);
}
