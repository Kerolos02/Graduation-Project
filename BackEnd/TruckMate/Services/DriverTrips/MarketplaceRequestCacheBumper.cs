namespace TruckMate.Services.DriverTrips;

public class MarketplaceRequestCacheBumper : IMarketplaceRequestCacheBumper
{
    private long _version;

    public long CurrentVersion => System.Threading.Interlocked.Read(ref _version);

    public void Bump() => System.Threading.Interlocked.Increment(ref _version);
}
