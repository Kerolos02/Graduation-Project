namespace TruckMate.Services.Auth;

public interface IAuthSessionService
{
    Task LogoutAsync(int userId, string role, CancellationToken cancellationToken);
}
