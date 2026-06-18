using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.BackgroundServices;

/// <summary>Every minute, increments <see cref="DriverDailySummary.OnlineTimeMinutes"/> for online drivers (UTC day bucket).</summary>
public class DriverOnlineTimeBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DriverOnlineTimeBackgroundService> _logger;

    public DriverOnlineTimeBackgroundService(IServiceScopeFactory scopeFactory,
        ILogger<DriverOnlineTimeBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken).ConfigureAwait(false);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await TickAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogError(ex, "Failed to update driver online-minute summaries.");
            }

            try
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    private async Task TickAsync(CancellationToken ct)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<TruckMateDbContext>();
        var utcToday = DateOnly.FromDateTime(DateTime.UtcNow);

        var onlineDriverIds = await db.Drivers.AsNoTracking()
            .Where(d => d.AvailabilityStatus == DriverAvailabilityStatus.Online)
            .Select(d => d.Id)
            .ToListAsync(ct)
            .ConfigureAwait(false);

        foreach (var driverId in onlineDriverIds)
        {
            var summary =
                await db.DriverDailySummaries.FirstOrDefaultAsync(
                    s => s.DriverId == driverId && s.SummaryDate == utcToday,
                    ct).ConfigureAwait(false);

            if (summary == null)
            {
                summary = new DriverDailySummary
                {
                    Id = Guid.NewGuid(),
                    DriverId = driverId,
                    SummaryDate = utcToday
                };
                db.DriverDailySummaries.Add(summary);
            }

            summary.OnlineTimeMinutes += 1;
        }

        await db.SaveChangesAsync(ct).ConfigureAwait(false);
        _logger.LogTrace("Online minute tick applied for {Count} drivers.", onlineDriverIds.Count);
    }
}
