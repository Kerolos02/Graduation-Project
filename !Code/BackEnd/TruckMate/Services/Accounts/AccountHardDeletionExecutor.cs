using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;

namespace TruckMate.Services.Accounts;

/// <summary>Permanently removes users whose deletion grace periods have elapsed.</summary>
public interface IAccountHardDeletionExecutor
{
    Task ProcessExpiredAccountsAsync(CancellationToken cancellationToken);
}

public class AccountHardDeletionExecutor : IAccountHardDeletionExecutor
{
    private readonly TruckMateDbContext _db;
    private readonly ILogger<AccountHardDeletionExecutor> _logger;

    public AccountHardDeletionExecutor(TruckMateDbContext db, ILogger<AccountHardDeletionExecutor> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task ProcessExpiredAccountsAsync(CancellationToken cancellationToken)
    {
        var utc = DateTime.UtcNow;
        var expired = await _db.Users.AsNoTracking()
            .Where(u => u.IsDeleted && u.ScheduledHardDeleteAtUtc != null &&
                        u.ScheduledHardDeleteAtUtc <= utc)
            .Select(u => new { u.Id, u.Role })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var item in expired)
        {
            if (item.Role == UserRole.Trader)
            {
                await HardDeleteTraderUserInternalAsync(item.Id, cancellationToken).ConfigureAwait(false);
            }
            else
            {
                await HardDeleteDriverUserInternalAsync(item.Id, cancellationToken).ConfigureAwait(false);
            }
        }
    }

    private async Task HardDeleteDriverUserInternalAsync(int userId, CancellationToken cancellationToken)
    {
        var driver =
            await _db.Drivers.FirstOrDefaultAsync(d => d.UserId == userId, cancellationToken).ConfigureAwait(false);
        await using var trx = await _db.Database.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (driver != null)
            {
                var driverIntId = driver.Id;
                var driverPublicId = driver.PublicId;

                await _db.DriverNotificationPreferences
                    .Where(x => x.DriverPublicId == driverPublicId).ExecuteDeleteAsync(cancellationToken)
                    .ConfigureAwait(false);
                await _db.DriverPrivacySettings.Where(x => x.DriverPublicId == driverPublicId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                await _db.DriverAuditLogs.Where(x => x.DriverPublicId == driverPublicId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);

                await _db.DriverDailySummaries.Where(x => x.DriverId == driverIntId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);

                await _db.DeliveryTrips.Where(x => x.AssignedDriverId == driverIntId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);

                await _db.ShipmentRequests.Where(x => x.AssignedDriverId == driverIntId)
                    .ExecuteUpdateAsync(x =>
                            x.SetProperty(s => s.AssignedDriverId, (int?)null),
                        cancellationToken)
                    .ConfigureAwait(false);

                var tripIds =
                    await _db.Trips.Where(t => t.DriverId == driverIntId).Select(t => t.Id)
                        .ToListAsync(cancellationToken).ConfigureAwait(false);
                if (tripIds.Count > 0)
                {
                    await _db.Reviews.Where(r => tripIds.Contains(r.TripId))
                        .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                }

                await _db.Trips.Where(t => t.DriverId == driverIntId).ExecuteDeleteAsync(cancellationToken)
                    .ConfigureAwait(false);
                await _db.Offers.Where(o => o.DriverId == driverIntId).ExecuteDeleteAsync(cancellationToken)
                    .ConfigureAwait(false);
                await _db.Drivers.Where(d => d.Id == driverIntId).ExecuteDeleteAsync(cancellationToken)
                    .ConfigureAwait(false);
            }

            await _db.Users.Where(u => u.Id == userId).ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
            await trx.CommitAsync(cancellationToken).ConfigureAwait(false);
            _logger.LogCritical("Hard-deleted People id {UserId}", userId);
        }
        catch (Exception ex)
        {
            await trx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            _logger.LogError(ex, "Failed hard delete for People id {UserId}", userId);
        }
    }

    private async Task HardDeleteTraderUserInternalAsync(int userId, CancellationToken cancellationToken)
    {
        var trader = await _db.Traders.FirstOrDefaultAsync(t => t.UserId == userId, cancellationToken)
            .ConfigureAwait(false);
        await using var trx = await _db.Database.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (trader != null)
            {
                var tid = trader.Id;
                var publicId = trader.PublicId;

                var shipmentIds = await _db.ShipmentRequests.AsNoTracking()
                    .Where(s => s.TraderId == tid)
                    .Select(s => s.Id)
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                if (shipmentIds.Count > 0)
                {
                    var tripIds = await _db.Trips.Where(t => shipmentIds.Contains(t.ShipmentRequestId))
                        .Select(t => t.Id)
                        .ToListAsync(cancellationToken).ConfigureAwait(false);
                    if (tripIds.Count > 0)
                    {
                        await _db.Reviews.Where(r => tripIds.Contains(r.TripId))
                            .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                    }

                    await _db.Reviews.Where(r => r.TraderId == tid)
                        .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);

                    await _db.Trips.Where(t => shipmentIds.Contains(t.ShipmentRequestId))
                        .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                    await _db.Offers.Where(o => shipmentIds.Contains(o.ShipmentRequestId))
                        .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                    await _db.ShipmentRequests.Where(s => s.TraderId == tid).ExecuteDeleteAsync(cancellationToken)
                        .ConfigureAwait(false);
                }

                await _db.TraderNotificationPreferences.Where(x => x.TraderPublicId == publicId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                await _db.TraderPrivacySettings.Where(x => x.TraderPublicId == publicId)
                    .ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
                await _db.TraderAuditLogs.Where(x => x.TraderPublicId == publicId).ExecuteDeleteAsync(cancellationToken)
                    .ConfigureAwait(false);
                await _db.Traders.Where(t => t.Id == tid).ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
            }

            await _db.Users.Where(u => u.Id == userId).ExecuteDeleteAsync(cancellationToken).ConfigureAwait(false);
            await trx.CommitAsync(cancellationToken).ConfigureAwait(false);
            _logger.LogCritical("Hard-deleted Trader user People id {UserId}", userId);
        }
        catch (Exception ex)
        {
            await trx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            _logger.LogError(ex, "Failed hard delete for Trader user People id {UserId}", userId);
        }
    }
}
