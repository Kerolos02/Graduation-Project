using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverAuditLogRepository : IDriverAuditLogRepository
{
    private readonly TruckMateDbContext _context;

    public DriverAuditLogRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(DriverAuditLog log, CancellationToken cancellationToken)
    {
        await _context.DriverAuditLogs.AddAsync(log, cancellationToken).ConfigureAwait(false);
    }
}
