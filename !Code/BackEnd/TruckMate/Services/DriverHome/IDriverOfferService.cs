using TruckMate.Core.DriverOffers.Dtos;

namespace TruckMate.Services.DriverHome;

public interface IDriverOfferService
{
    Task<CurrentDriverOfferResponseDto> GetCurrentOfferAsync(int userId, CancellationToken cancellationToken);
    Task<AcceptOfferResponseDto> AcceptOfferAsync(int userId, Guid offerId, CancellationToken cancellationToken);
    Task<DriverOfferStatusCardDto> DeclineOfferAsync(int userId, Guid offerId, string? reason,
        CancellationToken cancellationToken);
    Task<OfferStatusResponseDto> GetOfferStatusAsync(int userId, Guid offerId, CancellationToken cancellationToken);
}
