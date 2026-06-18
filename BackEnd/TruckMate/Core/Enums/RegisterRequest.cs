using TruckMate.Core.Enums;

public class RegisterRequest
{
    public UserRole Role { get; set; }

    // الـ Token اللي اتبعت من /register/send-otp
    public string OtpToken { get; set; } = string.Empty;

    // الكود اللي وصله على الإيميل (يقبل أيضاً الحقل "otp" من الموبايل)
    public string OtpCode { get; set; } = string.Empty;

    public string Otp { get; set; } = string.Empty;

    // الـ Token اللي بيرجع من /register/verify-otp بعد التحقق
    public string VerificationToken { get; set; } = string.Empty;

    // بيانات الـ Driver (لو Role == Driver)
    public DriverSignUpDto? Driver { get; set; }

    // بيانات الـ Trader (لو Role == Trader)
    public TraderSignUpDto? Trader { get; set; }

    public string ResolvedOtpCode
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(OtpCode)) return OtpCode.Trim();
            if (!string.IsNullOrWhiteSpace(Otp)) return Otp.Trim();
            if (!string.IsNullOrWhiteSpace(Driver?.OTPVerificationCode))
                return Driver.OTPVerificationCode.Trim();
            if (!string.IsNullOrWhiteSpace(Trader?.OTPVerificationCode))
                return Trader.OTPVerificationCode.Trim();
            return string.Empty;
        }
    }
}