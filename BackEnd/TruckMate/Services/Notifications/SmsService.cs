using Microsoft.Extensions.Logging;

namespace TruckMate.Services.Notifications;

public class SmsService : ISmsService
{
    private readonly ILogger<SmsService> _logger;

    public SmsService(ILogger<SmsService> logger)
    {
        _logger = logger;
    }

    public Task SendPhoneOtpAsync(string phoneNumberE164, string otp, CancellationToken cancellationToken)
    {
        _logger.LogInformation("SMS OTP placeholder to {Phone}: {Otp}", phoneNumberE164, otp);
        return Task.CompletedTask;
    }
}
