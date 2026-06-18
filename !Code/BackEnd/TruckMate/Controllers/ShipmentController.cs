using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Core.Shipments;
using TruckMate.Data.Context;
using TruckMate.Services;

namespace TruckMate.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ShipmentController : ControllerBase
    {
        private readonly TruckMateDbContext _context;
        private readonly IShipmentService _shipmentService;

        public ShipmentController(TruckMateDbContext context, IShipmentService shipmentService)
        {
            _context = context;
            _shipmentService = shipmentService;
        }

        [HttpPost("estimate")]
        public async Task<ActionResult<CostTimeEstimateDto>> EstimateCostAndTime([FromBody] CreateShipmentRequestDto request)
        {
            var estimate = await _shipmentService.EstimateCostAndTimeAsync(request);
            return Ok(estimate);
        }

        [HttpPost]
        public async Task<ActionResult<ShipmentResponseDto>> CreateShipment([FromBody] CreateShipmentRequestDto request)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized("Trader account required.");

            if (request.IsRefrigerated && (request.MinTemperature == null || request.MaxTemperature == null))
                return BadRequest("Min and Max temperature are required when refrigerated.");

            var shipment = new ShipmentRequest
            {
                TraderId = traderId.Value,
                OriginCity = request.PickupLocation,
                DestinationCity = request.DropOffLocation,
                ScheduledDate = request.ScheduledDate,
                ScheduledTime = request.ScheduledTime,
                PackageCount = request.PackageCount,
                Weight = request.Weight,
                IsFragile = request.IsFragile,
                IsRefrigerated = request.IsRefrigerated,
                MinTemperature = request.MinTemperature,
                MaxTemperature = request.MaxTemperature,
                Status = ShipmentStatus.Pending
            };

            _context.ShipmentRequests.Add(shipment);
            await _context.SaveChangesAsync();

            return Ok(MapToResponse(shipment));
        }

        [HttpPut("{id}/confirm")]
        public async Task<ActionResult<ShipmentResponseDto>> ConfirmShipment(int id, [FromBody] ConfirmShipmentDto dto)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized("Trader account required.");

            var shipment = await _context.ShipmentRequests
                .Include(s => s.AssignedDriver)
                .ThenInclude(d => d!.User)
                .FirstOrDefaultAsync(s => s.Id == id && s.TraderId == traderId);

            if (shipment == null)
                return NotFound("Shipment not found.");

            if (shipment.Status != ShipmentStatus.Pending)
                return BadRequest("Shipment is already confirmed or in progress.");

            var driverExists = await _context.Drivers.AnyAsync(d => d.Id == dto.DriverId);
            if (!driverExists)
                return BadRequest("Invalid driver.");

            shipment.TruckType = dto.VehicleType;
            shipment.FinalCost = dto.FinalCost;
            shipment.AssignedDriverId = dto.DriverId;
            shipment.ShipmentId = _shipmentService.GenerateShipmentId();
            shipment.Status = ShipmentStatus.Scheduled;

            await _context.SaveChangesAsync();

            await _context.Entry(shipment)
                .Reference(s => s.AssignedDriver)
                .LoadAsync();
            if (shipment.AssignedDriver != null)
                await _context.Entry(shipment.AssignedDriver).Reference(d => d.User).LoadAsync();

            return Ok(MapToResponse(shipment));
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<DashboardDto>> GetDashboard()
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized("Trader account required.");

            var shipments = await _context.ShipmentRequests
                .Include(s => s.AssignedDriver)
                .ThenInclude(d => d!.User)
                .Where(s => s.TraderId == traderId)
                .OrderByDescending(s => s.CreatedAt)
                .ToListAsync();

            var currentShipment = shipments
                .FirstOrDefault(s => s.Status == ShipmentStatus.Scheduled || s.Status == ShipmentStatus.InProgress || s.Status == ShipmentStatus.Accepted);

            var completed = shipments.Where(s => s.Status == ShipmentStatus.Completed).ToList();
            var avgCost = completed.Any() ? completed.Average(s => s.FinalCost ?? 0) : 0;
            var avgTime = 4.2;

            var recent = shipments.Take(5).Select(MapToResponse).ToList();

            return Ok(new DashboardDto
            {
                CurrentShipment = currentShipment != null ? MapToResponse(currentShipment) : null,
                AvgTimeHours = avgTime,
                AvgCost = avgCost,
                CompletedCount = completed.Count,
                RecentActivity = recent
            });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ShipmentResponseDto>> GetShipment(int id)
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized("Trader account required.");

            var shipment = await _context.ShipmentRequests
                .Include(s => s.AssignedDriver)
                .ThenInclude(d => d!.User)
                .FirstOrDefaultAsync(s => s.Id == id && s.TraderId == traderId);

            if (shipment == null)
                return NotFound();

            return Ok(MapToResponse(shipment));
        }

        [HttpGet]
        public async Task<ActionResult<List<ShipmentResponseDto>>> GetShipments()
        {
            var traderId = await GetTraderIdFromClaims();
            if (traderId == null)
                return Unauthorized("Trader account required.");

            var shipments = await _context.ShipmentRequests
                .Include(s => s.AssignedDriver)
                .ThenInclude(d => d!.User)
                .Where(s => s.TraderId == traderId)
                .OrderByDescending(s => s.CreatedAt)
                .ToListAsync();

            return Ok(shipments.Select(MapToResponse).ToList());
        }

        private async Task<int?> GetTraderIdFromClaims()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
                return null;

            var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
            return trader?.Id;
        }

        private static ShipmentResponseDto MapToResponse(ShipmentRequest s)
        {
            return new ShipmentResponseDto
            {
                Id = s.Id,
                ShipmentId = s.ShipmentId,
                PickupLocation = s.OriginCity,
                DropOffLocation = s.DestinationCity,
                ScheduledDate = s.ScheduledDate,
                ScheduledTime = s.ScheduledTime,
                PackageCount = s.PackageCount,
                Weight = s.Weight,
                VehicleType = s.TruckType,
                FinalCost = s.FinalCost,
                Status = s.Status,
                DriverName = s.AssignedDriver?.User?.FullName,
                CreatedAt = s.CreatedAt
            };
        }
    }
}
