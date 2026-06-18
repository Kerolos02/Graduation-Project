using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using TruckMate.API.Services;
using TruckMate.Data.Context;

namespace TruckMate.BackgroundServices;

/// <summary>
/// Polls pending GDPR export rows and sends the ready email (ZIP build is a placeholder).
/// </summary>
public class TraderGdprDataExportHostedService : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<TraderGdprDataExportHostedService> _logger;

    public TraderGdprDataExportHostedService(
        IServiceScopeFactory scopeFactory,
        ILogger<TraderGdprDataExportHostedService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken)
                   .ConfigureAwait(false))
        {
            try
            {
                await ProcessPendingExportsAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Trader GDPR export worker failed");
            }
        }
    }

    private async Task ProcessPendingExportsAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TruckMateDbContext>();
        var email = scope.ServiceProvider.GetRequiredService<IEmailService>();

        var pending = await db.TraderPrivacySettings
            .Include(p => p.Trader)
            .ThenInclude(t => t.User)
            .Where(p => p.GdprDataExportRequestedAtUtc != null && p.GdprDataExportDeliveredAtUtc == null)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var row in pending)
        {
            try
            {
                await email.SendDataExportReadyEmailAsync(row.Trader.User.Email, cancellationToken)
                    .ConfigureAwait(false);
                row.GdprDataExportDeliveredAtUtc = DateTime.UtcNow;
                await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
                _logger.LogInformation("GDPR export email sent for trader {Pid}", row.TraderPublicId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed GDPR export email for trader {Pid}", row.TraderPublicId);
            }
        }
    }
}
