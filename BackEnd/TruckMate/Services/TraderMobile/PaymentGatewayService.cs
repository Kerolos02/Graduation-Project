namespace TruckMate.Services.TraderMobile;

public class PaymentGatewayService : IPaymentGatewayService
{
    private readonly ILogger<PaymentGatewayService> _logger;

    public PaymentGatewayService(ILogger<PaymentGatewayService> logger)
    {
        _logger = logger;
    }

    public Task<string> TokenizeCardAsync(string cardNumber, int expiryMonth, int expiryYear, string cvv,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var token = $"tok_{Guid.NewGuid():N}";
        _logger.LogInformation("Tokenized card ending with {Last4}", cardNumber[^4..]);
        return Task.FromResult(token);
    }

    public Task ChargeAsync(string tokenizedCardId, decimal amountEGP, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _logger.LogInformation("Charged token {Token} amount {Amount}", tokenizedCardId, amountEGP);
        return Task.CompletedTask;
    }

    public Task DeleteTokenAsync(string tokenizedCardId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _logger.LogInformation("Deleted token {Token}", tokenizedCardId);
        return Task.CompletedTask;
    }
}
