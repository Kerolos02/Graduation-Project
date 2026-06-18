using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Auth;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;

namespace TruckMate.Middleware;

/// <summary>
/// Ensures JWT token_version matches the database and blocks accounts past their grace window.
/// </summary>
public class TokenVersionValidationMiddleware
{
    private readonly RequestDelegate _next;

    public TokenVersionValidationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, TruckMateDbContext db)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<Microsoft.AspNetCore.Authorization.IAllowAnonymous>() != null)
        {
            await _next(context).ConfigureAwait(false);
            return;
        }

        if (context.User.Identity?.IsAuthenticated != true)
        {
            await _next(context).ConfigureAwait(false);
            return;
        }

        var userIdRaw = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdRaw, out var userId))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        var tokenVersionClaim = context.User.FindFirst(JwtCustomClaims.TokenVersion)?.Value;
        if (tokenVersionClaim == null || !int.TryParse(tokenVersionClaim, out var claimVersion))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        var roleClaim = context.User.FindFirst(ClaimTypes.Role)?.Value;
        var user =
            await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId, context.RequestAborted)
                .ConfigureAwait(false);
        if (user == null)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        if (string.Equals(roleClaim, UserRole.Trader.ToString(), StringComparison.Ordinal))
        {
            var trader = await db.Traders.AsNoTracking()
                .FirstOrDefaultAsync(t => t.UserId == userId, context.RequestAborted).ConfigureAwait(false);
            if (trader == null || claimVersion != trader.TokenVersion)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                return;
            }
        }
        else
        {
            if (claimVersion != user.TokenVersion)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                return;
            }
        }

        if (user.IsDeleted && user.ScheduledHardDeleteAtUtc.HasValue &&
            user.ScheduledHardDeleteAtUtc.Value <= DateTime.UtcNow)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        await _next(context).ConfigureAwait(false);
    }
}
