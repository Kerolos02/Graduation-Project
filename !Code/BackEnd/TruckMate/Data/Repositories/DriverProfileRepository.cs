using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverProfileRepository : Repository<Driver>, IDriverProfileRepository
{
    public DriverProfileRepository(TruckMateDbContext context)
        : base(context)
    {
    }

    public Task<Driver?> GetByUserIdWithUserAsync(int userId, CancellationToken cancellationToken) =>
        DbSet
            .Include(d => d.User)
            .Include(d => d.AssignedDeliveryTrip)!
            .ThenInclude(t => t!.CourierShipment)
            .AsSplitQuery()
            .FirstOrDefaultAsync(d => d.UserId == userId, cancellationToken);

    public Task<Driver?> GetByUserIdForUpdateAsync(int userId, CancellationToken cancellationToken) =>
        DbSet
            .Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId, cancellationToken);

    public Task<Driver?> GetByPublicIdWithUserAsync(Guid driverPublicId, CancellationToken cancellationToken) =>
        DbSet
            .Include(d => d.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.PublicId == driverPublicId, cancellationToken);
}
