using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverDailySummaryRepository : IRepository<DriverDailySummary>
{
    Task<DriverDailySummary?> GetForDriverAndDateAsync(int driverId, DateOnly date,
        CancellationToken cancellationToken);
}
