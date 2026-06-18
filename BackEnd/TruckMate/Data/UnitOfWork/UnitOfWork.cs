using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Data.Context;
using TruckMate.Data.Repositories;

namespace TruckMate.Data.UnitOfWork;

public interface IUnitOfWork
{
    IDeliveryTripRepository DeliveryTrips { get; }
    ITripOfferRepository TripOffers { get; }
    IDriverOfferHistoryRepository DriverOfferHistories { get; }
    IDriverProfileRepository Drivers { get; }
    IDriverDailySummaryRepository DriverDailySummaries { get; }
    IDriverEarningRepository DriverEarnings { get; }
    IDriverVehicleRepository DriverVehicles { get; }
    IDriverReviewRepository DriverReviews { get; }
    IShipmentStatusHistoryRepository ShipmentStatusHistories { get; }
    IInvoiceRepository Invoices { get; }
    ITraderPaymentCardRepository TraderPaymentCards { get; }
    ITraderWalletRepository TraderWallets { get; }

    IDriverNotificationPreferenceRepository DriverNotificationPreferences { get; }
    IDriverPrivacySettingRepository DriverPrivacySettings { get; }
    IDriverAuditLogRepository DriverAuditLogs { get; }
    ILegalDocumentRepository LegalDocuments { get; }

    ITraderProfileRepository Traders { get; }
    ITraderNotificationPreferenceRepository TraderNotificationPreferences { get; }
    ITraderPrivacySettingRepository TraderPrivacySettings { get; }
    ITraderAuditLogRepository TraderAuditLogs { get; }

    ITripRequestRepository TripRequests { get; }

    Task<bool> EmailInUseExceptUserAsync(string normalizedEmail, int excludeUserId,
        CancellationToken cancellationToken);

    Task<bool> PhoneInUseExceptUserAsync(string phone, int excludeUserId,
        CancellationToken cancellationToken);

    /// <returns>True if the trader has shipments that prevent account deletion.</returns>
    Task<bool> TraderHasBlockingShipmentsAsync(int traderPkId, CancellationToken cancellationToken);

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

public class UnitOfWork : IUnitOfWork
{
    private readonly TruckMateDbContext _context;
    private readonly Lazy<IDeliveryTripRepository> _deliveryTrips;
    private readonly Lazy<ITripOfferRepository> _tripOffers;
    private readonly Lazy<IDriverOfferHistoryRepository> _driverOfferHistories;
    private readonly Lazy<IDriverProfileRepository> _drivers;
    private readonly Lazy<IDriverDailySummaryRepository> _daily;
    private readonly Lazy<IDriverEarningRepository> _driverEarnings;
    private readonly Lazy<IDriverVehicleRepository> _driverVehicles;
    private readonly Lazy<IDriverReviewRepository> _driverReviews;
    private readonly Lazy<IShipmentStatusHistoryRepository> _shipmentStatusHistories;
    private readonly Lazy<IInvoiceRepository> _invoices;
    private readonly Lazy<ITraderPaymentCardRepository> _traderPaymentCards;
    private readonly Lazy<ITraderWalletRepository> _traderWallets;
    private readonly Lazy<IDriverNotificationPreferenceRepository> _notif;
    private readonly Lazy<IDriverPrivacySettingRepository> _privacy;
    private readonly Lazy<IDriverAuditLogRepository> _audit;
    private readonly Lazy<ILegalDocumentRepository> _legal;
    private readonly Lazy<ITraderProfileRepository> _traders;
    private readonly Lazy<ITraderNotificationPreferenceRepository> _traderNotif;
    private readonly Lazy<ITraderPrivacySettingRepository> _traderPrivacy;
    private readonly Lazy<ITraderAuditLogRepository> _traderAudit;
    private readonly Lazy<ITripRequestRepository> _tripRequests;

    public UnitOfWork(TruckMateDbContext context)
    {
        _context = context;
        _deliveryTrips = new Lazy<IDeliveryTripRepository>(() => new DeliveryTripRepository(context));
        _tripOffers = new Lazy<ITripOfferRepository>(() => new TripOfferRepository(context));
        _driverOfferHistories = new Lazy<IDriverOfferHistoryRepository>(() => new DriverOfferHistoryRepository(context));
        _drivers = new Lazy<IDriverProfileRepository>(() => new DriverProfileRepository(context));
        _daily = new Lazy<IDriverDailySummaryRepository>(() => new DriverDailySummaryRepository(context));
        _driverEarnings = new Lazy<IDriverEarningRepository>(() => new DriverEarningRepository(context));
        _driverVehicles = new Lazy<IDriverVehicleRepository>(() => new DriverVehicleRepository(context));
        _driverReviews = new Lazy<IDriverReviewRepository>(() => new DriverReviewRepository(context));
        _shipmentStatusHistories =
            new Lazy<IShipmentStatusHistoryRepository>(() => new ShipmentStatusHistoryRepository(context));
        _invoices = new Lazy<IInvoiceRepository>(() => new InvoiceRepository(context));
        _traderPaymentCards = new Lazy<ITraderPaymentCardRepository>(() => new TraderPaymentCardRepository(context));
        _traderWallets = new Lazy<ITraderWalletRepository>(() => new TraderWalletRepository(context));
        _notif = new Lazy<IDriverNotificationPreferenceRepository>(() =>
            new DriverNotificationPreferenceRepository(context));
        _privacy =
            new Lazy<IDriverPrivacySettingRepository>(() => new DriverPrivacySettingRepository(context));
        _audit = new Lazy<IDriverAuditLogRepository>(() => new DriverAuditLogRepository(context));
        _legal = new Lazy<ILegalDocumentRepository>(() => new LegalDocumentRepository(context));
        _traders = new Lazy<ITraderProfileRepository>(() => new TraderProfileRepository(context));
        _traderNotif = new Lazy<ITraderNotificationPreferenceRepository>(() =>
            new TraderNotificationPreferenceRepository(context));
        _traderPrivacy =
            new Lazy<ITraderPrivacySettingRepository>(() => new TraderPrivacySettingRepository(context));
        _traderAudit = new Lazy<ITraderAuditLogRepository>(() => new TraderAuditLogRepository(context));
        _tripRequests = new Lazy<ITripRequestRepository>(() => new TripRequestRepository(context));
    }

    public IDeliveryTripRepository DeliveryTrips => _deliveryTrips.Value;
    public ITripOfferRepository TripOffers => _tripOffers.Value;
    public IDriverOfferHistoryRepository DriverOfferHistories => _driverOfferHistories.Value;
    public IDriverProfileRepository Drivers => _drivers.Value;
    public IDriverDailySummaryRepository DriverDailySummaries => _daily.Value;
    public IDriverEarningRepository DriverEarnings => _driverEarnings.Value;
    public IDriverVehicleRepository DriverVehicles => _driverVehicles.Value;
    public IDriverReviewRepository DriverReviews => _driverReviews.Value;
    public IShipmentStatusHistoryRepository ShipmentStatusHistories => _shipmentStatusHistories.Value;
    public IInvoiceRepository Invoices => _invoices.Value;
    public ITraderPaymentCardRepository TraderPaymentCards => _traderPaymentCards.Value;
    public ITraderWalletRepository TraderWallets => _traderWallets.Value;

    public IDriverNotificationPreferenceRepository DriverNotificationPreferences => _notif.Value;
    public IDriverPrivacySettingRepository DriverPrivacySettings => _privacy.Value;
    public IDriverAuditLogRepository DriverAuditLogs => _audit.Value;
    public ILegalDocumentRepository LegalDocuments => _legal.Value;

    public ITraderProfileRepository Traders => _traders.Value;

    public ITraderNotificationPreferenceRepository TraderNotificationPreferences => _traderNotif.Value;

    public ITraderPrivacySettingRepository TraderPrivacySettings => _traderPrivacy.Value;

    public ITraderAuditLogRepository TraderAuditLogs => _traderAudit.Value;

    public ITripRequestRepository TripRequests => _tripRequests.Value;

    public Task<bool> EmailInUseExceptUserAsync(string normalizedEmail, int excludeUserId,
        CancellationToken cancellationToken) =>
        _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail && u.Id != excludeUserId,
            cancellationToken);

    public Task<bool> PhoneInUseExceptUserAsync(string phone, int excludeUserId,
        CancellationToken cancellationToken) =>
        _context.Users.AnyAsync(u => u.Phone == phone && u.Id != excludeUserId,
            cancellationToken);

    public Task<bool> TraderHasBlockingShipmentsAsync(int traderPkId, CancellationToken cancellationToken) =>
        _context.ShipmentRequests.AsNoTracking().AnyAsync(s =>
                s.TraderId == traderPkId &&
                (s.Status == ShipmentStatus.Pending || s.Status == ShipmentStatus.Scheduled ||
                 s.Status == ShipmentStatus.Accepted || s.Status == ShipmentStatus.InProgress),
            cancellationToken);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _context.SaveChangesAsync(cancellationToken);
}
