using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Services.Auth;

namespace TruckMate.Controllers;

[ApiController]
[Route("api/auth")]
[Authorize]
public class AuthController : ControllerBase
{
    private readonly IAuthSessionService _authSessionService;

    public AuthController(IAuthSessionService authSessionService)
    {
        _authSessionService = authSessionService;
    }

    /// <summary>Logs out current user and invalidates active JWT token.</summary>
    [HttpPost("logout")]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Unauthorized)]
    public async Task<IActionResult> Logout(CancellationToken cancellationToken)
    {
        var userIdRaw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = User.FindFirst(ClaimTypes.Role)?.Value;
        if (!int.TryParse(userIdRaw, out var userId) || string.IsNullOrWhiteSpace(role))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        await _authSessionService.LogoutAsync(userId, role, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<object>.Ok(new { success = true }, "Logged out successfully."));
    }
}
