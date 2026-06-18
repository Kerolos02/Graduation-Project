namespace TruckMate.Services.TraderMobile;

public interface IPaymentGatewayService
{
    Task<string> TokenizeCardAsync(string cardNumber, int expiryMonth, int expiryYear, string cvv,
        CancellationToken cancellationToken);
    Task ChargeAsync(string tokenizedCardId, decimal amountEGP, CancellationToken cancellationToken);
    Task DeleteTokenAsync(string tokenizedCardId, CancellationToken cancellationToken);
}
