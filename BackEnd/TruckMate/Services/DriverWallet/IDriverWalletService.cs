using TruckMate.Core.DriverWallet.Dtos;

namespace TruckMate.Services.DriverWallet;

public interface IDriverWalletService
{
    Task<DriverWalletScreenResponseDto> GetWalletScreenAsync(Guid driverId, string filter, int page, int pageSize,
        CancellationToken cancellationToken);
    Task<DriverWalletSummaryResponseDto> GetWalletSummaryAsync(Guid driverId, CancellationToken cancellationToken);
    Task<DriverWalletTripsResponseDto> GetEarningTripsAsync(Guid driverId, string filter, int page, int pageSize,
        CancellationToken cancellationToken);
    Task<DriverWalletTripDetailResponseDto?> GetEarningTripDetailAsync(Guid driverId, Guid tripId,
        CancellationToken cancellationToken);
    Task CreateEarningRecordAsync(Guid tripId, CancellationToken cancellationToken);
    Task<bool> CanAccessTripAsync(Guid driverId, Guid tripId, CancellationToken cancellationToken);
}
