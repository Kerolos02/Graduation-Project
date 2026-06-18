using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderProfileRepository : Repository<Trader>, ITraderProfileRepository
{
    public TraderProfileRepository(TruckMateDbContext context)
        : base(context)
    {
    }

    public Task<Trader?> GetByUserIdWithUserAsync(int userId, CancellationToken cancellationToken) =>
        DbSet.Include(t => t.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.UserId == userId, cancellationToken);

    public Task<Trader?> GetByUserIdTrackedWithUserAsync(int userId, CancellationToken cancellationToken) =>
        DbSet.Include(t => t.User)
            .FirstOrDefaultAsync(t => t.UserId == userId, cancellationToken);

    public Task<Trader?> GetByPublicIdWithUserAsync(Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.Include(t => t.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.PublicId == traderPublicId, cancellationToken);
}
