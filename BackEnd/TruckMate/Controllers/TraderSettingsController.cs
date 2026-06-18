using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.TraderSettings.Dtos;
using TruckMate.Services.TraderSettings;

namespace TruckMate.Controllers;

/// <summary>Trader advanced settings endpoints (shipper-facing mobile app).</summary>
[ApiController]
[Route("api/trader/settings")]
[Authorize(Roles = nameof(UserRole.Trader))]
public class TraderSettingsController : ControllerBase
{
    private readonly ITraderSettingsService _settings;
    private readonly ITraderNotificationPreferencesService _notifications;
    private readonly ITraderPrivacyService _privacy;

    public TraderSettingsController(
        ITraderSettingsService settings,
        ITraderNotificationPreferencesService notifications,
        ITraderPrivacyService privacy)
    {
        _settings = settings;
        _notifications = notifications;
        _privacy = privacy;
    }

    /// <summary>Trader profile ribbon for Advanced Settings header.</summary>
    [HttpGet("profile")]
    [ProducesResponseType(typeof(ApiResponse<TraderSettingsProfileResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<TraderSettingsProfileResponseDto>.Fail("Invalid token."));
        }

        var data = await _settings.GetProfileAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<TraderSettingsProfileResponseDto>.Ok(data));
    }

    /// <summary>Changes password for the Trader account.</summary>
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

    /// <summary>Updates email and/or phone; verification flows are queued.</summary>
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

    /// <summary>Returns shipment and payment lifecycle notification switches.</summary>
    [HttpGet("notifications")]
    [ProducesResponseType(typeof(ApiResponse<TraderNotificationPreferencesResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetNotifications(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<TraderNotificationPreferencesResponseDto>.Fail("Invalid token."));
        }

        var data = await _notifications.GetAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<TraderNotificationPreferencesResponseDto>.Ok(data));
    }

    /// <summary>Upserts Trader notification preference rows.</summary>
    [HttpPatch("notifications")]
    [ProducesResponseType(typeof(ApiResponse<SimpleSuccessResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> PatchNotifications([FromBody] TraderNotificationPreferencesPatchDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result = await _notifications.UpdateAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    /// <summary>Returns business privacy posture and GDPR timestamps.</summary>
    [HttpGet("privacy")]
    [ProducesResponseType(typeof(ApiResponse<TraderPrivacySettingsResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetPrivacy(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<TraderPrivacySettingsResponseDto>.Fail("Invalid token."));
        }

        var data = await _privacy.GetAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<TraderPrivacySettingsResponseDto>.Ok(data));
    }

    /// <summary>Updates privacy toggles with per-field GDPR audit logging.</summary>
    [HttpPatch("privacy")]
    [ProducesResponseType(typeof(ApiResponse<SimpleSuccessResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> PatchPrivacy([FromBody] TraderPrivacySettingsPatchDto dto,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result = await _privacy.UpdateAsync(userId, dto, meta.ip, meta.ua, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    /// <summary>
    /// Requests a GDPR data portability export ZIP (queued; email sent when ready).
    /// </summary>
    [HttpPost("privacy/data-export-request")]
    [ProducesResponseType(typeof(ApiResponse<SimpleSuccessResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> RequestDataExport(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid token."));
        }

        var meta = ClientMeta();
        var result =
            await _privacy.RequestDataExportAsync(userId, meta.ip, meta.ua, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<SimpleSuccessResponseDto>.Ok(result, result.Message));
    }

    /// <summary>
    /// Schedules Trader account deletion with a grace period unless blocked shipments exist.
    /// </summary>
    [HttpDelete("account")]
    [ProducesResponseType(typeof(ApiResponse<ScheduleAccountDeletionResponseDto>), (int)HttpStatusCode.OK)]
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

    /// <summary>Cancels a pending Trader account deletion inside the grace window.</summary>
    [HttpPost("account/cancel-deletion")]
    [ProducesResponseType(typeof(ApiResponse<SimpleSuccessResponseDto>), (int)HttpStatusCode.OK)]
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
