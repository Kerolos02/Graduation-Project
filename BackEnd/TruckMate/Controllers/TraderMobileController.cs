using System.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.Auth;
using TruckMate.Core.DriverHome;
using TruckMate.Core.Enums;
using TruckMate.Core.TraderMobile.Dtos;
using TruckMate.Services.TraderMobile;

namespace TruckMate.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Trader))]
public class TraderMobileController : ControllerBase
{
    private readonly ITraderMobileService _service;
    private readonly ILogger<TraderMobileController> _logger;

    public TraderMobileController(ITraderMobileService service, ILogger<TraderMobileController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpGet("api/trader/mobile/home-current-shipment")]
    public async Task<IActionResult> HomeCurrentShipment(CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        var data = await _service.GetHomeCurrentShipmentAsync(traderId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<TraderHomeCurrentShipmentResponseDto>.Ok(data));
    }

    [HttpGet("api/trader/mobile/shipments/{shipmentId:guid}/details")]
    public async Task<IActionResult> ShipmentDetails(Guid shipmentId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetShipmentDetailsAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<TraderShipmentDetailsResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/mobile/shipments/{shipmentId:guid}/offers")]
    public async Task<IActionResult> ShipmentOffers(Guid shipmentId, [FromQuery] string tab = "pending",
        [FromQuery] int page = 1, [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetShipmentOffersAsync(traderId, shipmentId, tab, page, pageSize, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<DriverOffersResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/mobile/offers/{offerId:guid}/accept")]
    public async Task<IActionResult> AcceptOffer(Guid offerId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            await _service.AcceptOfferAsync(traderId, offerId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { success = true }));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/mobile/offers/{offerId:guid}/reject")]
    public async Task<IActionResult> RejectOffer(Guid offerId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            await _service.RejectOfferAsync(traderId, offerId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { success = true }));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/shipments/{shipmentId:guid}/suggested-drivers")]
    [ProducesResponseType(typeof(ApiResponse<SuggestedDriversResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetSuggestedDrivers(Guid shipmentId, [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetSuggestedDriversAsync(traderId, shipmentId, page, pageSize, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<SuggestedDriversResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/drivers/{driverId:guid}/details")]
    public async Task<IActionResult> GetDriverDetails(Guid driverId, [FromQuery] Guid? shipmentId,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetDriverDetailsAsync(traderId, driverId, shipmentId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<DriverDetailsResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/shipments/{shipmentId:guid}/select-driver")]
    public async Task<IActionResult> SelectDriver(Guid shipmentId, [FromBody] SelectDriverRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.SelectDriverAsync(traderId, shipmentId, request.DriverId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<SelectDriverResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/shipments/{shipmentId:guid}/tracking")]
    public async Task<IActionResult> GetTracking(Guid shipmentId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetTrackingAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<ShipmentTrackingResponseDto>.Ok(data));
        }
        catch (OperationCanceledException)
        {
            return StatusCode((int)HttpStatusCode.Gone, ApiResponse<object>.Fail("Shipment was cancelled."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/shipments/{shipmentId:guid}/mark-delivered")]
    public async Task<IActionResult> MarkDelivered(Guid shipmentId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var deliveredAt = await _service.MarkDeliveredAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { deliveredAt }));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/shipments/{shipmentId:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid shipmentId, [FromBody] CancelShipmentRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            await _service.CancelShipmentAsync(traderId, shipmentId, request.Reason, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { success = true }));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/shipments/{shipmentId:guid}/delivery-summary")]
    public async Task<IActionResult> DeliverySummary(Guid shipmentId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetDeliverySummaryAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<DeliverySummaryResponseDto>.Ok(data));
        }
        catch (Exception ex) when (ex is InvalidOperationException or KeyNotFoundException)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/shipments/{shipmentId:guid}/rate-driver")]
    public async Task<IActionResult> RateDriver(Guid shipmentId, [FromBody] RateDriverRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            await _service.RateDriverAsync(traderId, shipmentId, request.Rating, request.Comment, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { success = true }, "Thank you for your feedback!"));
        }
        catch (Microsoft.EntityFrameworkCore.DbUpdateException ex)
        {
            _logger.LogWarning(ex, "Duplicate driver rating for shipment {ShipmentId}", shipmentId);
            return Conflict(ApiResponse<object>.Fail("Driver already rated for this shipment."));
        }
        catch (Exception ex) when (ex is KeyNotFoundException or InvalidOperationException)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/invoices/{invoiceId:guid}")]
    public async Task<IActionResult> GetInvoice(Guid invoiceId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var data = await _service.GetInvoiceDetailsAsync(traderId, invoiceId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<InvoiceDetailsResponseDto>.Ok(data));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPost("api/trader/invoices/{invoiceId:guid}/pay")]
    public async Task<IActionResult> PayInvoice(Guid invoiceId, [FromBody] PayInvoiceRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            var (paidAt, paidWith) = await _service.PayInvoiceAsync(traderId, invoiceId, request.PaymentCardId, cancellationToken)
                .ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new
            {
                message = "Payment successful",
                paidAt,
                paidWith,
                receiptUrl = $"/api/trader/invoices/{invoiceId}/pdf"
            }));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<object>.Fail(ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("api/trader/invoices/{invoiceId:guid}/pdf")]
    public async Task<IActionResult> GetInvoicePdf(Guid invoiceId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized();
        }

        var pdf = await _service.GenerateInvoicePdfAsync(traderId, invoiceId, cancellationToken).ConfigureAwait(false);
        var invoice = await _service.GetInvoiceDetailsAsync(traderId, invoiceId, cancellationToken).ConfigureAwait(false);
        return File(pdf, "application/pdf", $"Invoice-{invoice.InvoiceNumber}.pdf");
    }

    [HttpPost("api/trader/invoices/{invoiceId:guid}/share")]
    public async Task<IActionResult> ShareInvoice(Guid invoiceId, [FromBody] ShareInvoiceRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        var result = await _service.ShareInvoiceAsync(traderId, invoiceId, request.Method, cancellationToken)
            .ConfigureAwait(false);
        return Ok(ApiResponse<object>.Ok(new { result }));
    }

    [HttpGet("api/trader/wallet")]
    public async Task<IActionResult> Wallet(CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        var data = await _service.GetWalletAsync(traderId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<TraderWalletResponseDto>.Ok(data));
    }

    [HttpPost("api/trader/wallet/cards")]
    public async Task<IActionResult> AddCard([FromBody] AddCardRequestDto request, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        var card = await _service.AddCardAsync(traderId, request, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<object>.Ok(new { card }));
    }

    [HttpDelete("api/trader/wallet/cards/{cardId:guid}")]
    public async Task<IActionResult> DeleteCard(Guid cardId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        try
        {
            await _service.DeleteCardAsync(traderId, cardId, cancellationToken).ConfigureAwait(false);
            return Ok(ApiResponse<object>.Ok(new { success = true }));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPatch("api/trader/wallet/cards/{cardId:guid}/set-default")]
    public async Task<IActionResult> SetDefaultCard(Guid cardId, CancellationToken cancellationToken = default)
    {
        if (!TryGetTraderId(out var traderId))
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid trader context."));
        }

        await _service.SetDefaultCardAsync(traderId, cardId, cancellationToken).ConfigureAwait(false);
        return Ok(ApiResponse<object>.Ok(new { success = true }));
    }

    private bool TryGetTraderId(out Guid traderId)
    {
        traderId = Guid.Empty;
        var raw = User.FindFirst(JwtCustomClaims.TraderPublicId)?.Value;
        return raw != null && Guid.TryParse(raw, out traderId);
    }
}
