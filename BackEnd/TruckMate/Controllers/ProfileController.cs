using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProfileController : ControllerBase
    {
        private readonly TruckMateDbContext _context;

        public ProfileController(TruckMateDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET api/profile
        // يرجع بيانات الـ User حسب الـ Role بتاعته
        // ============================================================
        [HttpGet]
        public async Task<IActionResult> GetProfile()
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "User not found." });

            // بيانات مشتركة
            var baseProfile = new
            {
                user.Id,
                user.FullName,
                user.Email,
                user.Phone,
                user.NationalId,
                role = user.Role.ToString()
            };

            // لو Trader - رجع بيانات الـ Business كمان
            if (user.Role == UserRole.Trader)
            {
                var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
                return Ok(new
                {
                    baseProfile.Id,
                    baseProfile.FullName,
                    baseProfile.Email,
                    baseProfile.Phone,
                    baseProfile.NationalId,
                    baseProfile.role,
                    trader?.BusinessName,
                    trader?.Address
                });
            }

            // لو Driver - رجع بيانات الـ License والـ Truck كمان
            if (user.Role == UserRole.Driver)
            {
                var driver = await _context.Drivers.FirstOrDefaultAsync(d => d.UserId == userId);
                return Ok(new
                {
                    baseProfile.Id,
                    baseProfile.FullName,
                    baseProfile.Email,
                    baseProfile.Phone,
                    baseProfile.NationalId,
                    baseProfile.role,
                    driver?.LicenseNumber,
                    driver?.LicenseType,
                    driver?.PlateNumber,
                    driver?.TruckType,
                    driver?.Capacity
                });
            }

            // Admin
            return Ok(baseProfile);
        }

        // ============================================================
        // PUT api/profile
        // تعديل البيانات الشخصية (مشترك بين كل الـ Roles)
        // ============================================================
        [HttpPut]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto dto)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "User not found." });

            // تحقق إن الـ Email مش بيستخدمه حد تاني
            if (!string.IsNullOrWhiteSpace(dto.Email) && dto.Email != user.Email)
            {
                var emailTaken = await _context.Users
                    .AnyAsync(u => u.Email == dto.Email && u.Id != userId);
                if (emailTaken)
                    return BadRequest(new { message = "Email already in use." });
                user.Email = dto.Email;
            }

            // تحقق إن الـ Phone مش بيستخدمه حد تاني
            if (!string.IsNullOrWhiteSpace(dto.Phone) && dto.Phone != user.Phone)
            {
                var phoneTaken = await _context.Users
                    .AnyAsync(u => u.Phone == dto.Phone && u.Id != userId);
                if (phoneTaken)
                    return BadRequest(new { message = "Phone already in use." });
                user.Phone = dto.Phone;
            }

            if (!string.IsNullOrWhiteSpace(dto.FullName))
                user.FullName = dto.FullName;

            // لو Trader - عدّل بيانات الـ Business
            if (user.Role == UserRole.Trader && dto.TraderDetails != null)
            {
                var trader = await _context.Traders.FirstOrDefaultAsync(t => t.UserId == userId);
                if (trader != null)
                {
                    if (!string.IsNullOrWhiteSpace(dto.TraderDetails.BusinessName))
                        trader.BusinessName = dto.TraderDetails.BusinessName;
                    if (!string.IsNullOrWhiteSpace(dto.TraderDetails.Address))
                        trader.Address = dto.TraderDetails.Address;
                }
            }

            // لو Driver - عدّل بيانات اللايسنس
            if (user.Role == UserRole.Driver && dto.DriverDetails != null)
            {
                var driver = await _context.Drivers.FirstOrDefaultAsync(d => d.UserId == userId);
                if (driver != null)
                {
                    if (!string.IsNullOrWhiteSpace(dto.DriverDetails.LicenseNumber))
                        driver.LicenseNumber = dto.DriverDetails.LicenseNumber;
                    if (!string.IsNullOrWhiteSpace(dto.DriverDetails.LicenseType))
                        driver.LicenseType = dto.DriverDetails.LicenseType;
                    if (!string.IsNullOrWhiteSpace(dto.DriverDetails.PlateNumber))
                        driver.PlateNumber = dto.DriverDetails.PlateNumber;
                    if (!string.IsNullOrWhiteSpace(dto.DriverDetails.TruckType))
                        driver.TruckType = dto.DriverDetails.TruckType;
                    if (dto.DriverDetails.Capacity.HasValue)
                        driver.Capacity = dto.DriverDetails.Capacity.Value;
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Profile updated successfully." });
        }

        // ============================================================
        // PUT api/profile/change-password
        // تغيير الباسورد بعد التحقق من الـ Old Password
        // ============================================================
        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
        {
            var userId = GetUserId();
            if (userId == null) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "User not found." });

            // تحقق من الـ Password القديم
            if (!BCrypt.Net.BCrypt.Verify(dto.OldPassword, user.PasswordHash))
                return BadRequest(new { success = false, message = "Old password is incorrect." });


            // تحقق من قوة الـ Password الجديد
            if (!IsStrongPassword(dto.NewPassword))
                return BadRequest(new
                {
                    success = false,
                    message = "Password must be at least 8 characters, include uppercase, digit, and special character."
                });

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Password changed successfully." });
        }

        // ============================================================
        // Helpers
        // ============================================================
        private int? GetUserId()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(claim, out var id) ? id : null;
        }

        private static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(password);
            return Convert.ToBase64String(sha256.ComputeHash(bytes));
        }

        private static bool IsStrongPassword(string password)
        {
            if (password.Length < 8) return false;
            if (!password.Any(char.IsUpper)) return false;
            if (!password.Any(char.IsDigit)) return false;
            if (!password.Any(c => "!@#$%^&*()_+-=[]{}|;':\",./<>?".Contains(c))) return false;
            return true;
        }
    }

    // ============================================================
    // DTOs
    // ============================================================
    public class UpdateProfileDto
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }

        // بيانات إضافية حسب الـ Role
        public TraderUpdateDto? TraderDetails { get; set; }
        public DriverUpdateDto? DriverDetails { get; set; }
    }

    public class TraderUpdateDto
    {
        public string? BusinessName { get; set; }
        public string? Address { get; set; }
    }

    public class DriverUpdateDto
    {
        public string? LicenseNumber { get; set; }
        public string? LicenseType { get; set; }
        public string? PlateNumber { get; set; }
        public string? TruckType { get; set; }
        public double? Capacity { get; set; }
    }

    public class ChangePasswordDto
    {
        public string OldPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}