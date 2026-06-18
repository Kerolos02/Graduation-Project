using System.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.Auth;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverWallet.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.DriverWallet;

namespace TruckMate.Controllers;

/// <summary>Driver wallet endpoints for summary and earning trips.</summary>
[ApiController]
[Route("api/driver/wallet")]
[Authorize(Roles = nameof(UserRole.Driver))]
public class DriverWalletController : ControllerBase
{
    private readonly IDriverWalletService _walletService;
    private readonly IUnitOfWork _uow;
    private readonly ILogger<DriverWalletController> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public DriverWalletController(IDriverWalletService walletService, IUnitOfWork uow,
        ILogger<DriverWalletController> logger, IHttpContextAccessor httpContextAccessor)
    {
        _walletService = walletService;
        _uow = uow;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
    }

    /// <summary>Returns wallet totals, growth, and summary cards.</summary>
    [HttpGet("screen")]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletScreenResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetScreen([FromQuery] DriverWalletTripsQueryDto query, CancellationToken cancellationToken)
    {
        if (!TryGetDriverPublicId(out var driverPublicId))
        {
            return Unauthorized(ApiResponse<DriverWalletScreenResponseDto>.Fail("Invalid driver context."));
        }

        var data = await _walletService
            .GetWalletScreenAsync(driverPublicId, query.Filter, query.Page, query.PageSize, cancellationToken)
            .ConfigureAwait(false);
        await LogWalletViewedAsync(driverPublicId, $"screen:{data.ActiveFilter}", cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<DriverWalletScreenResponseDto>.Ok(data));
    }

    /// <summary>Returns wallet totals, growth, and summary cards.</summary>
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletSummaryResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        if (!TryGetDriverPublicId(out var driverPublicId))
        {
            return Unauthorized(ApiResponse<DriverWalletSummaryResponseDto>.Fail("Invalid driver context."));
        }

        var summary = await _walletService.GetWalletSummaryAsync(driverPublicId, cancellationToken).ConfigureAwait(false);
        await LogWalletViewedAsync(driverPublicId, "summary", cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<DriverWalletSummaryResponseDto>.Ok(summary));
    }

    /// <summary>Returns paginated earning trips with tab filter.</summary>
    [HttpGet("trips")]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletTripsResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletTripsResponseDto>), (int)HttpStatusCode.UnprocessableEntity)]
    public async Task<IActionResult> GetTrips([FromQuery] DriverWalletTripsQueryDto query,
        CancellationToken cancellationToken)
    {
        if (!TryGetDriverPublicId(out var driverPublicId))
        {
            return Unauthorized(ApiResponse<DriverWalletTripsResponseDto>.Fail("Invalid driver context."));
        }

        var data = await _walletService
            .GetEarningTripsAsync(driverPublicId, query.Filter, query.Page, query.PageSize, cancellationToken)
            .ConfigureAwait(false);
        await LogWalletViewedAsync(driverPublicId, $"trips:{data.Filter}", cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<DriverWalletTripsResponseDto>.Ok(data));
    }

    /// <summary>Returns a single earning-trip detail owned by authenticated driver.</summary>
    [HttpGet("trips/{tripId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletTripDetailResponseDto>), (int)HttpStatusCode.OK)]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletTripDetailResponseDto>), (int)HttpStatusCode.Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<DriverWalletTripDetailResponseDto>), (int)HttpStatusCode.NotFound)]
    public async Task<IActionResult> GetTripDetail(Guid tripId, CancellationToken cancellationToken)
    {
        if (!TryGetDriverPublicId(out var driverPublicId))
        {
            return Unauthorized(ApiResponse<DriverWalletTripDetailResponseDto>.Fail("Invalid driver context."));
        }

        var canAccess = await _walletService.CanAccessTripAsync(driverPublicId, tripId, cancellationToken)
            .ConfigureAwait(false);
        if (!canAccess)
        {
            var existsForAny = await _uow.DriverEarnings.ExistsByTripIdAsync(tripId, cancellationToken).ConfigureAwait(false);
            if (existsForAny)
            {
                return StatusCode((int)HttpStatusCode.Forbidden,
                    ApiResponse<DriverWalletTripDetailResponseDto>.Fail("You cannot access this trip."));
            }

            return NotFound(ApiResponse<DriverWalletTripDetailResponseDto>.Fail("Trip earning not found."));
        }

        var detail = await _walletService.GetEarningTripDetailAsync(driverPublicId, tripId, cancellationToken)
            .ConfigureAwait(false);
        if (detail == null)
        {
            return NotFound(ApiResponse<DriverWalletTripDetailResponseDto>.Fail("Trip earning not found."));
        }

        await LogWalletViewedAsync(driverPublicId, $"trip:{tripId}", cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<DriverWalletTripDetailResponseDto>.Ok(detail));
    }

    private bool TryGetDriverPublicId(out Guid driverPublicId)
    {
        driverPublicId = Guid.Empty;
        var raw = User.FindFirst(JwtCustomClaims.DriverPublicId)?.Value;
        return raw != null && Guid.TryParse(raw, out driverPublicId);
    }

    private async Task LogWalletViewedAsync(Guid driverPublicId, string scope, CancellationToken cancellationToken)
    {
        var http = _httpContextAccessor.HttpContext;
        var ip = http?.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var userAgent = http?.Request.Headers.UserAgent.ToString();

        await _uow.DriverAuditLogs.AddAsync(new DriverAuditLog
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driverPublicId,
            Action = "WalletViewed",
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = string.IsNullOrWhiteSpace(ip) ? "unknown" : ip,
            UserAgent = string.IsNullOrWhiteSpace(userAgent) ? "unknown" : userAgent,
            AdditionalData = scope
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogDebug("Wallet view logged for driver {DriverId} scope {Scope}", driverPublicId, scope);
    }
}
