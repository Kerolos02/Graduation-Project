namespace TruckMate.API.Services;

public interface IEmailService
{
    Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default);

    Task SendVerificationEmailAsync(string to, string otpOrLink, CancellationToken cancellationToken);

    /// <summary>Sends a contact verification message (alias for advanced settings flows).</summary>
    Task SendEmailVerificationAsync(string to, string otpOrToken, CancellationToken cancellationToken);

    Task SendPasswordChangedEmailAsync(string to, CancellationToken cancellationToken);

    Task SendAccountDeletionConfirmationAsync(string to, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken);

    Task SendAccountDeletionCancelledEmailAsync(string to, CancellationToken cancellationToken);

    Task SendDataExportReadyEmailAsync(string to, CancellationToken cancellationToken);
}
