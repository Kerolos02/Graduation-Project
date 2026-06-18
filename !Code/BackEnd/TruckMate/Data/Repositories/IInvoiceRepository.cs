using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IInvoiceRepository : IRepository<Invoice>
{
    Task<Invoice?> GetByIdForTraderAsync(Guid invoiceId, Guid traderPublicId, CancellationToken cancellationToken);
    Task<Invoice?> GetByShipmentIdAsync(Guid shipmentId, CancellationToken cancellationToken);
}
