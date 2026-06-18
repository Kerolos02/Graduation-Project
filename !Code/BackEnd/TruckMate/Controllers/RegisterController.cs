using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using TruckMate.API.Services;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("register")]
    public class RegisterController : ControllerBase
    {
        private const string RegistrationOtpCachePrefix = "registration_otp:";
        private const string RegistrationVerifiedPurpose = "RegistrationVerified";

        private readonly TruckMateDbContext _context;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly IMemoryCache _cache;

        public RegisterController(
            TruckMateDbContext context,
            IConfiguration config,
            IEmailService emailService,
            IMemoryCache cache)
        {
            _context = context;
            _config = config;
            _emailService = emailService;
            _cache = cache;
        }

        // ============================================================
        // POST /register/send-otp
        // الخطوة الأولى: إرسال OTP على الإيميل قبل التسجيل
        // ============================================================
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto dto)
        {
            // تحقق إن الإيميل مش مسجل قبل كده
            var emailExists = await _context.Users.AnyAsync(u => u.Email == dto.Email.Trim().ToLower());
            if (emailExists)
                return BadRequest(new { success = false, message = "Email already registered." });

            // توليد OTP من 6 أرقام
            var otp = new Random().Next(100000, 999999).ToString();

            // حفظه مؤقتاً في People بدون تفعيل - أو استخدم cache/session
            // هنا بنحفظه في جدول مؤقت في نفس الـ Users table عن طريق record مؤقت
            // الأبسط: نبعت الـ OTP ونخليه يبعته في الـ Register request نفسه بعدين نتحقق منه

            // بما إن الـ Model بيسمح بـ Otp و OtpExpiry في People،
            // هنعمل record مؤقت أو نخزنه في memory cache
            // الحل الأسهل هنا: نرد بـ token يحمل الـ OTP encrypted

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim("Email", dto.Email.Trim().ToLower()),
                    new Claim("Otp", otp)
                }),
                Expires = DateTime.UtcNow.AddMinutes(10),
                Issuer = _config["Jwt:Issuer"],
                Audience = _config["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var otpToken = tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
            var normalizedEmail = dto.Email.Trim().ToLower();
            StoreRegistrationOtp(normalizedEmail, otp);

            await _emailService.SendAsync(
                dto.Email,
                "رمز التحقق - TruckMate",
                $"رمز التحقق الخاص بك هو: {otp}\n\nهذا الرمز صالح لمدة 10 دقائق فقط."
            );

            return Ok(new
            {
                success = true,
                message = "OTP sent to your email.",
                otpToken  // الـ Frontend يبعته مع الـ Register request
            });
        }

        // ============================================================
        // POST /register/verify-otp
        // التحقق من OTP قبل إكمال التسجيل (شاشة Verify في الموبايل)
        // ============================================================
        [HttpPost("verify-otp")]
        public IActionResult VerifyRegistrationOtp([FromBody] VerifyRegistrationOtpDto dto)
        {
            var email = dto.Email.Trim().ToLower();
            var otpCode = !string.IsNullOrWhiteSpace(dto.OtpCode) ? dto.OtpCode.Trim() : dto.Otp.Trim();

            if (string.IsNullOrWhiteSpace(otpCode))
                return BadRequest(new { success = false, message = "OTP code is required." });

            string verifiedEmail;
            try
            {
                verifiedEmail = !string.IsNullOrWhiteSpace(dto.OtpToken)
                    ? ValidateOtpToken(dto.OtpToken, otpCode)
                    : ValidateOtpFromCache(email, otpCode);
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }

            ClearRegistrationOtp(verifiedEmail);
            var verificationToken = CreateVerificationToken(verifiedEmail);

            return Ok(new
            {
                success = true,
                message = "OTP verified successfully.",
                verificationToken
            });
        }

        // ============================================================
        // POST /register
        // التسجيل الكامل بعد التحقق من الـ OTP
        // ============================================================
        [HttpPost]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            string verifiedEmail;
            try
            {
                verifiedEmail = ResolveVerifiedEmail(request);
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }

            // ---- التسجيل حسب الـ Role ----
            if (request.Role == UserRole.Driver)
            {
                var dto = request.Driver;
                if (dto == null)
                    return BadRequest(new { success = false, message = "Driver data is required." });

                // تأكد إن الإيميل في الـ Token هو نفسه في الـ DTO
                if (dto.Email.Trim().ToLower() != verifiedEmail)
                    return BadRequest(new { success = false, message = "Email does not match verified OTP." });

                // Uniqueness checks
                if (await _context.Users.AnyAsync(u => u.Email == dto.Email.Trim().ToLower()))
                    return BadRequest(new { success = false, message = "Email already registered." });

                if (await _context.Users.AnyAsync(u => u.Phone == dto.Phone))
                    return BadRequest(new { success = false, message = "Phone number already registered." });

                if (await _context.Users.AnyAsync(u => u.NationalId == dto.NationalId))
                    return BadRequest(new { success = false, message = "National ID already registered." });

                if (await _context.Drivers.AnyAsync(d => d.PlateNumber == dto.PlateNumber))
                    return BadRequest(new { success = false, message = "Plate number already registered." });

                if (await _context.Drivers.AnyAsync(d => d.LicenseNumber == dto.LicenseNumber))
                    return BadRequest(new { success = false, message = "License number already registered." });

                // حفظ الـ User
                var user = new People
                {
                    FullName = dto.FullName.Trim(),
                    Phone = dto.Phone.Trim(),
                    Email = dto.Email.Trim().ToLower(),
                    NationalId = dto.NationalId.Trim(),
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    Role = UserRole.Driver
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var driver = new Driver
                {
                    UserId = user.Id,
                    LicenseNumber = dto.LicenseNumber.Trim(),
                    LicenseType = dto.LicenseType.Trim(),
                    PlateNumber = dto.PlateNumber.Trim(),
                    TruckType = dto.TruckType.Trim(),
                    Capacity = dto.Capacity
                };
                _context.Drivers.Add(driver);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Driver registered successfully." });
            }

            if (request.Role == UserRole.Trader)
            {
                var dto = request.Trader;
                if (dto == null)
                    return BadRequest(new { success = false, message = "Trader data is required." });

                if (dto.Email.Trim().ToLower() != verifiedEmail)
                    return BadRequest(new { success = false, message = "Email does not match verified OTP." });

                if (await _context.Users.AnyAsync(u => u.Email == dto.Email.Trim().ToLower()))
                    return BadRequest(new { success = false, message = "Email already registered." });

                if (await _context.Users.AnyAsync(u => u.Phone == dto.Phone))
                    return BadRequest(new { success = false, message = "Phone number already registered." });

                if (await _context.Users.AnyAsync(u => u.NationalId == dto.NationalId))
                    return BadRequest(new { success = false, message = "National ID already registered." });

                var user = new People
                {
                    FullName = dto.FullName.Trim(),
                    Phone = dto.Phone.Trim(),
                    Email = dto.Email.Trim().ToLower(),
                    NationalId = dto.NationalId.Trim(),
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    Role = UserRole.Trader
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var trader = new Trader
                {
                    UserId = user.Id,
                    PublicId = Guid.NewGuid(),
                    TokenVersion = 0,
                    CreatedAtUtc = DateTime.UtcNow,
                    BusinessName = dto.BusinessName.Trim(),
                    Address = dto.Address?.Trim() ?? string.Empty
                };
                _context.Traders.Add(trader);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Trader registered successfully." });
            }

            return BadRequest(new { success = false, message = "Invalid role." });
        }

        // ============================================================
        // POST /register/forgot-password
        // إرسال OTP لإعادة تعيين الباسورد (للـ User المسجل)
        // ============================================================
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] SendOtpRequestDto dto)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == dto.Email.Trim().ToLower());

            // مش بنقول إن الإيميل مش موجود (security best practice)
            if (user == null)
                return Ok(new { success = true, message = "If this email exists, an OTP has been sent." });

            var otp = new Random().Next(100000, 999999).ToString();

            user.Otp = otp;
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(10);
            await _context.SaveChangesAsync();

            await _emailService.SendAsync(
                dto.Email,
                "إعادة تعيين كلمة المرور - TruckMate",
                $"رمز التحقق الخاص بك هو: {otp}\n\nهذا الرمز صالح لمدة 10 دقائق فقط."
            );

            return Ok(new { success = true, message = "If this email exists, an OTP has been sent." });
        }

        // ============================================================
        // POST /register/verify-reset-otp
        // التحقق من الـ OTP وإرجاع reset token
        // ============================================================
        [HttpPost("verify-reset-otp")]
        public async Task<IActionResult> VerifyResetOtp([FromBody] VerifyOtpDto dto)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == dto.Email.Trim().ToLower());

            if (user == null)
                return BadRequest(new { success = false, message = "Invalid OTP." });

            if (user.Otp != dto.Otp)
                return BadRequest(new { success = false, message = "Invalid verification code." });

            if (user.OtpExpiry == null || user.OtpExpiry < DateTime.UtcNow)
                return BadRequest(new { success = false, message = "OTP expired." });

            // امسح الـ OTP بعد ما اتتحقق منه
            user.Otp = null;
            user.OtpExpiry = null;
            await _context.SaveChangesAsync();

            // ارجع reset token صالح 15 دقيقة
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim("UserId", user.Id.ToString()),
                    new Claim("Purpose", "PasswordReset")
                }),
                Expires = DateTime.UtcNow.AddMinutes(15),
                Issuer = _config["Jwt:Issuer"],
                Audience = _config["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var resetToken = tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));

            return Ok(new
            {
                success = true,
                message = "OTP verified successfully.",
                resetToken
            });
        }

        // ============================================================
        // POST /register/reset-password
        // تعيين الباسورد الجديد باستخدام الـ reset token
        // ============================================================
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            int userId;
            try
            {
                userId = ValidateResetToken(dto.ResetToken);
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return BadRequest(new { success = false, message = "User not found." });

            if (!IsStrongPassword(dto.NewPassword))
                return BadRequest(new
                {
                    success = false,
                    message = "Password must be at least 8 characters, include uppercase, digit, and special character."
                });

            // حفظ الباسورد الجديد بـ BCrypt
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Password reset successfully." });
        }

        // ============================================================
        // Private Helpers
        // ============================================================

        private string ResolveVerifiedEmail(RegisterRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.VerificationToken))
                return ValidateVerificationToken(request.VerificationToken);

            var otpCode = request.ResolvedOtpCode;

            if (!string.IsNullOrWhiteSpace(request.OtpToken))
            {
                if (string.IsNullOrWhiteSpace(otpCode))
                    throw new Exception("OTP code is required.");

                return ValidateOtpToken(request.OtpToken, otpCode);
            }

            var email = GetRegistrationEmail(request);
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(otpCode))
                throw new Exception("OTP verification required.");

            var verifiedEmail = ValidateOtpFromCache(email, otpCode);
            ClearRegistrationOtp(verifiedEmail);
            return verifiedEmail;
        }

        private static string? GetRegistrationEmail(RegisterRequest request) =>
            request.Role switch
            {
                UserRole.Driver => request.Driver?.Email?.Trim().ToLower(),
                UserRole.Trader => request.Trader?.Email?.Trim().ToLower(),
                _ => null
            };

        private static string RegistrationOtpCacheKey(string email) =>
            RegistrationOtpCachePrefix + email.Trim().ToLower();

        private void StoreRegistrationOtp(string email, string otp)
        {
            _cache.Set(
                RegistrationOtpCacheKey(email),
                new CachedRegistrationOtp
                {
                    Otp = otp,
                    ExpiresAtUtc = DateTime.UtcNow.AddMinutes(10)
                },
                TimeSpan.FromMinutes(10));
        }

        private void ClearRegistrationOtp(string email) =>
            _cache.Remove(RegistrationOtpCacheKey(email));

        private string ValidateOtpFromCache(string email, string otpCode)
        {
            email = email.Trim().ToLower();
            otpCode = otpCode.Trim();

            if (!_cache.TryGetValue(RegistrationOtpCacheKey(email), out CachedRegistrationOtp? cached) ||
                cached == null)
            {
                throw new Exception("OTP expired or not found. Please request a new code.");
            }

            if (cached.ExpiresAtUtc < DateTime.UtcNow)
                throw new Exception("OTP expired.");

            if (cached.Otp != otpCode)
                throw new Exception("Invalid verification code.");

            return email;
        }

        private string CreateVerificationToken(string email)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim("Email", email.Trim().ToLower()),
                    new Claim("Purpose", RegistrationVerifiedPurpose)
                }),
                Expires = DateTime.UtcNow.AddMinutes(15),
                Issuer = _config["Jwt:Issuer"],
                Audience = _config["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            return tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
        }

        private string ValidateVerificationToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);

            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _config["Jwt:Issuer"],
                ValidateAudience = true,
                ValidAudience = _config["Jwt:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out _);

            var purposeClaim = principal.Claims.FirstOrDefault(c => c.Type == "Purpose")?.Value;
            if (purposeClaim != RegistrationVerifiedPurpose)
                throw new Exception("Invalid verification token.");

            var emailClaim = principal.Claims.FirstOrDefault(c =>
                c.Type == "Email" || c.Type == ClaimTypes.Email)?.Value;

            if (string.IsNullOrWhiteSpace(emailClaim))
                throw new Exception("Invalid verification token.");

            return emailClaim.Trim().ToLower();
        }

        /// <summary>
        /// التحقق من الـ OTP Token اللي بيجي مع طلب التسجيل
        /// </summary>
        private string ValidateOtpToken(string token, string otpCode)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);

            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _config["Jwt:Issuer"],
                ValidateAudience = true,
                ValidAudience = _config["Jwt:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out _);

            var emailClaim = principal.Claims.FirstOrDefault(c =>
                c.Type == "Email" || c.Type == ClaimTypes.Email)?.Value;
            var otpClaim = principal.Claims.FirstOrDefault(c => c.Type == "Otp")?.Value;

            if (emailClaim == null || otpClaim == null)
                throw new Exception("Invalid OTP token.");

            if (otpClaim != otpCode.Trim())
                throw new Exception("Invalid verification code.");

            return emailClaim.Trim().ToLower();
        }

        /// <summary>
        /// التحقق من الـ Reset Token وإرجاع الـ UserId
        /// </summary>
        private int ValidateResetToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"]!);

            var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = _config["Jwt:Issuer"],
                ValidateAudience = true,
                ValidAudience = _config["Jwt:Audience"],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out _);

            var purposeClaim = principal.Claims.FirstOrDefault(c => c.Type == "Purpose")?.Value;
            if (purposeClaim != "PasswordReset")
                throw new Exception("Invalid reset token.");

            var userIdClaim = principal.Claims.FirstOrDefault(c => c.Type == "UserId")?.Value;
            if (!int.TryParse(userIdClaim, out var userId))
                throw new Exception("Invalid reset token.");

            return userId;
        }

        private static bool IsStrongPassword(string password)
        {
            if (password.Length < 8) return false;
            if (!password.Any(char.IsUpper)) return false;
            if (!password.Any(char.IsDigit)) return false;
            if (!password.Any(c => "!@#$%^&*()_+-=[]{}|;':\",./<>?".Contains(c))) return false;
            return true;
        }

        private sealed class CachedRegistrationOtp
        {
            public string Otp { get; init; } = string.Empty;
            public DateTime ExpiresAtUtc { get; init; }
        }
    }

    // ============================================================
    // DTOs
    // ============================================================
    public class SendOtpRequestDto
    {
        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;
    }

    public class VerifyOtpDto
    {
        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Otp { get; set; } = string.Empty;
    }

    public class VerifyRegistrationOtpDto
    {
        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string Otp { get; set; } = string.Empty;

        public string OtpCode { get; set; } = string.Empty;

        public string? OtpToken { get; set; }
    }

    public class ResetPasswordDto
    {
        [Required]
        public string ResetToken { get; set; } = string.Empty;

        [Required]
        public string NewPassword { get; set; } = string.Empty;
    }
}