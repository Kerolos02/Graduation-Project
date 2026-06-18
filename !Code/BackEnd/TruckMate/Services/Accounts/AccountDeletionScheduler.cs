using Microsoft.Extensions.Logging;

namespace TruckMate.Services.Accounts;

public interface IAccountDeletionScheduler
{
    Task ScheduleDeletionAsync(Guid driverPublicId, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken);

    Task ScheduleTraderDeletionAsync(Guid traderPublicId, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken);

    Task CancelDeletionAsync(int userId, CancellationToken cancellationToken);

    Task CancelTraderDeletionAsync(int userId, CancellationToken cancellationToken);
}

public class AccountDeletionScheduler : IAccountDeletionScheduler
{
    private readonly ILogger<AccountDeletionScheduler> _logger;

    public AccountDeletionScheduler(ILogger<AccountDeletionScheduler> logger)
    {
        _logger = logger;
    }

    public Task ScheduleDeletionAsync(Guid driverPublicId, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken)
    {
        _logger.LogWarning("Recorded account deletion sweep target driver {Pid} due {Due}", driverPublicId,
            scheduledHardDeleteUtc);
        return Task.CompletedTask;
    }

    public Task ScheduleTraderDeletionAsync(Guid traderPublicId, DateTime scheduledHardDeleteUtc,
        CancellationToken cancellationToken)
    {
        _logger.LogWarning("Recorded account deletion sweep target trader {Pid} due {Due}", traderPublicId,
            scheduledHardDeleteUtc);
        return Task.CompletedTask;
    }

    public Task CancelDeletionAsync(int userId, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Recorded cancellation hint for user {UserId}", userId);
        return Task.CompletedTask;
    }

    public Task CancelTraderDeletionAsync(int userId, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Recorded trader deletion cancellation hint for user {UserId}", userId);
        return Task.CompletedTask;
    }
}
