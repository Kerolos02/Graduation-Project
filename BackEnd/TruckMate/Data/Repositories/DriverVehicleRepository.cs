using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverVehicleRepository : Repository<DriverVehicle>, IDriverVehicleRepository
{
    public DriverVehicleRepository(TruckMateDbContext context) : base(context)
    {
    }

    public Task<DriverVehicle?> GetByDriverIdAsync(Guid driverPublicId, CancellationToken cancellationToken) =>
        DbSet.AsNoTracking().FirstOrDefaultAsync(x => x.DriverPublicId == driverPublicId, cancellationToken);
}
