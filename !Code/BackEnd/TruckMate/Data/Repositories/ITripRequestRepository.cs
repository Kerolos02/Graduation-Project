using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ITripRequestRepository
{
    Task<TripRequest?> GetByIdAsync(Guid id, CancellationToken cancellationToken);

    Task<TripRequest?> GetByIdTrackedAsync(Guid id, CancellationToken cancellationToken);

    Task<TripRequest?> GetByIdForDetailAsync(Guid id, CancellationToken cancellationToken);

    Task<(IReadOnlyList<TripRequest> Items, int TotalCount)> GetOpenForDriverAsync(int driverId, string zone,
        string? requiredTruckTypeFilter, string sortBy, int page, int pageSize,
        CancellationToken cancellationToken);

    Task<int> TryMarkAcceptedAsync(Guid tripRequestId, int driverId, DateTime acceptedAtUtc,
        CancellationToken cancellationToken);

    Task AddRejectionAsync(TripRequestRejection rejection, CancellationToken cancellationToken);

    Task<bool> HasDriverRejectedAsync(Guid tripRequestId, int driverId, CancellationToken cancellationToken);

    Task<IReadOnlyList<TripRequest>> GetExpiredOpenAsync(DateTime utcNow, CancellationToken cancellationToken);

    Task AddAsync(TripRequest entity, CancellationToken cancellationToken);

    Task<int> TryMarkExpiredAsync(Guid tripRequestId, CancellationToken cancellationToken);
}
