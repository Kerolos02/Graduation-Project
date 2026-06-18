using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Services.DriverSettings;

namespace TruckMate.Controllers;

/// <summary>Driver advanced settings endpoints.</summary>
[ApiController]
[Route("api/driver/settings")]
[Authorize(Roles = nameof(UserRole.Driver))]
public class DriverSettingsController : ControllerBase
{
    private readonly IDriverSettingsService _settings;

    public DriverSettingsController(IDriverSettingsService settings)
    {
        _settings = settings;
    }

    /// <summary>Profile ribbon for Advanced Settings header.</summary>
    [HttpGet("profile")]
    [ProducesResponseType(typeof(ApiResponse<DriverSettingsProfileResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<DriverSettingsProfileResponseDto>.Fail("Invalid token."));
        }

        var data = await _settings.GetProfileAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<DriverSettingsProfileResponseDto>.Ok(data));
    }

    /// <summary>Changes password and invalidates previous JWT issuance via TokenVersion bumps.</summary>
    [HttpPatch("change-password")]
    [ProducesResponseType(typeof(ApiResponse<ChangePasswordResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<ChangePasswordResponseDto>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.ChangePasswordAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<ChangePasswordResponseDto>.Ok(result, result.Message));
    }

    [HttpPatch("update-contact")]
    [ProducesResponseType(typeof(ApiResponse<UpdateContactResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> UpdateContact([FromBody] UpdateContactRequestDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<UpdateContactResponseDto>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.UpdateContactAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<UpdateContactResponseDto>.Ok(result, result.Message));
    }

    [HttpGet("notifications")]
    [ProducesResponseType(typeof(ApiResponse<NotificationPreferencesDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetNotifications(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<NotificationPreferencesDto>.Fail("Invalid token."));
        }

        var data = await _settings.GetNotificationPreferencesAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<NotificationPreferencesDto>.Ok(data));
    }

    [HttpPatch("notifications")]
    public async Task<IActionResult> PatchNotifications([FromBody] NotificationPreferencesPatchDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.UpsertNotificationPreferencesAsync(userId, dto, meta.ip, meta.ua,
                cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    [HttpGet("privacy")]
    public async Task<IActionResult> GetPrivacy(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<PrivacySettingsResponseDto>.Fail("Invalid token."));
        }

        var data = await _settings.GetPrivacySettingsAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<PrivacySettingsResponseDto>.Ok(data));
    }

    [HttpPatch("privacy")]
    public async Task<IActionResult> PatchPrivacy([FromBody] PrivacySettingsPatchDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.UpsertPrivacySettingsAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount([FromBody] ScheduleAccountDeletionRequestDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<ScheduleAccountDeletionResponseDto>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.ScheduleAccountDeletionAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<ScheduleAccountDeletionResponseDto>.Ok(result, result.Message));
    }

    [HttpPost("account/cancel-deletion")]
    public async Task<IActionResult> CancelDeletion(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<SimpleSuccessResponseDto>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _settings.CancelAccountDeletionAsync(userId, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    private bool TryGetUserId(out int id)
    {
        id = 0;
        var raw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return raw != null && int.TryParse(raw, out id);
    }

    private (string ip, string ua) ClientMeta()
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var ua = Request.Headers.UserAgent.ToString();
        if (string.IsNullOrWhiteSpace(ua))
        {
            ua = "unknown";
        }

        return (ip, ua);
    }
}
