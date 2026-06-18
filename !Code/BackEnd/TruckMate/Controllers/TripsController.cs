using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;
using TruckMate.Core.Models; 

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TripsController : ControllerBase
    {
        private readonly TruckMateDbContext _context;

        public TripsController(TruckMateDbContext context)
        {
            _context = context;
        }

        [HttpGet("available-requests")]
        public async Task<IActionResult> GetRequests()
        {
            var requests = await _context.ShipmentRequests
                .Include(s => s.Trader)
                .ToListAsync();
            return Ok(requests);
        }

        [HttpPost("accept-request")]
        public async Task<IActionResult> AcceptRequest(int shipmentId, int driverId, int offerId)
        {
            var newTrip = new Trip
            {
                ShipmentRequestId = shipmentId,
                DriverId = driverId,
                OfferId = offerId,
                Status = TripStatus.created,
                StartedAt = DateTime.Now
            };

            _context.Trips.Add(newTrip);

            var offer = await _context.Offers.FindAsync(offerId);
            if (offer != null) offer.Status = OfferStatus.accepted;

            await _context.SaveChangesAsync();
            return Ok(new { message = "تم قبول الطلب وبدء الرحلة", tripId = newTrip.Id });
        }

        [HttpPost("{id}/complete")]
        public async Task<IActionResult> CompleteTrip(int id)
        {
            var trip = await _context.Trips.Include(t => t.Offer).FirstOrDefaultAsync(t => t.Id == id);
            if (trip == null) return NotFound();

            trip.CompletedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return Ok("تم إنهاء الرحلة بنجاح");
        }
    }
}