using System.Data;
using Microsoft.EntityFrameworkCore;
using TruckMate.Data.Context;

namespace TruckMate.Services.DriverTrips;

public class RequestNumberGenerator : IRequestNumberGenerator
{
    private readonly TruckMateDbContext _context;

    public RequestNumberGenerator(TruckMateDbContext context)
    {
        _context = context;
    }

    public async Task<string> GenerateNextRequestNumberAsync(CancellationToken cancellationToken)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx =
                await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken)
                    .ConfigureAwait(false);
            try
            {
                var seq = await _context.RequestNumberSequences
                    .FirstAsync(s => s.Id == 1, cancellationToken)
                    .ConfigureAwait(false);
                seq.LastNumber++;
                await _context.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
                await tx.CommitAsync(cancellationToken).ConfigureAwait(false);
                return $"REQ-{seq.LastNumber:D4}";
            }
            catch
            {
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                throw;
            }
        }).ConfigureAwait(false);
    }
}
