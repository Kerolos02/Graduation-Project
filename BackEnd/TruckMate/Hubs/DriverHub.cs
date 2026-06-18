using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using TruckMate.Core.Enums;
using TruckMate.Services.DriverHome;

namespace TruckMate.Hubs;

/// <summary>Real-time courier channel (/hubs/driver).</summary>
[Authorize]
public class DriverHub : Hub
{
    public const string DispatcherGroupName = "dispatchers";
    public static string TraderGroupName(int traderId) => $"trader-{traderId}";

    private readonly IDriverHomeService _driverHome;
    private readonly ILogger<DriverHub> _logger;

    public DriverHub(IDriverHomeService driverHome, ILogger<DriverHub> logger)
    {
        _driverHome = driverHome;
        _logger = logger;
    }

    public static string DriverUserGroupName(int userId) => $"driver-user-{userId}";

    public static string OperationalZoneGroupName(string zone) =>
        $"zone-{string.Concat(zone.Where(char.IsLetterOrDigit))}";

    /// <summary>All drivers subscribed on the Trips marketplace tab (expiry fan-out).</summary>
    public const string MarketplaceAllDriversGroupName = "marketplace-all-drivers";

    public static string MarketplaceZoneGroupName(string zone) =>
        $"marketplace-zone-{string.Concat((zone ?? string.Empty).Where(char.IsLetterOrDigit))}";

    public override async Task OnConnectedAsync()
    {
        if (TryGetUserId(out var userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, DriverUserGroupName(userId)).ConfigureAwait(false);
        }

        await base.OnConnectedAsync().ConfigureAwait(false);
    }

    /// <summary>Driver emits availability changes (mirrors PATCH /api/driver/status).</summary>
    [Authorize(Roles = nameof(UserRole.Driver))]
    public async Task UpdateStatus(string status)
    {
        if (!TryGetUserId(out var userId))
        {
            throw new HubException("Authentication required.");
        }

        var result = await _driverHome.TryApplySignalRStatusAsync(userId, status, Context.ConnectionAborted)
            .ConfigureAwait(false);

        if (result == null)
        {
            await Clients.Caller.SendAsync("StatusAcknowledged",
                    new { success = false, message = "Unable to update status." },
                    Context.ConnectionAborted)
                .ConfigureAwait(false);
            return;
        }

        await Clients.Caller.SendAsync("StatusAcknowledged",
                new { success = true, status = result.Status, message = result.Message },
                Context.ConnectionAborted)
            .ConfigureAwait(false);

        _logger.LogInformation("SignalR status ack for user {UserId}: {Status}", userId, result.Status);
    }

    /// <summary>Optional: join zone channel for granular TripOffer fan-out.</summary>
    [Authorize(Roles = nameof(UserRole.Driver))]
    public Task JoinOperationalZone(string zone) =>
        Groups.AddToGroupAsync(Context.ConnectionId, OperationalZoneGroupName(zone),
            Context.ConnectionAborted);

    /// <summary>Dispatcher dashboards subscribe for DriverAvailabilityChanged and CourierTripStarted events.</summary>
    [Authorize(Roles = nameof(UserRole.Admin))]
    public Task JoinDispatcherFeed() =>
        Groups.AddToGroupAsync(Context.ConnectionId, DispatcherGroupName,
            Context.ConnectionAborted);

    [Authorize(Roles = nameof(UserRole.Driver))]
    public Task DriverOnline() => UpdateStatus("Online");

    [Authorize(Roles = nameof(UserRole.Driver))]
    public Task DriverOffline() => UpdateStatus("Offline");

    /// <summary>Subscribe to marketplace SignalR events for a zone while on Available Requests.</summary>
    [Authorize(Roles = nameof(UserRole.Driver))]
    public async Task JoinAvailableRequestsRoom(string zone)
    {
        var z = MarketplaceZoneGroupName(zone);
        await Groups.AddToGroupAsync(Context.ConnectionId, z, Context.ConnectionAborted).ConfigureAwait(false);
        await Groups.AddToGroupAsync(Context.ConnectionId, MarketplaceAllDriversGroupName, Context.ConnectionAborted)
            .ConfigureAwait(false);
        _logger.LogDebug("Connection {ConnectionId} joined marketplace groups for {Zone}", Context.ConnectionId, z);
    }

    [Authorize(Roles = nameof(UserRole.Driver))]
    public async Task LeaveAvailableRequestsRoom(string zone)
    {
        var z = MarketplaceZoneGroupName(zone);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, z, Context.ConnectionAborted).ConfigureAwait(false);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, MarketplaceAllDriversGroupName, Context.ConnectionAborted)
            .ConfigureAwait(false);
    }

    private bool TryGetUserId(out int userId)
    {
        userId = 0;
        var raw = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? Context.User?.FindFirstValue(JwtRegisteredClaimNames.Sub);
        return int.TryParse(raw, out userId);
    }
}
