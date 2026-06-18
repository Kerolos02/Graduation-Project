using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverVehicleRepository : IRepository<DriverVehicle>
{
    Task<DriverVehicle?> GetByDriverIdAsync(Guid driverPublicId, CancellationToken cancellationToken);
}
