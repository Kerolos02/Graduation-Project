namespace TruckMate.Services.DriverTrips;

/// <summary>Bumps a global version so per-driver available-request cache entries become stale immediately.</summary>
public interface IMarketplaceRequestCacheBumper
{
    long CurrentVersion { get; }

    void Bump();
}
