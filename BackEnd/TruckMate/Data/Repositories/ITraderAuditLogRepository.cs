using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITraderAuditLogRepository
{
    Task AddAsync(TraderAuditLog log, CancellationToken cancellationToken);
}
