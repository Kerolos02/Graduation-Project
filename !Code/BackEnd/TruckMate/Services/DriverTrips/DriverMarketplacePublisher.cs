using Microsoft.AspNetCore.SignalR;
using TruckMate.Hubs;

namespace TruckMate.Services.DriverTrips;

public class DriverMarketplacePublisher : IDriverMarketplacePublisher
{
    private readonly IHubContext<DriverHub> _hub;
    private readonly IMarketplaceRequestCacheBumper _cacheBumper;
    private readonly ILogger<DriverMarketplacePublisher> _logger;

    public DriverMarketplacePublisher(IHubContext<DriverHub> hub, IMarketplaceRequestCacheBumper cacheBumper,
        ILogger<DriverMarketplacePublisher> logger)
    {
        _hub = hub;
        _cacheBumper = cacheBumper;
        _logger = logger;
    }

    public Task PublishNewRequestAvailableAsync(string zone, NewMarketplaceRequestSignalDto payload,
        CancellationToken cancellationToken)
    {
        _cacheBumper.Bump();
        return _hub.Clients.Group(DriverHub.MarketplaceZoneGroupName(zone))
            .SendAsync("NewRequestAvailable", payload, cancellationToken);
    }

    public Task PublishRequestTakenAsync(string zone, Guid requestId, string requestNumber,
        CancellationToken cancellationToken)
    {
        _cacheBumper.Bump();
        var body = new { requestId, requestNumber };
        return _hub.Clients.Group(DriverHub.MarketplaceZoneGroupName(zone))
            .SendAsync("RequestTaken", body, cancellationToken);
    }

    public Task PublishRequestCancelledAsync(string zone, Guid requestId, string? reason,
        CancellationToken cancellationToken)
    {
        _cacheBumper.Bump();
        return _hub.Clients.Group(DriverHub.MarketplaceZoneGroupName(zone))
            .SendAsync("RequestCancelled", new { requestId, reason }, cancellationToken);
    }

    public Task PublishRequestExpiredAsync(Guid requestId, CancellationToken cancellationToken)
    {
        _cacheBumper.Bump();
        return _hub.Clients.Group(DriverHub.MarketplaceAllDriversGroupName)
            .SendAsync("RequestExpired", new { requestId }, cancellationToken);
    }

    public Task PublishRequestExpiredNoDriverAsync(Guid requestId, CancellationToken cancellationToken)
    {
        return _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("RequestExpiredNoDriver", new { requestId }, cancellationToken);
    }

    public Task PublishDriverAcceptedToTraderAsync(int traderPkId, string driverName, DateTime acceptedAt,
        CancellationToken cancellationToken)
    {
        return _hub.Clients.Group(DriverHub.TraderGroupName(traderPkId))
            .SendAsync("DriverAccepted", new { driverName, acceptedAt }, cancellationToken);
    }

    public Task PublishRequestAcceptedToDispatchersAsync(Guid requestId, int driverDbId,
        CancellationToken cancellationToken)
    {
        return _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("RequestAccepted", new { requestId, driverId = driverDbId }, cancellationToken);
    }

    public Task PublishDriverRejectedRequestAsync(Guid requestId, int driverDbId,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Marketplace request {RequestId} rejected by driver {DriverId}", requestId, driverDbId);
        return _hub.Clients.Group(DriverHub.DispatcherGroupName)
            .SendAsync("DriverRejectedRequest", new { requestId, driverId = driverDbId }, cancellationToken);
    }
}
