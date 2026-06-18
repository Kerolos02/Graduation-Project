using TruckMate.Core.Enums;

namespace TruckMate.Core.Models
{
    public class People
    {
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string NationalId { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        public UserRole Role { get; set; }
        public string? Otp { get; set; }
        public DateTime? OtpExpiry { get; set; }
        public string? Password { get; set; }

        /// <summary>Incremented to invalidate previously issued JWT access tokens.</summary>
        public int TokenVersion { get; set; }

        public bool EmailVerified { get; set; } = true;
        public bool PhoneVerified { get; set; } = true;

        public DateTime? LastPasswordChangedAtUtc { get; set; }

        /// <summary>Account scheduled for hard deletion (driver mobile advanced settings).</summary>
        public bool IsDeleted { get; set; }

        public DateTime? DeleteRequestedAtUtc { get; set; }

        /// <summary>When the account will be permanently removed if not cancelled.</summary>
        public DateTime? ScheduledHardDeleteAtUtc { get; set; }
    }
}