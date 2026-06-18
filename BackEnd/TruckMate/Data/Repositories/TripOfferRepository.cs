using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TripOfferRepository : Repository<TripOffer>, ITripOfferRepository
{
    public TripOfferRepository(TruckMateDbContext context) : base(context)
    {
    }

    public Task<TripOffer?> GetPendingByDriverIdAsync(int driverId, CancellationToken cancellationToken) =>
        DbSet
            .AsNoTracking()
            .Include(x => x.Trip).ThenInclude(t => t.CourierShipment)
            .Include(x => x.Trip).ThenInclude(t => t.Trader)
            .FirstOrDefaultAsync(x => x.DriverId == driverId && x.Status == TripOfferStatus.Pending, cancellationToken);

    public Task<TripOffer?> GetByIdForDriverAsync(Guid offerId, int driverId, CancellationToken cancellationToken) =>
        DbSet
            .AsNoTracking()
            .Include(x => x.Trip).ThenInclude(t => t.CourierShipment)
            .Include(x => x.Trip).ThenInclude(t => t.Trader)
            .FirstOrDefaultAsync(x => x.Id == offerId && x.DriverId == driverId, cancellationToken);

    public Task<TripOffer?> GetByIdTrackedAsync(Guid offerId, CancellationToken cancellationToken) =>
        DbSet
            .Include(x => x.Trip).ThenInclude(t => t.CourierShipment)
            .Include(x => x.Trip).ThenInclude(t => t.Trader)
            .FirstOrDefaultAsync(x => x.Id == offerId, cancellationToken);

    public async Task<IReadOnlyList<TripOffer>> GetPendingByTripIdAsync(Guid tripId, CancellationToken cancellationToken)
    {
        return await DbSet
            .Where(x => x.TripId == tripId && x.Status == TripOfferStatus.Pending)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<TripOffer>> GetExpiredPendingsAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        return await DbSet
            .Include(x => x.Trip).ThenInclude(t => t.CourierShipment)
            .Include(x => x.Driver).ThenInclude(d => d.User)
            .Where(x => x.Status == TripOfferStatus.Pending && x.ExpiresAtUtc <= utcNow)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public Task<bool> HasPendingOfferForDriverAsync(int driverId, CancellationToken cancellationToken) =>
        DbSet.AnyAsync(x => x.DriverId == driverId && x.Status == TripOfferStatus.Pending, cancellationToken);

    public Task<bool> DriverDeclinedTripBeforeAsync(int driverId, Guid tripId, CancellationToken cancellationToken) =>
        DbSet.AnyAsync(x =>
                x.DriverId == driverId &&
                x.TripId == tripId &&
                x.Status == TripOfferStatus.Declined,
            cancellationToken);

    public Task MarkPendingByTripAsCancelledAsync(Guid tripId, Guid acceptedOfferId, string reason, DateTime utcNow,
        CancellationToken cancellationToken) =>
        DbSet
            .Where(x => x.TripId == tripId && x.Status == TripOfferStatus.Pending && x.Id != acceptedOfferId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(x => x.Status, TripOfferStatus.Cancelled)
                .SetProperty(x => x.RespondedAtUtc, utcNow)
                .SetProperty(x => x.CancelReason, reason), cancellationToken);

    public Task<int> ExecuteExpirePendingAsync(Guid offerId, DateTime utcNow, CancellationToken cancellationToken) =>
        DbSet
            .Where(x => x.Id == offerId && x.Status == TripOfferStatus.Pending)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(x => x.Status, TripOfferStatus.Expired)
                .SetProperty(x => x.RespondedAtUtc, utcNow),
                cancellationToken);
}
