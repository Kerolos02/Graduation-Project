using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverTrips.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Services.DriverTrips;
using TruckMate.Validation;

namespace TruckMate.Controllers;

/// <summary>Driver marketplace: browse open trip requests, accept/reject, and list assigned trips.</summary>
[ApiController]
[Route("api/driver/trips")]
[Authorize(Roles = nameof(UserRole.Driver))]
public class DriverMarketplaceTripsController : ControllerBase
{
    private readonly ITripRequestService _tripRequests;

    public DriverMarketplaceTripsController(ITripRequestService tripRequests)
    {
        _tripRequests = tripRequests;
    }

    /// <summary>Available Requests tab — paginated open requests excluding this driver's rejections.</summary>
    [HttpGet("available-requests")]
    [ProducesResponseType(typeof(ApiResponse<AvailableTripRequestsResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Forbidden)]
    public async Task<IActionResult> GetAvailableRequests([FromQuery] MarketplaceAvailableRequestsQuery query,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        var data = await _tripRequests
            .GetAvailableRequestsAsync(userId, query.SortBy, query.Page, query.PageSize, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<AvailableTripRequestsResponseDto>.Ok(data));
    }

    /// <summary>Request Details screen — includes trader phone and special notes (not returned on the list endpoint).</summary>
    [HttpGet("requests/{requestId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<TripRequestDetailResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Conflict)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Gone)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Forbidden)]
    public async Task<IActionResult> GetRequestDetail(Guid requestId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        var data = await _tripRequests.GetRequestDetailAsync(requestId, userId, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<TripRequestDetailResponseDto>.Ok(data));
    }

    /// <summary>Accept a marketplace request and create an assigned <see cref="Core.Models.DeliveryTrip"/>.</summary>
    [HttpPost("requests/{requestId:guid}/accept")]
    [ProducesResponseType(typeof(ApiResponse<AcceptTripRequestResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Conflict)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Gone)]
    public async Task<IActionResult> AcceptRequest(Guid requestId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        var data = await _tripRequests.AcceptRequestAsync(requestId, userId, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<AcceptTripRequestResponseDto>.Ok(data, "Request accepted."));
    }

    /// <summary>Reject hides the request from this driver's available list; it stays open for others.</summary>
    [HttpPost("requests/{requestId:guid}/reject")]
    [ProducesResponseType(typeof(ApiResponse<RejectTripRequestResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Conflict)]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.Gone)]
    public async Task<IActionResult> RejectRequest(Guid requestId, [FromBody] RejectTripRequestRequestDto body,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        var (message, id) =
            await _tripRequests.RejectRequestAsync(requestId, userId, body.Reason, cancellationToken)
                .ConfigureAwait(false);
        return Ok(ApiResponse<RejectTripRequestResponseDto>.Ok(new RejectTripRequestResponseDto { RequestId = id },
            message));
    }

    /// <summary>My Trips tab — trips assigned to this driver via marketplace or dispatch.</summary>
    [HttpGet("my-trips")]
    [ProducesResponseType(typeof(ApiResponse<MyMarketplaceTripsResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetMyTrips([FromQuery] MarketplaceMyTripsQuery query,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        var data = await _tripRequests
            .GetMyTripsAsync(userId, query.Status, query.Page, query.PageSize, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<MyMarketplaceTripsResponseDto>.Ok(data));
    }

    private bool TryGetUserId(out int userId)
    {
        userId = 0;
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
        return int.TryParse(raw, out userId);
    }
}
