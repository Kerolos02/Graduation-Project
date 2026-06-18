namespace TruckMate.Services.DriverTrips;

public interface IRequestNumberGenerator
{
    Task<string> GenerateNextRequestNumberAsync(CancellationToken cancellationToken);
}
