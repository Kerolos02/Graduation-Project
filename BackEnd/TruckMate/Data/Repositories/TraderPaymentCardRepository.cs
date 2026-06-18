using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderPaymentCardRepository : Repository<TraderPaymentCard>, ITraderPaymentCardRepository
{
    public TraderPaymentCardRepository(TruckMateDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<TraderPaymentCard>> GetByTraderIdAsync(Guid traderPublicId,
        CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.TraderId == traderPublicId)
            .OrderByDescending(x => x.IsDefault)
            .ThenByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public Task<TraderPaymentCard?> GetByIdForTraderAsync(Guid cardId, Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.FirstOrDefaultAsync(x => x.Id == cardId && x.TraderId == traderPublicId, cancellationToken);

    public Task<bool> AnyByTraderAsync(Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.AnyAsync(x => x.TraderId == traderPublicId, cancellationToken);
}
