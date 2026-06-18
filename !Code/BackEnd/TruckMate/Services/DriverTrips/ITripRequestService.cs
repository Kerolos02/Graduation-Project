using TruckMate.Core.DriverTrips.Dtos;

namespace TruckMate.Services.DriverTrips;

public interface ITripRequestService
{
    Task<AvailableTripRequestsResponseDto> GetAvailableRequestsAsync(int userId, string sortBy, int page,
        int pageSize, CancellationToken cancellationToken);

    Task<TripRequestDetailResponseDto> GetRequestDetailAsync(Guid requestId, int userId,
        CancellationToken cancellationToken);

    Task<AcceptTripRequestResponseDto> AcceptRequestAsync(Guid requestId, int userId,
        CancellationToken cancellationToken);

    Task<(string Message, Guid RequestId)> RejectRequestAsync(Guid requestId, int userId, string? reason,
        CancellationToken cancellationToken);

    Task<MyMarketplaceTripsResponseDto> GetMyTripsAsync(int userId, string status, int page, int pageSize,
        CancellationToken cancellationToken);
}
