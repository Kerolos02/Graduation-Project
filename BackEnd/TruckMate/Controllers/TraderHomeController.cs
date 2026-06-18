using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("api/trader")]
    [Authorize]
    public class TraderHomeController : ControllerBase
    {
        private readonly TruckMateDbContext _context;

        public TraderHomeController(TruckMateDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET api/trader/home
        // الـ Trader Home Page - كل البيانات في Request واحد
        // ============================================================
        [HttpGet("home")]
        public async Task<IActionResult> GetHome()
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { message = "Trader account required." });

            // ---- 1. Active Shipments (Pending / Scheduled / InProgress / Accepted) ----
            var activeShipments = await _context.ShipmentRequests
                .Include(s => s.AssignedDriver).ThenInclude(d => d!.User)
                .Where(s => s.TraderId == traderId &&
                    (s.Status == ShipmentStatus.Pending ||
                     s.Status == ShipmentStatus.Scheduled ||
                     s.Status == ShipmentStatus.InProgress ||
                     s.Status == ShipmentStatus.Accepted))
                .OrderByDescending(s => s.CreatedAt)
                .Select(s => new
                {
                    s.Id,
                    s.ShipmentId,
                    s.OriginCity,
                    s.DestinationCity,
                    s.ScheduledDate,
                    s.Weight,
                    s.TruckType,
                    status = s.Status.ToString(),
                    s.FinalCost,
                    assignedDriverName = s.AssignedDriver != null ? s.AssignedDriver.User.FullName : null
                })
                .ToListAsync();

            // ---- 2. Recent Offers (على شحنات الـ Trader) ----
            var recentOffers = await _context.Offers
                .Include(o => o.Driver).ThenInclude(d => d.User)
                .Include(o => o.ShipmentRequest)
                .Where(o => o.ShipmentRequest.TraderId == traderId &&
                            o.Status == OfferStatus.pending)
                .OrderByDescending(o => o.CreatedAt)
                .Take(10)
                .Select(o => new
                {
                    o.Id,
                    o.ShipmentRequestId,
                    origin = o.ShipmentRequest.OriginCity,
                    destination = o.ShipmentRequest.DestinationCity,
                    driverName = o.Driver.User.FullName,
                    driverId = o.DriverId,
                    o.Price,
                    status = o.Status.ToString(),
                    o.CreatedAt
                })
                .ToListAsync();

            // ---- 3. Available Drivers (مش assigned لـ trip نشطة دلوقتي) ----
            var busyDriverIds = await _context.Trips
                .Where(t => t.Status == TripStatus.inProgress || t.Status == TripStatus.created)
                .Select(t => t.DriverId)
                .Distinct()
                .ToListAsync();

            var availableDrivers = await _context.Drivers
                .Include(d => d.User)
                .Where(d => !busyDriverIds.Contains(d.Id))
                .Take(20)
                .Select(d => new
                {
                    d.Id,
                    fullName = d.User.FullName,
                    d.TruckType,
                    d.Capacity,
                    d.PlateNumber,
                    // Average Rating
                    averageRating = _context.Reviews
                        .Where(r => r.DriverId == d.Id && !r.IsDeleted)
                        .Select(r => (double?)r.Rating)
                        .Average() ?? 0
                })
                .ToListAsync();

            // ---- 4. Stats / Summary ----
            var allShipments = await _context.ShipmentRequests
                .Where(s => s.TraderId == traderId)
                .ToListAsync();

            var completedShipments = allShipments
                .Where(s => s.Status == ShipmentStatus.Completed).ToList();

            var stats = new
            {
                totalShipments = allShipments.Count,
                activeCount = activeShipments.Count,
                completedCount = completedShipments.Count,
                pendingCount = allShipments.Count(s => s.Status == ShipmentStatus.Pending),
                totalSpent = completedShipments.Sum(s => s.FinalCost ?? 0),
                averageCost = completedShipments.Any()
                                        ? Math.Round(completedShipments.Average(s => (double)(s.FinalCost ?? 0)), 2)
                                        : 0
            };

            return Ok(new
            {
                success = true,
                stats,
                activeShipments,
                recentOffers,
                availableDrivers
            });
        }

        // ============================================================
        // GET api/trader/shipments
        // كل الشحنات (current + closed) مع Filters
        // ============================================================
        [HttpGet("shipments")]
        public async Task<IActionResult> GetShipments(
            [FromQuery] string? status = null,
            [FromQuery] string? city = null,
            [FromQuery] DateTime? from = null,
            [FromQuery] DateTime? to = null)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { message = "Trader account required." });

            var query = _context.ShipmentRequests
                .Include(s => s.AssignedDriver).ThenInclude(d => d!.User)
                .Where(s => s.TraderId == traderId)
                .AsQueryable();

            // Filter by status
            if (!string.IsNullOrWhiteSpace(status) &&
                Enum.TryParse<ShipmentStatus>(status, true, out var parsedStatus))
                query = query.Where(s => s.Status == parsedStatus);

            // Filter by city (origin أو destination)
            if (!string.IsNullOrWhiteSpace(city))
                query = query.Where(s =>
                    s.OriginCity.ToLower().Contains(city.ToLower()) ||
                    s.DestinationCity.ToLower().Contains(city.ToLower()));

            // Filter by date range
            if (from.HasValue) query = query.Where(s => s.ScheduledDate >= from.Value);
            if (to.HasValue) query = query.Where(s => s.ScheduledDate <= to.Value);

            var shipments = await query
                .OrderByDescending(s => s.CreatedAt)
                .Select(s => new
                {
                    s.Id,
                    s.ShipmentId,
                    s.OriginCity,
                    s.DestinationCity,
                    s.ScheduledDate,
                    s.Weight,
                    s.TruckType,
                    status = s.Status.ToString(),
                    s.FinalCost,
                    s.CreatedAt,
                    driverName = s.AssignedDriver != null ? s.AssignedDriver.User.FullName : null
                })
                .ToListAsync();

            return Ok(new { success = true, count = shipments.Count, shipments });
        }

        // ============================================================
        // PUT api/trader/offers/{offerId}/accept
        // الـ Trader يقبل Offer من Driver
        // ============================================================
        [HttpPut("offers/{offerId}/accept")]
        public async Task<IActionResult> AcceptOffer(int offerId)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { message = "Trader account required." });

            var offer = await _context.Offers
                .Include(o => o.ShipmentRequest)
                .FirstOrDefaultAsync(o => o.Id == offerId &&
                                          o.ShipmentRequest.TraderId == traderId);

            if (offer == null)
                return NotFound(new { message = "Offer not found." });

            if (offer.Status != OfferStatus.pending)
                return BadRequest(new { message = "Offer already processed." });

            // قبول الـ Offer
            offer.Status = OfferStatus.accepted;

            // تحديث الشحنة
            var shipment = offer.ShipmentRequest;
            shipment.AssignedDriverId = offer.DriverId;
            shipment.FinalCost = offer.Price;
            shipment.Status = ShipmentStatus.Accepted;

            // رفض باقي الـ Offers على نفس الشحنة
            var otherOffers = await _context.Offers
                .Where(o => o.ShipmentRequestId == offer.ShipmentRequestId &&
                            o.Id != offerId &&
                            o.Status == OfferStatus.pending)
                .ToListAsync();

            foreach (var o in otherOffers)
                o.Status = OfferStatus.rejected;

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Offer accepted successfully." });
        }

        // ============================================================
        // PUT api/trader/offers/{offerId}/reject
        // الـ Trader يرفض Offer من Driver
        // ============================================================
        [HttpPut("offers/{offerId}/reject")]
        public async Task<IActionResult> RejectOffer(int offerId)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { message = "Trader account required." });

            var offer = await _context.Offers
                .Include(o => o.ShipmentRequest)
                .FirstOrDefaultAsync(o => o.Id == offerId &&
                                          o.ShipmentRequest.TraderId == traderId);

            if (offer == null)
                return NotFound(new { message = "Offer not found." });

            if (offer.Status != OfferStatus.pending)
                return BadRequest(new { message = "Offer already processed." });

            offer.Status = OfferStatus.rejected;
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Offer rejected." });
        }

        // ============================================================
        // Helper
        // ============================================================
        private async Task<int?> GetTraderIdFromClaims()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(claim, out var userId)) return null;
            var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
            return trader?.Id;
        }
    }
}