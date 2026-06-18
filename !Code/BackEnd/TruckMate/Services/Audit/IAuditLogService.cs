namespace TruckMate.Services.Audit;

public interface IAuditLogService
{
    Task LogDriverActionAsync(Guid driverPublicId, string action, string? additionalDataJson,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task LogTraderActionAsync(Guid traderPublicId, string action, string? additionalDataJson,
        string ipAddress, string userAgent, CancellationToken cancellationToken);
}
