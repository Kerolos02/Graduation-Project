using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.Audit;

public class AuditLogService : IAuditLogService
{
    private readonly IUnitOfWork _uow;

    public AuditLogService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public Task LogDriverActionAsync(Guid driverPublicId, string action, string? additionalDataJson,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var log = new DriverAuditLog
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driverPublicId,
            Action = action,
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            AdditionalData = additionalDataJson
        };
        return _uow.DriverAuditLogs.AddAsync(log, cancellationToken);
    }

    public Task LogTraderActionAsync(Guid traderPublicId, string action, string? additionalDataJson,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var log = new TraderAuditLog
        {
            Id = Guid.NewGuid(),
            TraderPublicId = traderPublicId,
            Action = action,
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            AdditionalData = additionalDataJson
        };
        return _uow.TraderAuditLogs.AddAsync(log, cancellationToken);
    }
}
