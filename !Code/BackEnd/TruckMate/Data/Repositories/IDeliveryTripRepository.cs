using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDeliveryTripRepository : IRepository<DeliveryTrip>
{
    Task<int> GetNextShipmentNumericAsync(CancellationToken cancellationToken);
    Task<DeliveryTrip?> GetByIdWithShipmentAsync(Guid id, CancellationToken cancellationToken);

    Task<DeliveryTrip?> GetByIdWithShipmentTrackedAsync(Guid id, CancellationToken cancellationToken);

    Task<DeliveryTrip?> GetActiveCourierTripForDriverAsync(int driverDbId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<DeliveryTrip>> GetIncomingPendingForZoneAsync(string zone,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<DeliveryTrip>> GetRecentCompletedAsync(int driverDbId,
        int skip, int take, CancellationToken cancellationToken);

    Task<int> CountRecentCompletedAsync(int driverDbId, CancellationToken cancellationToken);
    Task<DeliveryTrip?> GetByIdForTraderAsync(Guid tripId, Guid traderPublicId, CancellationToken cancellationToken);

    Task<(IReadOnlyList<(DeliveryTrip Trip, string? MarketplaceRequestNumber)> Items, int TotalCount)>
        GetMyTripsPagedAsync(int driverDbId, string? status, int page, int pageSize,
            CancellationToken cancellationToken);
}
