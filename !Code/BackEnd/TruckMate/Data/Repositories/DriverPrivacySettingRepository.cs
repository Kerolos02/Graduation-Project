using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverPrivacySettingRepository : IDriverPrivacySettingRepository
{
    private readonly TruckMateDbContext _context;

    public DriverPrivacySettingRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<DriverPrivacySetting?> GetByDriverPublicIdAsync(Guid driverPublicId,
        CancellationToken cancellationToken) =>
        _context.DriverPrivacySettings.FirstOrDefaultAsync(x => x.DriverPublicId == driverPublicId, cancellationToken);

    public void Add(DriverPrivacySetting entity) =>
        _context.DriverPrivacySettings.Add(entity);
}
