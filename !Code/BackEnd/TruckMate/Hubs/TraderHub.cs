using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using TruckMate.Core.Enums;

namespace TruckMate.Hubs;

[Authorize(Roles = nameof(UserRole.Trader))]
public class TraderHub : Hub
{
    public static string TraderGroupName(Guid traderPublicId) => $"trader-{traderPublicId:D}";

    public Task JoinTraderFeed(Guid traderPublicId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, TraderGroupName(traderPublicId), Context.ConnectionAborted);
}
