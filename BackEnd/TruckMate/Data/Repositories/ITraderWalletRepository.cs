using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderWalletRepository : IRepository<TraderWallet>
{
    Task<TraderWallet?> GetByTraderIdAsync(Guid traderPublicId, CancellationToken cancellationToken);
}
