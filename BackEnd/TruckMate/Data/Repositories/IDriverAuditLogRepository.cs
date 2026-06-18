using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverAuditLogRepository
{
    Task AddAsync(DriverAuditLog log, CancellationToken cancellationToken);
}
