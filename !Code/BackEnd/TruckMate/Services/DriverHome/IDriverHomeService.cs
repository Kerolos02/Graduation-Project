using TruckMate.Core.DriverHome.Dtos;

namespace TruckMate.Services.DriverHome;

public interface IDriverHomeService
{
    Task<DriverHomeResponseDto> BuildHomePayloadAsync(int userId, CancellationToken cancellationToken);

    Task<DriverStatusPatchResponse> UpdateAvailabilityAsync(int userId, string requestedStatus,
        CancellationToken cancellationToken);

    Task<IncomingTripsResponseDto> GetIncomingOffersAsync(int userId, CancellationToken cancellationToken);

    Task<StartTripResponseDto> StartAssignedTripAsync(int userId, Guid tripId, CancellationToken cancellationToken);
    Task<DriverTripExecutionScreenDto> GetTripExecutionScreenAsync(int userId, Guid tripId,
        CancellationToken cancellationToken);
    Task<StartTripResponseDto> MarkArrivedAtPickupAsync(int userId, Guid tripId, CancellationToken cancellationToken);
    Task<StartTripResponseDto> ConfirmPickupAsync(int userId, Guid tripId, CancellationToken cancellationToken);
    Task<StartTripResponseDto> StartDeliveryAsync(int userId, Guid tripId, CancellationToken cancellationToken);
    Task<StartTripResponseDto> MarkDeliveredAsync(int userId, Guid tripId, CancellationToken cancellationToken);

    Task<TripDetailsResponseDto> GetCourierTripDetailsAsync(int userId, Guid tripId, CancellationToken cancellationToken);

    Task<RecentTripsPageResponseDto> GetRecentCourierTripsPageAsync(int userId, int page, int pageSize,
        CancellationToken cancellationToken);

    Task<StartTripResponseDto> CompleteAssignedTripAsync(int userId, Guid tripId, CancellationToken cancellationToken);

    Task<DriverStatusPatchResponse?> TryApplySignalRStatusAsync(int userId, string requestedStatus,
        CancellationToken cancellationToken);
}
