using System.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TruckMate.Core.DriverHome;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Services.Legal;

namespace TruckMate.Controllers;

[ApiController]
[Route("api/legal")]
public class LegalDocumentsController : ControllerBase
{
    private readonly ILegalDocumentService _legal;

    public LegalDocumentsController(ILegalDocumentService legal)
    {
        _legal = legal;
    }

    /// <summary>Returns the active legal document for the requested route key.</summary>
    [HttpGet("documents/{type}")]
    [Authorize(Roles = nameof(UserRole.Driver) + "," + nameof(UserRole.Trader))]
    [ProducesResponseType(typeof(ApiResponse<LegalDocumentResponseDto>), (int)HttpStatusCode.OK)]
    public async Task<IActionResult> GetDocument(string type, CancellationToken cancellationToken)
    {
        var doc = await _legal.GetActiveCachedAsync(type, cancellationToken).ConfigureAwait(false);
        if (doc == null)
        {
            return NotFound(ApiResponse<LegalDocumentResponseDto>.Fail("Document not available."));
        }

        return Ok(ApiResponse<LegalDocumentResponseDto>.Ok(doc));
    }
}
