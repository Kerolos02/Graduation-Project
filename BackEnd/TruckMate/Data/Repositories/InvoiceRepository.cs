using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class InvoiceRepository : Repository<Invoice>, IInvoiceRepository
{
    public InvoiceRepository(TruckMateDbContext context) : base(context)
    {
    }

    public Task<Invoice?> GetByIdForTraderAsync(Guid invoiceId, Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet.Include(x => x.Shipment)
            .Include(x => x.Driver).ThenInclude(d => d.User)
            .FirstOrDefaultAsync(x => x.Id == invoiceId && x.TraderId == traderPublicId, cancellationToken);

    public Task<Invoice?> GetByShipmentIdAsync(Guid shipmentId, CancellationToken cancellationToken) =>
        DbSet.FirstOrDefaultAsync(x => x.ShipmentId == shipmentId, cancellationToken);
}
