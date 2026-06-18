using System.ComponentModel.DataAnnotations;

public class TraderSignUpDto
{
    // Step 1 – Personal Information
    [Required]
    [StringLength(100)]
    public string FullName { get; set; }

    [Required]
    [Phone]
    [StringLength(20)]
    public string Phone { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; }

    [Required]
    [RegularExpression(@"^\d{14}$")]
    public string NationalId { get; set; }

    // Step 2 – Business Details
    [Required]
    [StringLength(100)]
    public string BusinessName { get; set; }

    [StringLength(200)]
    public string Address { get; set; }

    // Password
    [Required]
    [StringLength(100, MinimumLength = 8)]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$")]
    public string Password { get; set; }

    [Required]
    [Compare("Password")]
    public string ConfirmPassword { get; set; }

    // OTP
    [Required]
    [RegularExpression(@"^\d{6}$")]
    public string OTPVerificationCode { get; set; }
}