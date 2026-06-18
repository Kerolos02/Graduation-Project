namespace TruckMate.Services.Notifications;

public interface ISmsService
{
    Task SendPhoneOtpAsync(string phoneNumberE164, string otp, CancellationToken cancellationToken);
}
