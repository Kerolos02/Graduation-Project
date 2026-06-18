using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderPrivacySettingRepository : ITraderPrivacySettingRepository
{
    private readonly TruckMateDbContext _context;

    public TraderPrivacySettingRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<TraderPrivacySetting?> GetByTraderPublicIdForReadAsync(Guid traderPublicId,
        CancellationToken cancellationToken) =>
        _context.TraderPrivacySettings.AsNoTracking()
            .FirstOrDefaultAsync(x => x.TraderPublicId == traderPublicId, cancellationToken);

    public Task<TraderPrivacySetting?> GetByTraderPublicIdTrackedAsync(Guid traderPublicId,
        CancellationToken cancellationToken) =>
        _context.TraderPrivacySettings
            .FirstOrDefaultAsync(x => x.TraderPublicId == traderPublicId, cancellationToken);

    public void Add(TraderPrivacySetting entity) =>
        _context.TraderPrivacySettings.Add(entity);
}
