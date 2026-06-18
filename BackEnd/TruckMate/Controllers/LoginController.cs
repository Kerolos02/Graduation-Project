using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using TruckMate.Core.Auth;
using TruckMate.Core.Enums;
using TruckMate.Core.Log_In;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.API.Controllers
{
    [ApiController]
    [Route("login")]
    public class LoginController : ControllerBase
    {
        private readonly TruckMateDbContext _context;
        private readonly IConfiguration _configuration;

        public LoginController(TruckMateDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [HttpPost]
        public async Task<IActionResult> Login([FromBody] LoginDto request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { success = false, message = "Email and password are required." });

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email.Trim().ToLower());

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Unauthorized(new { success = false, message = "Invalid credentials." });

            if (!user.EmailVerified)
                return Unauthorized(new { success = false, message = "Please verify your email before signing in." });

            if (user.IsDeleted && user.ScheduledHardDeleteAtUtc.HasValue &&
                user.ScheduledHardDeleteAtUtc.Value <= DateTime.UtcNow)
            {
                return Unauthorized(new { success = false, message = "This account has been removed." });
            }

            var token = await GenerateJwtTokenAsync(user).ConfigureAwait(false);

            return Ok(new LoginResponseDto
            {
                Token = token,
                UserId = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role
            });
        }

        private async Task<string> GenerateJwtTokenAsync(People user)
        {
            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]
                    ?? throw new InvalidOperationException("Jwt:Key is not configured.")));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claimList = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, user.FullName),
                new(ClaimTypes.Role, user.Role.ToString())
            };

            if (user.Role == UserRole.Trader)
            {
                var trader = await _context.Traders.AsNoTracking()
                    .FirstOrDefaultAsync(t => t.UserId == user.Id).ConfigureAwait(false);
                if (trader != null)
                {
                    claimList.Add(new Claim(JwtCustomClaims.TraderPublicId, trader.PublicId.ToString()));
                    claimList.Add(new Claim(JwtCustomClaims.TokenVersion, trader.TokenVersion.ToString()));
                }
                else
                {
                    claimList.Add(new Claim(JwtCustomClaims.TokenVersion, "0"));
                }
            }
            else
            {
                claimList.Add(new Claim(JwtCustomClaims.TokenVersion, user.TokenVersion.ToString()));
            }

            if (user.Role == UserRole.Driver)
            {
                var driver = await _context.Drivers.AsNoTracking()
                    .FirstOrDefaultAsync(d => d.UserId == user.Id).ConfigureAwait(false);
                if (driver != null)
                {
                    claimList.Add(new Claim(JwtCustomClaims.DriverPublicId, driver.PublicId.ToString()));
                }
            }

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claimList,
                expires: DateTime.UtcNow.AddHours(24),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
