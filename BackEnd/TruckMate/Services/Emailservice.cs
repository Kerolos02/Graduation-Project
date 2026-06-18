using MailKit.Security;
using Microsoft.Extensions.Logging;
using MimeKit;

namespace TruckMate.API.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body,
        CancellationToken cancellationToken = default)
    {
        var senderEmail = _config["Email:SenderAddress"]
                          ?? throw new InvalidOperationException("Email:SenderAddress not configured.");
        var appPassword = _config["Email:AppPassword"]
                          ?? throw new InvalidOperationException("Email:AppPassword not configured.");

        var email = new MimeMessage();
        email.From.Add(MailboxAddress.Parse(senderEmail));
        email.To.Add(MailboxAddress.Parse(to));
        email.Subject = subject;
        email.Body = new TextPart("plain") { Text = body };

        using var smtp = new MailKit.Net.Smtp.SmtpClient();
        await smtp.ConnectAsync("smtp.gmail.com", 587, SecureSocketOptions.StartTls, cancellationToken)
            .ConfigureAwait(false);
        await smtp.AuthenticateAsync(senderEmail, appPassword, cancellationToken).ConfigureAwait(false);
        await smtp.SendAsync(email, cancellationToken).ConfigureAwait(false);
        await smtp.DisconnectAsync(true, cancellationToken).ConfigureAwait(false);
    }

    public Task SendVerificationEmailAsync(string to, string otpOrLink, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Queued verification placeholder email to {To}", to);
        return SendAsync(to, "Verify your TruckMate contact",
            $"Please verify your contact using this code/link (placeholder):\n{otpOrLink}", cancellationToken);
    }

    public Task SendEmailVerificationAsync(string to, string otpOrToken, CancellationToken cancellationToken) =>
        SendVerificationEmailAsync(to, otpOrToken, cancellationToken);

    public Task SendPasswordChangedEmailAsync(string to, CancellationToken cancellationToken) =>
        SendAsync(to, "Your TruckMate password was changed",
            "Your account password was updated successfully. If this was not you, reset your password immediately.",
            cancellationToken);

    public Task SendAccountDeletionConfirmationAsync(string to, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken)
    {
        var when = scheduledHardDeleteUtc.ToString("u");
        return SendAsync(to, "Your TruckMate account deletion has been scheduled",
            $"Your account will be permanently removed after {when} UTC unless you cancel from the app.",
            cancellationToken);
    }

    public Task SendAccountDeletionCancelledEmailAsync(string to, CancellationToken cancellationToken) =>
        SendAsync(to, "Your TruckMate account deletion has been cancelled",
            "Your scheduled account deletion was cancelled. Your account remains active.", cancellationToken);

    public Task SendDataExportReadyEmailAsync(string to, CancellationToken cancellationToken) =>
        SendAsync(to, "Your TruckMate data export",
            "Your GDPR data export ZIP is ready (placeholder). Attachments would be included in production.",
            cancellationToken);
}
