using Microsoft.Extensions.Options;
using TruckMate.Core.Enums;
using TruckMate.Core.TraderMobile;

namespace TruckMate.Services.TraderMobile;

public class PricingService : IPricingService
{
    private readonly PricingConfig _config;

    public PricingService(IOptions<PricingConfig> config)
    {
        _config = config.Value;
    }

    public Task<decimal> CalculateTripPriceAsync(decimal distanceKm, decimal weightLbs, VehicleType vehicleType,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var weightKg = weightLbs * 0.45359237m;
        var tripPrice = (_config.BaseFare + (distanceKm * _config.PerKmRate) + (weightKg * _config.PerKgRate)) *
                        ResolveMultiplier(vehicleType);
        var serviceFee = tripPrice * 0.08m;
        var tax = tripPrice * 0.08m;
        var total = tripPrice + serviceFee + tax;
        return Task.FromResult(decimal.Round(total, 2));
    }

    private decimal ResolveMultiplier(VehicleType vehicleType) =>
        vehicleType switch
        {
            VehicleType.Van => _config.VanMultiplier,
            VehicleType.PickupTruck => _config.PickupTruckMultiplier,
            VehicleType.BoxTruck => _config.BoxTruckMultiplier,
            VehicleType.Truck => _config.TruckMultiplier,
            _ => 1m
        };
}
