using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class ShipmentStatusHistoryRepository : Repository<ShipmentStatusHistory>, IShipmentStatusHistoryRepository
{
    public ShipmentStatusHistoryRepository(TruckMateDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<ShipmentStatusHistory>> GetByShipmentIdAsync(Guid shipmentId,
        CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(x => x.ShipmentId == shipmentId)
            .OrderBy(x => x.OccurredAt)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }
}
