using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.DriverTrips;

namespace TruckMate.BackgroundServices;

/// <summary>Marks open marketplace requests past <see cref="Core.Models.TripRequest.ExpiresAt"/> as expired.</summary>
public class RequestExpiryBackgroundService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<RequestExpiryBackgroundService> _logger;

    public RequestExpiryBackgroundService(IServiceProvider services, ILogger<RequestExpiryBackgroundService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(TimeSpan.FromSeconds(60), stoppingToken).ConfigureAwait(false);
                await ExpireOnceAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Request expiry sweep failed");
            }
        }
    }

    private async Task ExpireOnceAsync(CancellationToken cancellationToken)
    {
        await using var scope = _services.CreateAsyncScope();
        var uow = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var publisher = scope.ServiceProvider.GetRequiredService<IDriverMarketplacePublisher>();
        var db = scope.ServiceProvider.GetRequiredService<TruckMateDbContext>();

        var now = DateTime.UtcNow;
        var ids = await db.TripRequests.AsNoTracking()
            .Where(t => t.Status == TripRequestStatus.Open && t.ExpiresAt != null && t.ExpiresAt <= now)
            .Select(t => t.Id)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var id in ids)
        {
            var n = await uow.TripRequests.TryMarkExpiredAsync(id, cancellationToken).ConfigureAwait(false);
            if (n == 0)
            {
                continue;
            }

            await uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            await publisher.PublishRequestExpiredAsync(id, cancellationToken).ConfigureAwait(false);
            await publisher.PublishRequestExpiredNoDriverAsync(id, cancellationToken).ConfigureAwait(false);
            _logger.LogInformation("Trip request {RequestId} expired (marketplace)", id);
        }
    }
}
