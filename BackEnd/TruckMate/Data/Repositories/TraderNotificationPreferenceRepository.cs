using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class TraderNotificationPreferenceRepository : ITraderNotificationPreferenceRepository
{
    private readonly TruckMateDbContext _context;

    public TraderNotificationPreferenceRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<TraderNotificationPreference?> GetByTraderPublicIdForReadAsync(Guid traderPublicId,
        CancellationToken cancellationToken) =>
        _context.TraderNotificationPreferences.AsNoTracking()
            .FirstOrDefaultAsync(x => x.TraderPublicId == traderPublicId, cancellationToken);

    public Task<TraderNotificationPreference?> GetByTraderPublicIdTrackedAsync(Guid traderPublicId,
        CancellationToken cancellationToken) =>
        _context.TraderNotificationPreferences
            .FirstOrDefaultAsync(x => x.TraderPublicId == traderPublicId, cancellationToken);

    public void Add(TraderNotificationPreference entity) =>
        _context.TraderNotificationPreferences.Add(entity);
}
