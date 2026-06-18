using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverEarningRepository : Repository<DriverEarning>, IDriverEarningRepository
{
    public DriverEarningRepository(TruckMateDbContext context)
        : base(context)
    {
    }

    public async Task<decimal> GetTotalEarningsAsync(Guid driverId, CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.DriverId == driverId)
            .SumAsync(x => (decimal?)x.AmountEGP, cancellationToken)
            .ConfigureAwait(false) ?? 0m;
    }

    public async Task<decimal> GetEarningsFromAsync(Guid driverId, DateTime fromUtc, CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.DriverId == driverId && x.EarnedAt >= fromUtc)
            .SumAsync(x => (decimal?)x.AmountEGP, cancellationToken)
            .ConfigureAwait(false) ?? 0m;
    }

    public async Task<decimal> GetEarningsBetweenAsync(Guid driverId, DateTime fromUtc, DateTime toUtc,
        CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.DriverId == driverId && x.EarnedAt >= fromUtc && x.EarnedAt < toUtc)
            .SumAsync(x => (decimal?)x.AmountEGP, cancellationToken)
            .ConfigureAwait(false) ?? 0m;
    }

    public Task<int> CountAsync(Guid driverId, DateTime? fromUtc, CancellationToken cancellationToken)
    {
        var query = DbSet.AsNoTracking().Where(x => x.DriverId == driverId);
        if (fromUtc.HasValue)
        {
            query = query.Where(x => x.EarnedAt >= fromUtc.Value);
        }

        return query.CountAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<DriverEarning>> GetPagedAsync(Guid driverId, DateTime? fromUtc, int skip, int take,
        CancellationToken cancellationToken)
    {
        var query = DbSet.AsNoTracking().Where(x => x.DriverId == driverId);
        if (fromUtc.HasValue)
        {
            query = query.Where(x => x.EarnedAt >= fromUtc.Value);
        }

        return await query
            .OrderByDescending(x => x.EarnedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public Task<DriverEarning?> GetByTripIdAsync(Guid driverId, Guid tripId, CancellationToken cancellationToken) =>
        DbSet.AsNoTracking()
            .Include(x => x.Trip)
            .FirstOrDefaultAsync(x => x.DriverId == driverId && x.TripId == tripId, cancellationToken);

    public Task<DriverEarning?> GetByTripIdAnyDriverAsync(Guid tripId, CancellationToken cancellationToken) =>
        DbSet.AsNoTracking()
            .FirstOrDefaultAsync(x => x.TripId == tripId, cancellationToken);

    public Task<bool> ExistsByTripIdAsync(Guid tripId, CancellationToken cancellationToken) =>
        DbSet.AnyAsync(x => x.TripId == tripId, cancellationToken);
}
