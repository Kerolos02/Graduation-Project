using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TripRequestRepository : ITripRequestRepository
{
    private readonly TruckMateDbContext _context;

    public TripRequestRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<TripRequest?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
        _context.TripRequests.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public Task<TripRequest?> GetByIdTrackedAsync(Guid id, CancellationToken cancellationToken) =>
        _context.TripRequests
            .Include(t => t.Trader).ThenInclude(tr => tr.User)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public Task<TripRequest?> GetByIdForDetailAsync(Guid id, CancellationToken cancellationToken) =>
        _context.TripRequests
            .AsNoTracking()
            .Include(t => t.Trader).ThenInclude(tr => tr.User)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public async Task<(IReadOnlyList<TripRequest> Items, int TotalCount)> GetOpenForDriverAsync(int driverId,
        string zone, string? truckType, string sortBy, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var truckNorm = (truckType ?? string.Empty).ToLowerInvariant();
        var q = _context.TripRequests.AsNoTracking()
            .Where(t => t.Status == TripRequestStatus.Open
                        && t.Zone == zone
                        && !t.Rejections.Any(r => r.DriverId == driverId)
                        && (t.RequiredTruckType == null || t.RequiredTruckType == string.Empty
                                                       || t.RequiredTruckType.ToLower() == truckNorm));

        q = sortBy switch
        {
            "price_desc" => q.OrderByDescending(t => t.PaymentAmountEGP),
            "distance_asc" => q.OrderBy(t => t.DistanceKm),
            _ => q.OrderByDescending(t => t.PostedAt)
        };

        var total = await q.CountAsync(cancellationToken).ConfigureAwait(false);
        var items = await q
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return (items, total);
    }

    public Task<int> TryMarkAcceptedAsync(Guid tripRequestId, int driverId, DateTime acceptedAtUtc,
        CancellationToken cancellationToken) =>
        _context.TripRequests
            .Where(t => t.Id == tripRequestId && t.Status == TripRequestStatus.Open)
            .ExecuteUpdateAsync(setters => setters
                    .SetProperty(t => t.Status, TripRequestStatus.Accepted)
                    .SetProperty(t => t.AcceptedByDriverId, driverId)
                    .SetProperty(t => t.AcceptedAt, acceptedAtUtc),
                cancellationToken);

    public Task AddRejectionAsync(TripRequestRejection rejection, CancellationToken cancellationToken) =>
        _context.TripRequestRejections.AddAsync(rejection, cancellationToken).AsTask();

    public Task<bool> HasDriverRejectedAsync(Guid tripRequestId, int driverId, CancellationToken cancellationToken) =>
        _context.TripRequestRejections.AsNoTracking()
            .AnyAsync(r => r.TripRequestId == tripRequestId && r.DriverId == driverId, cancellationToken);

    public async Task<IReadOnlyList<TripRequest>> GetExpiredOpenAsync(DateTime utcNow,
        CancellationToken cancellationToken) =>
        await _context.TripRequests
            .Where(t => t.Status == TripRequestStatus.Open && t.ExpiresAt != null && t.ExpiresAt <= utcNow)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

    public Task AddAsync(TripRequest entity, CancellationToken cancellationToken) =>
        _context.TripRequests.AddAsync(entity, cancellationToken).AsTask();

    public Task<int> TryMarkExpiredAsync(Guid tripRequestId, CancellationToken cancellationToken) =>
        _context.TripRequests
            .Where(t => t.Id == tripRequestId && t.Status == TripRequestStatus.Open)
            .ExecuteUpdateAsync(setters => setters.SetProperty(t => t.Status, TripRequestStatus.Expired),
                cancellationToken);
}
