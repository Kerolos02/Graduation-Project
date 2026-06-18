using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface IDriverPrivacySettingRepository
{
    Task<DriverPrivacySetting?> GetByDriverPublicIdAsync(Guid driverPublicId, CancellationToken cancellationToken);
    void Add(DriverPrivacySetting entity);
}
