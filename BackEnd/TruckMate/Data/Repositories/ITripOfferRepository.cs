using TruckMate.Core.Enums;
using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITripOfferRepository : IRepository<TripOffer>
{
    Task<TripOffer?> GetPendingByDriverIdAsync(int driverId, CancellationToken cancellationToken);
    Task<TripOffer?> GetByIdForDriverAsync(Guid offerId, int driverId, CancellationToken cancellationToken);
    Task<TripOffer?> GetByIdTrackedAsync(Guid offerId, CancellationToken cancellationToken);
    Task<IReadOnlyList<TripOffer>> GetPendingByTripIdAsync(Guid tripId, CancellationToken cancellationToken);
    Task<IReadOnlyList<TripOffer>> GetExpiredPendingsAsync(DateTime utcNow, CancellationToken cancellationToken);
    Task<bool> HasPendingOfferForDriverAsync(int driverId, CancellationToken cancellationToken);
    Task<bool> DriverDeclinedTripBeforeAsync(int driverId, Guid tripId, CancellationToken cancellationToken);
    Task MarkPendingByTripAsCancelledAsync(Guid tripId, Guid acceptedOfferId, string reason, DateTime utcNow,
        CancellationToken cancellationToken);
    Task<int> ExecuteExpirePendingAsync(Guid offerId, DateTime utcNow, CancellationToken cancellationToken);
}
