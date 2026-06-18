using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReviewController : ControllerBase
    {
        private readonly TruckMateDbContext _context;

        public ReviewController(TruckMateDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // POST api/review
        // الـ Trader يعمل review للـ Driver بعد ما الـ Trip تخلص
        // ============================================================
        [HttpPost]
        public async Task<IActionResult> AddReview([FromBody] AddReviewDto dto)
        {
            // جيب الـ Trader من الـ Token
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { success = false, message = "Trader account required." });

            // تحقق إن الـ Rating بين 1 و 5
            if (dto.Rating < 1 || dto.Rating > 5)
                return BadRequest(new { success = false, message = "Invalid rating value." });

            // تحقق إن الـ Comment مش فاضي ولو اتبعت
            if (dto.Comment != null && (dto.Comment.Length < 10 || dto.Comment.Length > 500))
                return BadRequest(new { success = false, message = "Review must be between 10 and 500 characters." });

            // جيب الـ Trip وتأكد إنها Completed وبتاعت الـ Trader ده
            var trip = await _context.Trips
                .Include(t => t.ShipmentRequest)
                .FirstOrDefaultAsync(t => t.Id == dto.TripId
                    && t.ShipmentRequest.TraderId == traderId
                    && t.Status == TripStatus.completed);

            if (trip == null)
                return NotFound(new { success = false, message = "Trip not found or not completed yet." });

            // تأكد مفيش review قبل كده لنفس الـ Trip
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.TripId == dto.TripId && r.TraderId == traderId);

            if (existingReview != null)
                return BadRequest(new { success = false, message = "You already reviewed this trip." });

            var review = new Review
            {
                TripId = dto.TripId,
                TraderId = traderId.Value,
                DriverId = trip.DriverId,
                Rating = dto.Rating,
                Comment = dto.Comment
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Review saved successfully." });
        }

        // ============================================================
        // PUT api/review/{id}
        // الـ Trader يعدل الـ Review بتاعته
        // ============================================================
        [HttpPut("{id}")]
        public async Task<IActionResult> EditReview(int id, [FromBody] EditReviewDto dto)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized(new { success = false, message = "Trader account required." });

            if (dto.Rating < 1 || dto.Rating > 5)
                return BadRequest(new { success = false, message = "Invalid rating value." });

            if (dto.Comment != null && (dto.Comment.Length < 10 || dto.Comment.Length > 500))
                return BadRequest(new { success = false, message = "Review must be between 10 and 500 characters." });

            var review = await _context.Reviews
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (review == null)
                return NotFound(new { success = false, message = "Review not found." });

            // بس صاحب الـ Review يقدر يعدلها
            if (review.TraderId != traderId)
                return Forbid("You cannot edit this review.");

            review.Rating = dto.Rating;
            review.Comment = dto.Comment;
            review.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Review updated successfully." });
        }

        // ============================================================
        // DELETE api/review/{id}
        // الـ Trader يحذف الـ Review بتاعته - أو الـ Admin يحذف أي review
        // ============================================================
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReview(int id)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out var userId))
                return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return Unauthorized();

            var review = await _context.Reviews
                .FirstOrDefaultAsync(r => r.Id == id && !r.IsDeleted);

            if (review == null)
                return NotFound(new { success = false, message = "Review not found." });

            // الـ Admin يحذف أي review
            if (user.Role == UserRole.Admin)
            {
                review.IsDeleted = true;
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Review removed successfully." });
            }

            // الـ Trader يحذف بس الـ Review بتاعته
            var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
            if (trader == null || review.TraderId != trader.Id)
                return Forbid("You cannot edit this review.");

            review.IsDeleted = true;
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Review removed successfully." });
        }

        // ============================================================
        // GET api/review/driver/{driverId}
        // اجيب كل الـ Reviews بتاعة Driver معين + Average Rating
        // ============================================================
        [HttpGet("driver/{driverId}")]
        public async Task<IActionResult> GetDriverReviews(int driverId, [FromQuery] string sort = "newest")
        {
            var driverExists = await _context.Drivers.AnyAsync(d => d.Id == driverId);
            if (!driverExists)
                return NotFound(new { success = false, message = "Driver not found." });

            var query = _context.Reviews
                .Include(r => r.Trader)
                    .ThenInclude(t => t.User)
                .Where(r => r.DriverId == driverId && !r.IsDeleted);

            query = sort switch
            {
                "highest" => query.OrderByDescending(r => r.Rating),
                "lowest" => query.OrderBy(r => r.Rating),
                _ => query.OrderByDescending(r => r.CreatedAt) // newest
            };

            var reviews = await query.ToListAsync();

            if (!reviews.Any())
                return Ok(new { success = true, message = "No reviews yet.", averageRating = 0, reviews = new List<object>() });

            var averageRating = reviews.Average(r => r.Rating);

            var result = reviews.Select(r => new
            {
                r.Id,
                r.TripId,
                traderName = r.Trader.User.FullName,
                r.Rating,
                r.Comment,
                r.CreatedAt
            });

            return Ok(new
            {
                success = true,
                message = "Average rating updated.",
                averageRating = Math.Round(averageRating, 1),
                reviews = result
            });
        }

        // ============================================================
        // Helper
        // ============================================================
        private async Task<int?> GetTraderIdFromClaims()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out var userId)) return null;
            var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
            return trader?.Id;
        }
    }

    // ============================================================
    // DTOs
    // ============================================================
    public class AddReviewDto
    {
        public int TripId { get; set; }
        public int Rating { get; set; }       // 1 - 5
        public string? Comment { get; set; }  // 10 - 500 chars
    }

    public class EditReviewDto
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}