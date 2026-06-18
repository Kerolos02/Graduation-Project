using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DeliveryTripRepository : Repository<DeliveryTrip>, IDeliveryTripRepository
{
    public DeliveryTripRepository(TruckMateDbContext context)
        : base(context)
    {
    }

    public async Task<int> GetNextShipmentNumericAsync(CancellationToken cancellationToken)
    {
        var max = await DbSet.MaxAsync(x => (int?)x.ShipmentNumericId, cancellationToken).ConfigureAwait(false);
        return (max ?? 0) + 1;
    }

    public Task<DeliveryTrip?> GetByIdWithShipmentAsync(Guid id, CancellationToken cancellationToken) =>
        DbSet.AsNoTracking()
            .Include(t => t.CourierShipment)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public Task<DeliveryTrip?> GetByIdWithShipmentTrackedAsync(Guid id, CancellationToken cancellationToken) =>
        DbSet
            .Include(t => t.CourierShipment)
            .Include(t => t.Trader)
            .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public async Task<DeliveryTrip?> GetActiveCourierTripForDriverAsync(int driverDbId,
        CancellationToken cancellationToken)
    {
        return await DbSet
            .Include(t => t.CourierShipment)
            .FirstOrDefaultAsync(
                t => t.AssignedDriverId == driverDbId
                     && (t.Status == CourierTripStatus.Assigned || t.Status == CourierTripStatus.InProgress),
                cancellationToken)
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<DeliveryTrip>> GetIncomingPendingForZoneAsync(string zone,
        CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Include(t => t.CourierShipment)
            .Where(t => t.Status == CourierTripStatus.Pending
                        && t.AssignedDriverId == null
                        && t.Zone == zone)
            .OrderByDescending(t => t.OfferedAtUtc)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<DeliveryTrip>> GetRecentCompletedAsync(int driverDbId,
        int skip, int take, CancellationToken cancellationToken)
    {
        return await DbSet.AsNoTracking()
            .Where(t => t.AssignedDriverId == driverDbId && t.Status == CourierTripStatus.Completed)
            .OrderByDescending(t => t.CompletedAtUtc)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public Task<int> CountRecentCompletedAsync(int driverDbId, CancellationToken cancellationToken) =>
        DbSet.CountAsync(t => t.AssignedDriverId == driverDbId && t.Status == CourierTripStatus.Completed,
            cancellationToken);

    public Task<DeliveryTrip?> GetByIdForTraderAsync(Guid tripId, Guid traderPublicId, CancellationToken cancellationToken) =>
        DbSet
            .Include(t => t.AssignedDriver)!.ThenInclude(d => d!.User)
            .Include(t => t.Trader)
            .FirstOrDefaultAsync(t => t.Id == tripId && t.Trader.PublicId == traderPublicId, cancellationToken);

    public async Task<(IReadOnlyList<(DeliveryTrip Trip, string? MarketplaceRequestNumber)> Items, int TotalCount)>
        GetMyTripsPagedAsync(int driverDbId, string? status, int page, int pageSize,
            CancellationToken cancellationToken)
    {
        var trips = DbSet.AsNoTracking().Include(t => t.CourierShipment)
            .Where(t => t.AssignedDriverId == driverDbId);

        if (string.Equals(status, "active", StringComparison.OrdinalIgnoreCase))
        {
            trips = trips.Where(t => t.Status == CourierTripStatus.Assigned || t.Status == CourierTripStatus.InProgress);
        }
        else if (string.Equals(status, "completed", StringComparison.OrdinalIgnoreCase))
        {
            trips = trips.Where(t => t.Status == CourierTripStatus.Completed);
        }

        var joined = from t in trips
            join r in Context.TripRequests.AsNoTracking() on t.Id equals r.CreatedDeliveryTripId into rg
            from r in rg.DefaultIfEmpty()
            select new { Trip = t, MarketplaceRequestNumber = r != null ? r.RequestNumber : null };

        var ordered = joined.OrderByDescending(x => x.Trip.AssignedAtUtc ?? x.Trip.OfferedAtUtc);

        var total = await ordered.CountAsync(cancellationToken).ConfigureAwait(false);
        var pageItems = await ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var list = pageItems.Select(x => (x.Trip, (string?)x.MarketplaceRequestNumber)).ToList();
        return (list, total);
    }
}
