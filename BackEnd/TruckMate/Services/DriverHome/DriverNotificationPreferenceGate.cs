using Microsoft.EntityFrameworkCore;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.DriverHome;

public interface IDriverNotificationPreferenceGate
{
    Task<bool> CanSendTripAssignedForUserAsync(int driverUserId, CancellationToken cancellationToken);

    Task<bool> CanSendTripOfferForUserAsync(int driverUserId, CancellationToken cancellationToken);
}

public class DriverNotificationPreferenceGate : IDriverNotificationPreferenceGate
{
    private readonly IUnitOfWork _uow;

    public DriverNotificationPreferenceGate(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<bool> CanSendTripAssignedForUserAsync(int driverUserId,
        CancellationToken cancellationToken)
    {
        var pid = await GetDriverPublicIdOrNull(driverUserId, cancellationToken).ConfigureAwait(false);
        if (pid == null)
        {
            return true;
        }

        var p = await _uow.DriverNotificationPreferences.GetByDriverPublicIdAsync(pid.Value, cancellationToken)
            .ConfigureAwait(false);
        if (p == null)
        {
            return true;
        }

        return p.TripAssignedEnabled && p.PushNotificationsEnabled;
    }

    public async Task<bool> CanSendTripOfferForUserAsync(int driverUserId,
        CancellationToken cancellationToken)
    {
        var pid = await GetDriverPublicIdOrNull(driverUserId, cancellationToken).ConfigureAwait(false);
        if (pid == null)
        {
            return true;
        }

        var p = await _uow.DriverNotificationPreferences.GetByDriverPublicIdAsync(pid.Value, cancellationToken)
            .ConfigureAwait(false);
        if (p == null)
        {
            return true;
        }

        return p.TripOfferEnabled && p.PushNotificationsEnabled;
    }

    private async Task<Guid?> GetDriverPublicIdOrNull(int userId, CancellationToken cancellationToken)
    {
        var pid = await _uow.Drivers.Query().AsNoTracking()
            .Where(d => d.UserId == userId)
            .Select(d => d.PublicId)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        return pid == default ? null : pid;
    }
}
