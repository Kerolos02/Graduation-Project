using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverNotificationPreferenceRepository
{
    Task<DriverNotificationPreference?> GetByDriverPublicIdAsync(Guid driverPublicId,
        CancellationToken cancellationToken);

    void Add(DriverNotificationPreference entity);
}
