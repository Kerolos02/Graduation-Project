using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;

namespace TruckMate.Services.Auth;

public class AuthSessionService : IAuthSessionService
{
    private readonly TruckMateDbContext _db;
    private readonly ILogger<AuthSessionService> _logger;

    public AuthSessionService(TruckMateDbContext db, ILogger<AuthSessionService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task LogoutAsync(int userId, string role, CancellationToken cancellationToken)
    {
        var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken).ConfigureAwait(false)
                   ?? throw new InvalidOperationException("User not found.");

        if (string.Equals(role, UserRole.Trader.ToString(), StringComparison.Ordinal))
        {
            var trader = await _db.Traders.FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken)
                .ConfigureAwait(false);
            if (trader != null)
            {
                trader.TokenVersion += 1;
            }
        }
        else
        {
            user.TokenVersion += 1;
        }

        await _db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogInformation("Logout invalidated token for user {UserId} role {Role}", userId, role);
    }
}
