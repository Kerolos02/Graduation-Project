using TruckMate.Core.Enums;

namespace TruckMate.Services.TraderMobile;

public interface IPricingService
{
    Task<decimal> CalculateTripPriceAsync(decimal distanceKm, decimal weightLbs, VehicleType vehicleType,
        CancellationToken cancellationToken);
}
