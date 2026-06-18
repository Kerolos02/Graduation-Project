using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverReviewRepository : Repository<DriverReview>, IDriverReviewRepository
{
    public DriverReviewRepository(TruckMateDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<DriverReview>> GetRecentByDriverAsync(Guid driverPublicId, int take,
        CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.DriverPublicId == driverPublicId)
            .OrderByDescending(x => x.ReviewedAt)
            .Take(take)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public Task<bool> ExistsForTripAndTraderAsync(Guid tripId, Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.AnyAsync(x => x.TripId == tripId && x.TraderPublicId == traderPublicId, cancellationToken);

    public async Task<(decimal average, int count)> GetDriverRatingStatsAsync(Guid driverPublicId,
        CancellationToken cancellationToken)
    {
        var query = DbSet.AsNoTracking().Where(x => x.DriverPublicId == driverPublicId);
        var count = await query.CountAsync(cancellationToken).ConfigureAwait(false);
        if (count == 0)
        {
            return (0m, 0);
        }

        var average = await query.AverageAsync(x => (decimal)x.Rating, cancellationToken).ConfigureAwait(false);
        return (decimal.Round(average, 2), count);
    }
}
