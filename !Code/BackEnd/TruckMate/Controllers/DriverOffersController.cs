using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverOffers.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Services.DriverHome;

namespace TruckMate.Controllers;

[ApiController]
[Route("api/driver/offers")]
[Authorize(Roles = nameof(UserRole.Driver))]
public class DriverOffersController : ControllerBase
{
    private readonly IDriverOfferService _service;

    public DriverOffersController(IDriverOfferService service)
    {
        _service = service;
    }

    /// <summary>Returns the active incoming offer card for the authenticated driver.</summary>
    [HttpGet("current")]
    [ProducesResponseType(typeof(ApiResponse<CurrentDriverOfferResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetCurrent(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<CurrentDriverOfferResponseDto>.Fail("Invalid user context."));
        }

        var data = await _service.GetCurrentOfferAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<CurrentDriverOfferResponseDto>.Ok(data));
    }

    /// <summary>Accepts a pending trip offer before it expires.</summary>
    [HttpPost("{offerId:guid}/accept")]
    [ProducesResponseType(typeof(ApiResponse<AcceptOfferResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> Accept(Guid offerId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<AcceptOfferResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _service.AcceptOfferAsync(userId, offerId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<AcceptOfferResponseDto>.Ok(data, "Trip accepted successfully"));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<AcceptOfferResponseDto>.Fail("Offer not found."));
        }
        catch (InvalidOperationException ex) when (ex.Message == "OFFER_EXPIRED")
        {
            return StatusCode((int)HttpStatusCode.Gone, ApiResponse<AcceptOfferResponseDto>.Fail("This offer has expired"));
        }
        catch (InvalidOperationException ex) when (ex.Message == "DRIVER_HAS_ACTIVE_TRIP")
        {
            return Conflict(ApiResponse<AcceptOfferResponseDto>.Fail("Driver already has an active trip."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<AcceptOfferResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Declines a pending trip offer and requests redispatch to another driver.</summary>
    [HttpPost("{offerId:guid}/decline")]
    [ProducesResponseType(typeof(ApiResponse<DriverOfferStatusCardDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> Decline(Guid offerId, [FromBody] DeclineOfferRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<DriverOfferStatusCardDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _service.DeclineOfferAsync(userId, offerId, request.Reason, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<DriverOfferStatusCardDto>.Ok(data, "Trip declined"));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<DriverOfferStatusCardDto>.Fail("Offer not found."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<DriverOfferStatusCardDto>.Fail(ex.Message));
        }
    }

    /// <summary>Polling fallback for clients when SignalR is unavailable.</summary>
    [HttpGet("{offerId:guid}/status")]
    [ProducesResponseType(typeof(ApiResponse<OfferStatusResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> Status(Guid offerId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<OfferStatusResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _service.GetOfferStatusAsync(userId, offerId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<OfferStatusResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException)
        {
            return NotFound(ApiResponse<OfferStatusResponseDto>.Fail("Offer not found."));
        }
    }

    private static bool TryGetUserId(ClaimsPrincipal principal, out int id)
    {
        id = 0;
        var raw = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return raw != null && int.TryParse(raw, out id);
    }

    private bool TryGetUserId(out int id) => TryGetUserId(User, out id);
}
