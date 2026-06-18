namespace TruckMate.Services.TraderMobile;

public interface ICancellationFeeService
{
    Task<decimal> CalculateFeeAsync(Guid shipmentId, CancellationToken cancellationToken);
}
