using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderWalletRepository : Repository<TraderWallet>, ITraderWalletRepository
{
    public TraderWalletRepository(TruckMateDbContext context) : base(context)
    {
    }

    public Task<TraderWallet?> GetByTraderIdAsync(Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.FirstOrDefaultAsync(x => x.TraderId == traderPublicId, cancellationToken);
}
