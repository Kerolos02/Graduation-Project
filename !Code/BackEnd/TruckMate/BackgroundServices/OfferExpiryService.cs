using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.DriverHome;

namespace TruckMate.BackgroundServices;

public class OfferExpiryService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<OfferExpiryService> _logger;

    public OfferExpiryService(IServiceScopeFactory scopeFactory, ILogger<OfferExpiryService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await SweepAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Offer expiry sweep failed.");
            }

            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken).ConfigureAwait(false);
        }
    }

    private async Task SweepAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var uow = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var dispatch = scope.ServiceProvider.GetRequiredService<ITripDispatchService>();
        var realtime = scope.ServiceProvider.GetRequiredService<IDriverRealtimePublisher>();

        var now = DateTime.UtcNow;
        var expired = await uow.TripOffers.GetExpiredPendingsAsync(now, cancellationToken).ConfigureAwait(false);
        if (expired.Count == 0)
        {
            return;
        }

        foreach (var offer in expired)
        {
            offer.Status = TripOfferStatus.Expired;
            offer.RespondedAtUtc = now;

            await uow.DriverOfferHistories.AddAsync(new DriverOfferHistory
            {
                Id = Guid.NewGuid(),
                DriverId = offer.DriverId,
                TripOfferId = offer.Id,
                Action = DriverOfferHistoryAction.Expired,
                TimestampUtc = now
            }, cancellationToken).ConfigureAwait(false);

            await uow.DriverAuditLogs.AddAsync(new DriverAuditLog
            {
                Id = Guid.NewGuid(),
                DriverPublicId = offer.Driver.PublicId,
                Action = "OfferExpired",
                PerformedAtUtc = now,
                IpAddress = "system",
                UserAgent = "backend",
                AdditionalData = $"offerId={offer.Id};tripId={offer.TripId}"
            }, cancellationToken).ConfigureAwait(false);
        }

        await uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        foreach (var offer in expired)
        {
            await realtime.PublishTripOfferExpiredAsync(offer.Driver.UserId, offer.Id, offer.TripId, "Timeout",
                cancellationToken).ConfigureAwait(false);
            await dispatch.ReDispatchTripAsync(offer.TripId, offer.DriverId, cancellationToken).ConfigureAwait(false);
        }

        _logger.LogInformation("Expired {Count} pending driver offers.", expired.Count);
    }
}
