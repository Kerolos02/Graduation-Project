using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IShipmentStatusHistoryRepository : IRepository<ShipmentStatusHistory>
{
    Task<IReadOnlyList<ShipmentStatusHistory>> GetByShipmentIdAsync(Guid shipmentId, CancellationToken cancellationToken);
}
