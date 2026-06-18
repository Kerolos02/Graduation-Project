using TruckMate.Core.TraderMobile.Dtos;

namespace TruckMate.Services.TraderMobile;

public interface ITraderMobileService
{
    Task<TraderHomeCurrentShipmentResponseDto> GetHomeCurrentShipmentAsync(Guid traderId, CancellationToken cancellationToken);
    Task<TraderShipmentDetailsResponseDto> GetShipmentDetailsAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken);
    Task<DriverOffersResponseDto> GetShipmentOffersAsync(Guid traderId, Guid shipmentId, string tab, int page, int pageSize,
        CancellationToken cancellationToken);
    Task AcceptOfferAsync(Guid traderId, Guid offerId, CancellationToken cancellationToken);
    Task RejectOfferAsync(Guid traderId, Guid offerId, CancellationToken cancellationToken);

    Task<SuggestedDriversResponseDto> GetSuggestedDriversAsync(Guid traderId, Guid shipmentId, int page, int pageSize,
        CancellationToken cancellationToken);
    Task<DriverDetailsResponseDto> GetDriverDetailsAsync(Guid traderId, Guid driverId, Guid? shipmentId,
        CancellationToken cancellationToken);
    Task<SelectDriverResponseDto> SelectDriverAsync(Guid traderId, Guid shipmentId, Guid driverId,
        CancellationToken cancellationToken);
    Task<ShipmentTrackingResponseDto> GetTrackingAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken);
    Task<DateTime> MarkDeliveredAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken);
    Task CancelShipmentAsync(Guid traderId, Guid shipmentId, string? reason, CancellationToken cancellationToken);
    Task<DeliverySummaryResponseDto> GetDeliverySummaryAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken);
    Task RateDriverAsync(Guid traderId, Guid shipmentId, int rating, string? comment, CancellationToken cancellationToken);
    Task<InvoiceDetailsResponseDto> GetInvoiceDetailsAsync(Guid traderId, Guid invoiceId, CancellationToken cancellationToken);
    Task<(DateTime paidAt, string paidWith)> PayInvoiceAsync(Guid traderId, Guid invoiceId, Guid cardId,
        CancellationToken cancellationToken);
    Task<byte[]> GenerateInvoicePdfAsync(Guid traderId, Guid invoiceId, CancellationToken cancellationToken);
    Task<string> ShareInvoiceAsync(Guid traderId, Guid invoiceId, string method, CancellationToken cancellationToken);
    Task<TraderWalletResponseDto> GetWalletAsync(Guid traderId, CancellationToken cancellationToken);
    Task<SavedCardDto> AddCardAsync(Guid traderId, AddCardRequestDto request, CancellationToken cancellationToken);
    Task DeleteCardAsync(Guid traderId, Guid cardId, CancellationToken cancellationToken);
    Task SetDefaultCardAsync(Guid traderId, Guid cardId, CancellationToken cancellationToken);
}
