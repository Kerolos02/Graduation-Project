namespace TruckMate.Services.DriverHome;

public interface ITripDispatchService
{
    Task DispatchTripToDriverAsync(Guid tripId, CancellationToken cancellationToken);
    Task ReDispatchTripAsync(Guid tripId, int excludeDriverId, CancellationToken cancellationToken);
    Task CancelAllOffersForTripAsync(Guid tripId, string reason, CancellationToken cancellationToken);
    Task AssignDriverToShipmentAsync(Guid tripId, Guid driverPublicId, CancellationToken cancellationToken);
}
