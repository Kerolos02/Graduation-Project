using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverNotificationPreferenceRepository : IDriverNotificationPreferenceRepository
{
    private readonly TruckMateDbContext _context;

    public DriverNotificationPreferenceRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<DriverNotificationPreference?> GetByDriverPublicIdAsync(Guid driverPublicId,
        CancellationToken cancellationToken) =>
        _context.DriverNotificationPreferences.FirstOrDefaultAsync(x => x.DriverPublicId == driverPublicId,
            cancellationToken);

    public void Add(DriverNotificationPreference entity) =>
        _context.DriverNotificationPreferences.Add(entity);
}
