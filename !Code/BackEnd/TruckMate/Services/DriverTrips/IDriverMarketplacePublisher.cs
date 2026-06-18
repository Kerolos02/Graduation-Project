namespace TruckMate.Services.DriverTrips;

public class NewMarketplaceRequestSignalDto
{
    public Guid RequestId { get; set; }
    public string RequestNumber { get; set; } = string.Empty;
    public decimal OfferedPaymentEGP { get; set; }
    public string OfferedPaymentFormatted { get; set; } = string.Empty;
    public string PickupLocation { get; set; } = string.Empty;
    public string DropoffLocation { get; set; } = string.Empty;
    public decimal DistanceKm { get; set; }
    public string EstimatedDurationFormatted { get; set; } = string.Empty;
    public decimal WeightLbs { get; set; }
    public string CargoType { get; set; } = string.Empty;
    public string PostedAgoFormatted { get; set; } = string.Empty;
}

public interface IDriverMarketplacePublisher
{
    Task PublishNewRequestAvailableAsync(string zone, NewMarketplaceRequestSignalDto payload,
        CancellationToken cancellationToken);

    Task PublishRequestTakenAsync(string zone, Guid requestId, string requestNumber,
        CancellationToken cancellationToken);

    Task PublishRequestCancelledAsync(string zone, Guid requestId, string? reason,
        CancellationToken cancellationToken);

    Task PublishRequestExpiredAsync(Guid requestId, CancellationToken cancellationToken);

    Task PublishRequestExpiredNoDriverAsync(Guid requestId, CancellationToken cancellationToken);

    Task PublishDriverAcceptedToTraderAsync(int traderPkId, string driverName, DateTime acceptedAt,
        CancellationToken cancellationToken);

    Task PublishRequestAcceptedToDispatchersAsync(Guid requestId, int driverDbId,
        CancellationToken cancellationToken);

    Task PublishDriverRejectedRequestAsync(Guid requestId, int driverDbId,
        CancellationToken cancellationToken);
}
