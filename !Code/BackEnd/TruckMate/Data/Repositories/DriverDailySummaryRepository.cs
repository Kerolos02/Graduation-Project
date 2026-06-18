using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverDailySummaryRepository : Repository<DriverDailySummary>, IDriverDailySummaryRepository
{
    public DriverDailySummaryRepository(TruckMateDbContext context)
        : base(context)
    {
    }

    public Task<DriverDailySummary?> GetForDriverAndDateAsync(int driverId, DateOnly date,
        CancellationToken cancellationToken) =>
        DbSet.FirstOrDefaultAsync(s => s.DriverId == driverId && s.SummaryDate == date, cancellationToken);
}
