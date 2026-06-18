using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderPaymentCardRepository : IRepository<TraderPaymentCard>
{
    Task<IReadOnlyList<TraderPaymentCard>> GetByTraderIdAsync(Guid traderPublicId, CancellationToken cancellationToken);
    Task<TraderPaymentCard?> GetByIdForTraderAsync(Guid cardId, Guid traderPublicId, CancellationToken cancellationToken);
    Task<bool> AnyByTraderAsync(Guid traderPublicId, CancellationToken cancellationToken);
}
