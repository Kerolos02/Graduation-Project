namespace TruckMate.Services.TraderMobile;

public class CancellationFeeService : ICancellationFeeService
{
    public Task<decimal> CalculateFeeAsync(Guid shipmentId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return Task.FromResult(25m);
    }
}
