using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Services.DriverHome;

namespace TruckMate.Controllers;

/// <summary>Driver mobile home &amp; courier trip actions.</summary>
[ApiController]
[Route("api/driver")]
[Authorize(Roles = nameof(UserRole.Driver))]
public class DriverController : ControllerBase
{
    private readonly IDriverHomeService _driverHome;
    private readonly ILogger<DriverController> _logger;

    public DriverController(IDriverHomeService driverHome, ILogger<DriverController> logger)
    {
        _driverHome = driverHome;
        _logger = logger;
    }

    /// <summary>Aggregates profile, active trip, today stats, and recent deliveries.</summary>
    [HttpGet("home")]
    [ProducesResponseType(typeof(ApiResponse<DriverHomeResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetHome(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<DriverHomeResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.BuildHomePayloadAsync(userId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<DriverHomeResponseDto>.Ok(data));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Home payload failed for user {UserId}", userId);
            return BadRequest(ApiResponse<DriverHomeResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Toggles online/offline availability and notifies dispatchers over SignalR.</summary>
    [HttpPatch("status")]
    [ProducesResponseType(typeof(ApiResponse<DriverStatusPatchResponse>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<DriverStatusPatchResponse>), (int)HttpStatusCode.BadRequest)]
    public async Task<IActionResult> PatchStatus([FromBody] DriverStatusPatchRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<DriverStatusPatchResponse>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.UpdateAvailabilityAsync(userId, request.Status, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<DriverStatusPatchResponse>.Ok(data, data.Message));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<DriverStatusPatchResponse>.Fail(ex.Message));
        }
    }

    /// <summary>Lists pending zone-matched courier offers visible while the driver is online.</summary>
    [HttpGet("incoming-trips")]
    [ProducesResponseType(typeof(ApiResponse<IncomingTripsResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetIncomingTrips(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<IncomingTripsResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.GetIncomingOffersAsync(userId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<IncomingTripsResponseDto>.Ok(data));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<IncomingTripsResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Marks an assigned courier trip as in-progress.</summary>
    [HttpPost("trips/{tripId:guid}/start")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> StartTrip(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.StartAssignedTripAsync(userId, tripId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Trip started."));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Start trip rejected for user {UserId}", userId);
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Returns driver trip execution payload for pickup/transit/delivery screens.</summary>
    [HttpGet("trips/{tripId:guid}/execution")]
    [ProducesResponseType(typeof(ApiResponse<DriverTripExecutionScreenDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> TripExecution(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<DriverTripExecutionScreenDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.GetTripExecutionScreenAsync(userId, tripId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<DriverTripExecutionScreenDto>.Ok(data));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Trip execution rejected for user {UserId}", userId);
            return NotFound(ApiResponse<DriverTripExecutionScreenDto>.Fail(ex.Message));
        }
    }

    [HttpPost("trips/{tripId:guid}/arrive-pickup")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> ArrivePickup(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.MarkArrivedAtPickupAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Arrived at pickup."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    [HttpPost("trips/{tripId:guid}/confirm-pickup")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> ConfirmPickup(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.ConfirmPickupAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Pickup confirmed."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    [HttpPost("trips/{tripId:guid}/start-delivery")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> StartDelivery(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.StartDeliveryAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Delivery started."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    [HttpPost("trips/{tripId:guid}/mark-delivered")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> MarkDelivered(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.MarkDeliveredAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Marked delivered."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Lightweight retry endpoint for connection-loss UI.</summary>
    [HttpGet("trips/{tripId:guid}/sync")]
    [ProducesResponseType(typeof(ApiResponse<object>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> SyncTrip(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.GetTripExecutionScreenAsync(userId, tripId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { status = "connected", trip = data }));
        }
        catch (Exception ex) when (ex is InvalidOperationException)
        {
            return Ok(ApiResponse<object>.Ok(new { status = "error", reason = ex.Message }));
        }
    }

    /// <summary>Marks an in-progress courier trip as completed and creates earning record.</summary>
    [HttpPost("trips/{tripId:guid}/complete")]
    [ProducesResponseType(typeof(ApiResponse<StartTripResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> CompleteTrip(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<StartTripResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.CompleteAssignedTripAsync(userId, tripId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<StartTripResponseDto>.Ok(data, "Trip completed."));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Complete trip rejected for user {UserId}", userId);
            return Conflict(ApiResponse<StartTripResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Deep-link friendly payload for assigned trip introspection.</summary>
    [HttpGet("trips/{tripId:guid}/details")]
    [ProducesResponseType(typeof(ApiResponse<TripDetailsResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> TripDetails(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<TripDetailsResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data = await _driverHome.GetCourierTripDetailsAsync(userId, tripId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<TripDetailsResponseDto>.Ok(data));
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Trip details rejected for user {UserId}", userId);
            return NotFound(ApiResponse<TripDetailsResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>Paginated ledger of historical completed courier trips.</summary>
    [HttpGet("trips/recent")]
    [ProducesResponseType(typeof(ApiResponse<RecentTripsPageResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> RecentTrips([FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(ApiResponse<RecentTripsPageResponseDto>.Fail("Invalid user context."));
        }

        try
        {
            var data =
                await _driverHome.GetRecentCourierTripsPageAsync(userId, page, pageSize, cancellationToken)
                    .ConfigureAwait(false);
            return Ok(ApiResponse<RecentTripsPageResponseDto>.Ok(data));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<RecentTripsPageResponseDto>.Fail(ex.Message));
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
