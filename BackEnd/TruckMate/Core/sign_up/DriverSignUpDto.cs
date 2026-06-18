using System.ComponentModel.DataAnnotations;

public class DriverSignUpDto
{
    // Step 1 – Personal Information
    [Required(ErrorMessage = "Full name is required.")]
    [StringLength(100)]
    public string FullName { get; set; }

    [Required(ErrorMessage = "Phone number is required.")]
    [Phone]
    [StringLength(20)]
    public string Phone { get; set; }

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; }

    [Required(ErrorMessage = "National ID is required.")]
    [RegularExpression(@"^\d{14}$", ErrorMessage = "National ID must be 14 digits.")]
    public string NationalId { get; set; }

    // Step 2 – License Details
    [Required(ErrorMessage = "License number is required.")]
    [StringLength(50)]
    public string LicenseNumber { get; set; }

    [Required(ErrorMessage = "License type is required.")]
    [StringLength(20)]
    public string LicenseType { get; set; }

    public string LicenseImageBase64 { get; set; }

    // Step 3 – Vehicle Information
    [Required(ErrorMessage = "Plate number is required.")]
    [StringLength(20)]
    public string PlateNumber { get; set; }

    [Required(ErrorMessage = "Truck type is required.")]
    [StringLength(50)]
    public string TruckType { get; set; }

    [Required(ErrorMessage = "Capacity is required.")]
    public double Capacity { get; set; }

    // Password
    [Required]
    [StringLength(100, MinimumLength = 8)]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$",
        ErrorMessage = "Password must contain uppercase, lowercase and number.")]
    public string Password { get; set; }

    [Required]
    [Compare("Password", ErrorMessage = "Passwords do not match.")]
    public string ConfirmPassword { get; set; }

    // OTP
    [Required]
    [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP must be 6 digits.")]
    public string OTPVerificationCode { get; set; }
}