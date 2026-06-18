namespace TruckMate.Core.Models;

public class Trader
{
    public int Id { get; set; }

    public Guid PublicId { get; set; }

    /// <summary>Separate from People.TokenVersion — used in Trader JWT validation.</summary>
    public int TokenVersion { get; set; }

    public string BusinessName { get; set; } = string.Empty;

    /// <summary>Business phone shown on driver request details; falls back to <see cref="People.Phone"/> when empty.</summary>
    public string? PhoneNumber { get; set; }

    public string Address { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; }

    public int UserId { get; set; }
    public People User { get; set; } = null!;

    public bool IsDeleted { get; set; }
    public DateTime? DeleteRequestedAtUtc { get; set; }
    public DateTime? ScheduledHardDeleteAtUtc { get; set; }

    /// <summary>BCrypt hash of emailed verification OTP for pending email change verification.</summary>
    public string? EmailVerificationOtpHash { get; set; }

    public DateTime? EmailVerificationOtpExpiresUtc { get; set; }

    public string? PhoneVerificationOtpHash { get; set; }
    public DateTime? PhoneVerificationOtpExpiresUtc { get; set; }

    public ICollection<ShipmentRequest> Shipments { get; set; } = new List<ShipmentRequest>();
}