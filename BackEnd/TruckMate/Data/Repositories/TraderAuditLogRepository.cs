using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderAuditLogRepository : ITraderAuditLogRepository
{
    private readonly TruckMateDbContext _context;

    public TraderAuditLogRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(TraderAuditLog log, CancellationToken cancellationToken)
    {
        await _context.TraderAuditLogs.AddAsync(log, cancellationToken).ConfigureAwait(false);
    }
}
