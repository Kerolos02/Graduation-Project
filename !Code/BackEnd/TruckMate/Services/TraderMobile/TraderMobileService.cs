using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using TruckMate.API.Services;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Core.TraderMobile.Dtos;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.DriverHome;
using TruckMate.Services.Notifications;

namespace TruckMate.Services.TraderMobile;

public class TraderMobileService : ITraderMobileService
{
    private readonly IUnitOfWork _uow;
    private readonly IPricingService _pricingService;
    private readonly ITripDispatchService _tripDispatchService;
    private readonly IPaymentGatewayService _paymentGateway;
    private readonly ICancellationFeeService _cancellationFeeService;
    private readonly ITraderRealtimePublisher _realtime;
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _configuration;
    private readonly ILogger<TraderMobileService> _logger;

    public TraderMobileService(IUnitOfWork uow, IPricingService pricingService, ITripDispatchService tripDispatchService,
        IPaymentGatewayService paymentGateway, ICancellationFeeService cancellationFeeService,
        ITraderRealtimePublisher realtime, IEmailService emailService, ISmsService smsService, IMemoryCache cache,
        IConfiguration configuration, ILogger<TraderMobileService> logger)
    {
        _uow = uow;
        _pricingService = pricingService;
        _tripDispatchService = tripDispatchService;
        _paymentGateway = paymentGateway;
        _cancellationFeeService = cancellationFeeService;
        _realtime = realtime;
        _emailService = emailService;
        _smsService = smsService;
        _cache = cache;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<TraderHomeCurrentShipmentResponseDto> GetHomeCurrentShipmentAsync(Guid traderId,
        CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByPublicIdWithUserAsync(traderId, cancellationToken).ConfigureAwait(false)
                     ?? throw new KeyNotFoundException("Trader not found.");
        var shipments = await _uow.DeliveryTrips.Query()
            .Include(x => x.Trader)
            .Include(x => x.AssignedDriver)!.ThenInclude(d => d!.User)
            .Where(x => x.Trader.PublicId == traderId)
            .OrderByDescending(x => x.OfferedAtUtc)
            .Take(20)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
        var current = shipments.FirstOrDefault(x => x.Status is CourierTripStatus.Assigned or CourierTripStatus.InProgress);
        var completed = shipments.Where(x => x.Status == CourierTripStatus.Completed).ToList();
        var avgCost = completed.Any() ? completed.Average(x => x.PaymentAmountEGP) : 0m;

        return new TraderHomeCurrentShipmentResponseDto
        {
            TraderName = trader.User.FullName,
            CurrentShipment = current == null
                ? null
                : new CurrentShipmentCardDto
                {
                    ShipmentId = current.Id,
                    ShipmentNumber = current.ShipmentNumber,
                    Status = MapTraderStatus(current).ToString(),
                    RouteFrom = current.PickupLocation,
                    RouteTo = current.DropoffLocation,
                    DriverName = current.AssignedDriver?.User.FullName ?? "Pending assignment",
                    TotalCostEGP = decimal.Round(current.PaymentAmountEGP, 2)
                },
            QuickInsights = new TraderQuickInsightsDto
            {
                AvgTimeHours = 4.2m,
                AvgCostEGP = decimal.Round(avgCost, 2),
                CompletedShipments = completed.Count
            },
            RecentActivity = shipments.Take(5).Select(x => new TraderRecentActivityDto
            {
                ShipmentId = x.Id,
                Route = $"{x.PickupLocation} \u2192 {x.DropoffLocation}",
                DateLabel = x.OfferedAtUtc.ToString("MMM dd", CultureInfo.InvariantCulture),
                Status = MapTraderStatus(x).ToString()
            }).ToList()
        };
    }

    public async Task<TraderShipmentDetailsResponseDto> GetShipmentDetailsAsync(Guid traderId, Guid shipmentId,
        CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        var history = await _uow.ShipmentStatusHistories.GetByShipmentIdAsync(shipmentId, cancellationToken).ConfigureAwait(false);
        Driver? driver = null;
        DriverVehicle? vehicle = null;
        if (shipment.AssignedDriverId.HasValue)
        {
            driver = await _uow.Drivers.Query().Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == shipment.AssignedDriverId.Value, cancellationToken)
                .ConfigureAwait(false);
            if (driver != null)
            {
                vehicle = await _uow.DriverVehicles.GetByDriverIdAsync(driver.PublicId, cancellationToken).ConfigureAwait(false);
            }
        }

        return new TraderShipmentDetailsResponseDto
        {
            ShipmentId = shipment.Id,
            ShipmentNumber = shipment.ShipmentNumber,
            Status = MapTraderStatus(shipment).ToString(),
            Timeline = BuildTimeline(shipment, history),
            RouteFrom = shipment.PickupLocation,
            RouteTo = shipment.DropoffLocation,
            DateLabel = shipment.DateUtc.ToString("yyyy-MM-dd"),
            TimeLabel = shipment.DateUtc.ToString("HH:mm"),
            PackagesCount = shipment.PackagesCount,
            WeightLbs = decimal.Round(shipment.TotalWeightLbs, 2),
            Driver = new ShipmentDetailsDriverDto
            {
                DriverId = driver?.PublicId,
                DriverName = driver?.User.FullName ?? "Pending Assignment",
                Type = vehicle?.Type.ToString() ?? driver?.VehicleType.ToString() ?? "TBD",
                Model = vehicle?.Model ?? "TBD",
                LicensePlate = vehicle?.LicensePlate ?? "TBD"
            },
            TotalCostEGP = decimal.Round(shipment.PaymentAmountEGP, 2)
        };
    }

    public async Task<DriverOffersResponseDto> GetShipmentOffersAsync(Guid traderId, Guid shipmentId, string tab, int page,
        int pageSize, CancellationToken cancellationToken)
    {
        _ = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        var normalizedTab = string.IsNullOrWhiteSpace(tab) ? "pending" : tab.Trim().ToLowerInvariant();
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 50);
        var skip = (safePage - 1) * safePageSize;
        var status = normalizedTab switch
        {
            "accepted" => TripOfferStatus.Accepted,
            "rejected" => TripOfferStatus.Declined,
            _ => TripOfferStatus.Pending
        };

        var offers = await _uow.TripOffers.Query()
            .Include(x => x.Driver).ThenInclude(d => d.User)
            .Where(x => x.TripId == shipmentId && x.Status == status)
            .OrderByDescending(x => x.OfferedAtUtc)
            .Skip(skip)
            .Take(safePageSize)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
        var total = await _uow.TripOffers.Query().CountAsync(x => x.TripId == shipmentId && x.Status == status, cancellationToken)
            .ConfigureAwait(false);

        return new DriverOffersResponseDto
        {
            ShipmentId = shipmentId,
            Tab = normalizedTab,
            TotalCount = total,
            Offers = offers.Select(x => new DriverOfferItemDto
            {
                OfferId = x.Id,
                DriverId = x.Driver.PublicId,
                DriverName = x.Driver.User.FullName,
                Initials = BuildInitials(x.Driver.User.FullName),
                Rating = decimal.Round(x.Driver.Rating, 2),
                ReviewCount = x.Driver.ReviewCount,
                VehicleTypeLabel = VehicleTypeLabel(x.Driver.VehicleType),
                OfferPriceEGP = decimal.Round(x.Trip.PaymentAmountEGP, 2),
                EtaMinutes = Math.Max(1, x.Trip.EstimatedDurationMinutes),
                Status = normalizedTab
            }).ToList()
        };
    }

    public async Task AcceptOfferAsync(Guid traderId, Guid offerId, CancellationToken cancellationToken)
    {
        var offer = await _uow.TripOffers.GetByIdTrackedAsync(offerId, cancellationToken).ConfigureAwait(false)
                    ?? throw new KeyNotFoundException("Offer not found.");
        var shipment = await EnsureShipmentOwnershipAsync(traderId, offer.TripId, cancellationToken).ConfigureAwait(false);
        if (offer.Status != TripOfferStatus.Pending)
        {
            throw new InvalidOperationException("Offer is already processed.");
        }

        await _tripDispatchService.AssignDriverToShipmentAsync(shipment.Id, offer.Driver.PublicId, cancellationToken)
            .ConfigureAwait(false);
        offer.Status = TripOfferStatus.Accepted;
        offer.RespondedAtUtc = DateTime.UtcNow;
        await _uow.TripOffers.MarkPendingByTripAsCancelledAsync(shipment.Id, offer.Id, "AssignedToOther", DateTime.UtcNow,
            cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    public async Task RejectOfferAsync(Guid traderId, Guid offerId, CancellationToken cancellationToken)
    {
        var offer = await _uow.TripOffers.GetByIdTrackedAsync(offerId, cancellationToken).ConfigureAwait(false)
                    ?? throw new KeyNotFoundException("Offer not found.");
        _ = await EnsureShipmentOwnershipAsync(traderId, offer.TripId, cancellationToken).ConfigureAwait(false);
        if (offer.Status != TripOfferStatus.Pending)
        {
            throw new InvalidOperationException("Offer is already processed.");
        }

        offer.Status = TripOfferStatus.Declined;
        offer.RespondedAtUtc = DateTime.UtcNow;
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    public async Task<SuggestedDriversResponseDto> GetSuggestedDriversAsync(Guid traderId, Guid shipmentId, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 50);
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        var cacheKey = $"trader:suggested:{shipmentId}:{safePage}:{safePageSize}";
        if (_cache.TryGetValue(cacheKey, out SuggestedDriversResponseDto? cached) && cached != null)
        {
            return cached;
        }

        var onlineDrivers = await _uow.Drivers.Query()
            .Include(x => x.User)
            .Where(x => x.AvailabilityStatus == DriverAvailabilityStatus.Online && x.AssignedDeliveryTripId == null)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var scored = new List<(Driver driver, decimal distance, decimal total, decimal score)>();
        foreach (var driver in onlineDrivers)
        {
            if (!IsVehicleCompatible(driver.VehicleType, shipment.TotalWeightLbs))
            {
                continue;
            }

            var distance = ComputeDistanceKm(driver.LastKnownLatitude ?? shipment.PickupCoordinatesLat ?? 0d,
                driver.LastKnownLongitude ?? shipment.PickupCoordinatesLng ?? 0d,
                shipment.PickupCoordinatesLat ?? 0d,
                shipment.PickupCoordinatesLng ?? 0d);
            var total = await _pricingService
                .CalculateTripPriceAsync(shipment.DistanceKm, shipment.TotalWeightLbs, driver.VehicleType, cancellationToken)
                .ConfigureAwait(false);
            var distanceFactor = distance <= 0m ? 1m : (1m / distance);
            var score = (driver.Rating * 0.4m) + (distanceFactor * 0.4m) + ((driver.IsVerified ? 1m : 0m) * 0.2m);
            scored.Add((driver, distance, total, score));
        }

        var ordered = scored.OrderByDescending(x => x.score).ToList();
        var pageItems = ordered.Skip((safePage - 1) * safePageSize).Take(safePageSize).ToList();
        var response = new SuggestedDriversResponseDto
        {
            ShipmentId = shipmentId,
            AvailableCount = ordered.Count,
            Drivers = pageItems.Select((x, idx) => new SuggestedDriverItemDto
            {
                DriverId = x.driver.PublicId,
                FullName = x.driver.User.FullName,
                Initials = BuildInitials(x.driver.User.FullName),
                AvatarColor = x.driver.AvatarColor,
                IsBestMatch = (safePage == 1 && idx == 0),
                Rating = decimal.Round(x.driver.Rating, 2),
                ReviewCount = x.driver.ReviewCount,
                DistanceKm = decimal.Round(x.distance, 1),
                VehicleType = x.driver.VehicleType.ToString(),
                VehicleTypeLabel = VehicleTypeLabel(x.driver.VehicleType),
                TotalCostEGP = decimal.Round(x.total, 2),
                IsVerified = x.driver.IsVerified
            }).ToList()
        };

        _cache.Set(cacheKey, response, TimeSpan.FromSeconds(30));
        return response;
    }

    public async Task<DriverDetailsResponseDto> GetDriverDetailsAsync(Guid traderId, Guid driverId, Guid? shipmentId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByPublicIdWithUserAsync(driverId, cancellationToken).ConfigureAwait(false)
                     ?? throw new KeyNotFoundException("Driver not found.");
        var vehicle = await _uow.DriverVehicles.GetByDriverIdAsync(driverId, cancellationToken).ConfigureAwait(false);
        var reviews = await _uow.DriverReviews.GetRecentByDriverAsync(driverId, 5, cancellationToken).ConfigureAwait(false);

        var contextShipment = shipmentId.HasValue
            ? await EnsureShipmentOwnershipAsync(traderId, shipmentId.Value, cancellationToken).ConfigureAwait(false)
            : null;
        var distance = contextShipment == null
            ? 0m
            : ComputeDistanceKm(driver.LastKnownLatitude ?? contextShipment.PickupCoordinatesLat ?? 0d,
                driver.LastKnownLongitude ?? contextShipment.PickupCoordinatesLng ?? 0d,
                contextShipment.PickupCoordinatesLat ?? 0d, contextShipment.PickupCoordinatesLng ?? 0d);
        var totalCost = contextShipment == null
            ? 0m
            : await _pricingService.CalculateTripPriceAsync(contextShipment.DistanceKm, contextShipment.TotalWeightLbs,
                driver.VehicleType, cancellationToken).ConfigureAwait(false);

        return new DriverDetailsResponseDto
        {
            DriverId = driver.PublicId,
            FullName = driver.User.FullName,
            Initials = BuildInitials(driver.User.FullName),
            AvatarColor = driver.AvatarColor,
            IsVerified = driver.IsVerified,
            Rating = decimal.Round(driver.Rating, 2),
            ReviewCount = driver.ReviewCount,
            TotalCostEGP = decimal.Round(totalCost, 2),
            TotalTrips = driver.TotalTrips,
            TotalYears = driver.TotalYears,
            DistanceKm = decimal.Round(distance, 1),
            Vehicle = new DriverVehicleDto
            {
                Type = vehicle?.Type.ToString() ?? driver.VehicleType.ToString(),
                Model = vehicle?.Model ?? driver.TruckType,
                LicensePlate = vehicle?.LicensePlate ?? driver.PlateNumber
            },
            RecentReviews = reviews.Select(x => new DriverRecentReviewDto
            {
                ReviewId = x.Id,
                TraderName = x.TraderName,
                Rating = x.Rating,
                Comment = x.Comment,
                ReviewedAt = x.ReviewedAt.ToString("MMM d, yyyy", CultureInfo.InvariantCulture)
            }).ToList()
        };
    }

    public async Task<SelectDriverResponseDto> SelectDriverAsync(Guid traderId, Guid shipmentId, Guid driverId,
        CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        if (shipment.Status != CourierTripStatus.Pending && shipment.Status != CourierTripStatus.Offered)
        {
            throw new InvalidOperationException("Shipment is not pending.");
        }

        await _tripDispatchService.AssignDriverToShipmentAsync(shipmentId, driverId, cancellationToken).ConfigureAwait(false);
        var driver = await _uow.Drivers.GetByPublicIdWithUserAsync(driverId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver not found.");

        var basePrice = await _pricingService
            .CalculateTripPriceAsync(shipment.DistanceKm, shipment.TotalWeightLbs, driver.VehicleType, cancellationToken)
            .ConfigureAwait(false);
        var subtotal = basePrice / 1.16m;
        var serviceFee = subtotal * 0.08m;
        var tax = subtotal * 0.08m;
        var invoice = new Invoice
        {
            Id = Guid.NewGuid(),
            InvoiceNumber = $"INV-{DateTime.UtcNow:yyyy}-{Random.Shared.Next(1000, 9999)}-{Random.Shared.Next(100, 999)}",
            ShipmentId = shipment.Id,
            TraderId = traderId,
            DriverId = driverId,
            InvoiceDate = DateTime.UtcNow,
            BasePriceEGP = decimal.Round(subtotal, 2),
            ServiceFeeEGP = decimal.Round(serviceFee, 2),
            TaxEGP = decimal.Round(tax, 2),
            TotalAmountEGP = decimal.Round(basePrice, 2),
            Status = InvoiceStatus.Unpaid
        };
        await _uow.Invoices.AddAsync(invoice, cancellationToken).ConfigureAwait(false);

        await _uow.ShipmentStatusHistories.AddAsync(new ShipmentStatusHistory
        {
            Id = Guid.NewGuid(),
            ShipmentId = shipment.Id,
            Status = TraderShipmentStatus.Assigned,
            OccurredAt = DateTime.UtcNow
        }, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return new SelectDriverResponseDto
        {
            ShipmentId = shipmentId,
            DriverId = driverId,
            DriverName = driver.User.FullName,
            EstimatedPickupAt = DateTime.UtcNow.AddMinutes(30),
            InvoiceId = invoice.Id
        };
    }

    public async Task<ShipmentTrackingResponseDto> GetTrackingAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        if (shipment.Status == CourierTripStatus.Cancelled)
        {
            throw new OperationCanceledException("Shipment cancelled.");
        }

        var history = await _uow.ShipmentStatusHistories.GetByShipmentIdAsync(shipmentId, cancellationToken).ConfigureAwait(false);
        var currentStatus = MapTraderStatus(shipment);
        var statusLabel = StatusLabel(currentStatus);
        var remaining = ComputeEtaMinutes(shipment);
        var timeline = BuildTimeline(shipment, history);
        var driver = shipment.AssignedDriverId.HasValue
            ? await _uow.Drivers.Query().AsNoTracking().FirstOrDefaultAsync(x => x.Id == shipment.AssignedDriverId.Value, cancellationToken)
                .ConfigureAwait(false)
            : null;

        return new ShipmentTrackingResponseDto
        {
            ShipmentId = shipment.Id,
            ShipmentNumber = shipment.ShipmentNumber,
            Status = currentStatus.ToString(),
            StatusLabel = statusLabel,
            EstimatedTimeRemainingMinutes = remaining,
            DriverLocation = new DriverLocationDto
            {
                Lat = driver?.LastKnownLatitude ?? 0d,
                Lng = driver?.LastKnownLongitude ?? 0d,
                LastUpdatedAt = driver?.LastLocationUpdatedAtUtc
            },
            Route = new TrackingRouteDto
            {
                PickupLat = shipment.PickupCoordinatesLat ?? 0d,
                PickupLng = shipment.PickupCoordinatesLng ?? 0d,
                DropoffLat = shipment.DropoffCoordinatesLat ?? 0d,
                DropoffLng = shipment.DropoffCoordinatesLng ?? 0d
            },
            Timeline = timeline,
            Actions = new TrackingActionsDto
            {
                CanMarkDelivered = currentStatus == TraderShipmentStatus.InTransit,
                CanCancelShipment = currentStatus != TraderShipmentStatus.Delivered &&
                                   currentStatus != TraderShipmentStatus.Cancelled
            }
        };
    }

    public async Task<DateTime> MarkDeliveredAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        if (MapTraderStatus(shipment) != TraderShipmentStatus.InTransit)
        {
            throw new InvalidOperationException("Shipment must be InTransit.");
        }

        var deliveredAt = DateTime.UtcNow;
        shipment.Status = CourierTripStatus.Completed;
        shipment.CompletedAtUtc = deliveredAt;
        await _uow.ShipmentStatusHistories.AddAsync(new ShipmentStatusHistory
        {
            Id = Guid.NewGuid(),
            ShipmentId = shipmentId,
            Status = TraderShipmentStatus.Delivered,
            OccurredAt = deliveredAt
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _realtime.PublishShipmentStatusUpdatedAsync(traderId, shipmentId, "Delivered", deliveredAt, cancellationToken)
            .ConfigureAwait(false);
        await _realtime.PublishDeliveryConfirmedAsync(traderId, shipmentId, deliveredAt, cancellationToken)
            .ConfigureAwait(false);
        return deliveredAt;
    }

    public async Task CancelShipmentAsync(Guid traderId, Guid shipmentId, string? reason, CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        var status = MapTraderStatus(shipment);
        if (status is TraderShipmentStatus.Delivered or TraderShipmentStatus.Cancelled)
        {
            throw new InvalidOperationException("Shipment cannot be cancelled.");
        }

        if (status is TraderShipmentStatus.Assigned or TraderShipmentStatus.PickedUp)
        {
            _ = await _cancellationFeeService.CalculateFeeAsync(shipmentId, cancellationToken).ConfigureAwait(false);
        }

        shipment.Status = CourierTripStatus.Cancelled;
        shipment.CancelledAtUtc = DateTime.UtcNow;
        if (shipment.AssignedDriverId.HasValue)
        {
            var driver = await _uow.Drivers.Query()
                .FirstOrDefaultAsync(x => x.Id == shipment.AssignedDriverId.Value, cancellationToken)
                .ConfigureAwait(false);
            if (driver != null)
            {
                driver.AssignedDeliveryTripId = null;
            }
        }

        await _uow.ShipmentStatusHistories.AddAsync(new ShipmentStatusHistory
        {
            Id = Guid.NewGuid(),
            ShipmentId = shipmentId,
            Status = TraderShipmentStatus.Cancelled,
            OccurredAt = DateTime.UtcNow,
            Note = reason
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _realtime.PublishShipmentStatusUpdatedAsync(traderId, shipmentId, "Cancelled", DateTime.UtcNow, cancellationToken)
            .ConfigureAwait(false);
    }

    public async Task<DeliverySummaryResponseDto> GetDeliverySummaryAsync(Guid traderId, Guid shipmentId,
        CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        if (shipment.CompletedAtUtc is null)
        {
            throw new InvalidOperationException("Shipment is not delivered.");
        }

        var driver = shipment.AssignedDriverId.HasValue
            ? await _uow.Drivers.Query().Include(x => x.User)
                .FirstAsync(x => x.Id == shipment.AssignedDriverId.Value, cancellationToken)
                .ConfigureAwait(false)
            : throw new InvalidOperationException("Shipment has no driver.");
        var invoice = await _uow.Invoices.GetByShipmentIdAsync(shipmentId, cancellationToken).ConfigureAwait(false)
                      ?? throw new KeyNotFoundException("Invoice not found.");
        var hasRated = await _uow.DriverReviews.ExistsForTripAndTraderAsync(shipmentId, traderId, cancellationToken)
            .ConfigureAwait(false);

        return new DeliverySummaryResponseDto
        {
            ShipmentId = shipmentId,
            ShipmentNumber = shipment.ShipmentNumber,
            DeliveredAt = DateTime.SpecifyKind(shipment.CompletedAtUtc.Value, DateTimeKind.Utc),
            DeliveredAtFormatted = $"Delivered at {shipment.CompletedAtUtc.Value.ToString("h:mm tt", CultureInfo.InvariantCulture)}",
            From = shipment.PickupLocation,
            To = shipment.DropoffLocation,
            Driver = new DeliveryDriverDto
            {
                DriverId = driver.PublicId,
                FullName = driver.User.FullName,
                Initials = BuildInitials(driver.User.FullName),
                AvatarColor = driver.AvatarColor,
                HasBeenRated = hasRated
            },
            InvoiceId = invoice.Id,
            CanRate = !hasRated
        };
    }

    public async Task RateDriverAsync(Guid traderId, Guid shipmentId, int rating, string? comment, CancellationToken cancellationToken)
    {
        var shipment = await EnsureShipmentOwnershipAsync(traderId, shipmentId, cancellationToken).ConfigureAwait(false);
        if (shipment.CompletedAtUtc is null)
        {
            throw new InvalidOperationException("Shipment must be delivered.");
        }

        if (await _uow.DriverReviews.ExistsForTripAndTraderAsync(shipmentId, traderId, cancellationToken).ConfigureAwait(false))
        {
            throw new DbUpdateException("Duplicate rating.");
        }

        var trader = await _uow.Traders.GetByPublicIdWithUserAsync(traderId, cancellationToken).ConfigureAwait(false)
                     ?? throw new KeyNotFoundException("Trader not found.");
        var driver = shipment.AssignedDriverId.HasValue
            ? await _uow.Drivers.Query().FirstAsync(x => x.Id == shipment.AssignedDriverId.Value, cancellationToken)
                .ConfigureAwait(false)
            : throw new InvalidOperationException("Shipment has no driver.");

        await _uow.DriverReviews.AddAsync(new DriverReview
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driver.PublicId,
            TraderPublicId = traderId,
            TraderName = trader.User.FullName,
            Rating = rating,
            Comment = comment,
            ReviewedAt = DateTime.UtcNow,
            TripId = shipmentId
        }, cancellationToken).ConfigureAwait(false);
        var (average, count) = await _uow.DriverReviews.GetDriverRatingStatsAsync(driver.PublicId, cancellationToken)
            .ConfigureAwait(false);
        driver.Rating = average;
        driver.ReviewCount = count;

        await _uow.TraderAuditLogs.AddAsync(new TraderAuditLog
        {
            Id = Guid.NewGuid(),
            TraderPublicId = traderId,
            Action = "DriverRated",
            PerformedAtUtc = DateTime.UtcNow,
            IpAddress = "api",
            UserAgent = "mobile",
            AdditionalData = $"shipmentId={shipmentId};driverId={driver.PublicId};rating={rating}"
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    public async Task<InvoiceDetailsResponseDto> GetInvoiceDetailsAsync(Guid traderId, Guid invoiceId,
        CancellationToken cancellationToken)
    {
        var invoice = await _uow.Invoices.GetByIdForTraderAsync(invoiceId, traderId, cancellationToken).ConfigureAwait(false)
                      ?? throw new KeyNotFoundException("Invoice not found.");
        var vehicle = await _uow.DriverVehicles.GetByDriverIdAsync(invoice.DriverId, cancellationToken).ConfigureAwait(false);
        return MapInvoice(invoice, vehicle);
    }

    public async Task<(DateTime paidAt, string paidWith)> PayInvoiceAsync(Guid traderId, Guid invoiceId, Guid cardId,
        CancellationToken cancellationToken)
    {
        var invoice = await _uow.Invoices.GetByIdForTraderAsync(invoiceId, traderId, cancellationToken).ConfigureAwait(false)
                      ?? throw new KeyNotFoundException("Invoice not found.");
        if (invoice.Status != InvoiceStatus.Unpaid)
        {
            throw new InvalidOperationException("Invoice already paid.");
        }

        var card = await _uow.TraderPaymentCards.GetByIdForTraderAsync(cardId, traderId, cancellationToken)
                   .ConfigureAwait(false)
                   ?? throw new KeyNotFoundException("Payment card not found.");
        await _paymentGateway.ChargeAsync(card.TokenizedCardId, invoice.TotalAmountEGP, cancellationToken).ConfigureAwait(false);

        var paidAt = DateTime.UtcNow;
        var paidWith = $"{card.CardBrand} **** {card.Last4Digits}";
        invoice.Status = InvoiceStatus.Paid;
        invoice.PaidAt = paidAt;
        invoice.PaymentMethod = paidWith;

        var wallet = await _uow.TraderWallets.GetByTraderIdAsync(traderId, cancellationToken).ConfigureAwait(false);
        if (wallet == null)
        {
            wallet = new TraderWallet
            {
                Id = Guid.NewGuid(),
                TraderId = traderId,
                BalanceEGP = 0m,
                TotalSpentEGP = 0m,
                LastUpdatedAt = DateTime.UtcNow
            };
            await _uow.TraderWallets.AddAsync(wallet, cancellationToken).ConfigureAwait(false);
        }

        wallet.BalanceEGP = decimal.Round(wallet.BalanceEGP - invoice.TotalAmountEGP, 2);
        wallet.TotalSpentEGP = decimal.Round(wallet.TotalSpentEGP + invoice.TotalAmountEGP, 2);
        wallet.LastUpdatedAt = DateTime.UtcNow;

        await _uow.TraderAuditLogs.AddAsync(new TraderAuditLog
        {
            Id = Guid.NewGuid(),
            TraderPublicId = traderId,
            Action = "InvoicePaid",
            PerformedAtUtc = paidAt,
            IpAddress = "api",
            UserAgent = "mobile",
            AdditionalData = $"invoiceId={invoiceId};amount={invoice.TotalAmountEGP};method={paidWith}"
        }, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var trader = await _uow.Traders.GetByPublicIdWithUserAsync(traderId, cancellationToken).ConfigureAwait(false);
        if (trader != null)
        {
            await _emailService.SendAsync(trader.User.Email, "Payment successful",
                $"Invoice {invoice.InvoiceNumber} was paid successfully via {paidWith}.", cancellationToken).ConfigureAwait(false);
        }

        await _realtime.PublishInvoicePaidAsync(traderId, invoiceId, paidAt, paidWith, cancellationToken).ConfigureAwait(false);
        return (paidAt, paidWith);
    }

    public async Task<byte[]> GenerateInvoicePdfAsync(Guid traderId, Guid invoiceId, CancellationToken cancellationToken)
    {
        var invoice = await _uow.Invoices.GetByIdForTraderAsync(invoiceId, traderId, cancellationToken).ConfigureAwait(false)
                      ?? throw new KeyNotFoundException("Invoice not found.");
        var vehicle = await _uow.DriverVehicles.GetByDriverIdAsync(invoice.DriverId, cancellationToken).ConfigureAwait(false);

        QuestPDF.Settings.License = LicenseType.Community;
        var bytes = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Margin(20);
                page.Header().Text("TruckMate Invoice").FontSize(20).Bold();
                page.Content().Column(col =>
                {
                    col.Spacing(6);
                    col.Item().Text($"Invoice: {invoice.InvoiceNumber}");
                    col.Item().Text($"Date: {invoice.InvoiceDate:u}");
                    col.Item().Text($"Shipment: {invoice.Shipment.ShipmentNumber}");
                    col.Item().Text($"Route: {invoice.Shipment.PickupLocation} -> {invoice.Shipment.DropoffLocation}");
                    col.Item().Text($"Distance: {invoice.Shipment.DistanceKm:0.##} km");
                    col.Item().Text($"Packages: {invoice.Shipment.PackagesCount}");
                    col.Item().Text($"Weight: {invoice.Shipment.TotalWeightLbs:0.##} lbs");
                    col.Item().Text($"Driver: {invoice.Driver.User.FullName}");
                    col.Item().Text($"Vehicle: {vehicle?.Type.ToString() ?? invoice.Driver.VehicleType.ToString()}");
                    col.Item().Text($"License: {vehicle?.LicensePlate ?? invoice.Driver.PlateNumber}");
                    col.Item().Text($"Base: {invoice.BasePriceEGP:0.00} EGP");
                    col.Item().Text($"Service Fee: {invoice.ServiceFeeEGP:0.00} EGP");
                    col.Item().Text($"Tax: {invoice.TaxEGP:0.00} EGP");
                    col.Item().Text($"Total: {invoice.TotalAmountEGP:0.00} EGP").Bold();
                });
            });
        }).GeneratePdf();
        return await Task.FromResult(bytes).ConfigureAwait(false);
    }

    public async Task<string> ShareInvoiceAsync(Guid traderId, Guid invoiceId, string method, CancellationToken cancellationToken)
    {
        var invoice = await _uow.Invoices.GetByIdForTraderAsync(invoiceId, traderId, cancellationToken).ConfigureAwait(false)
                      ?? throw new KeyNotFoundException("Invoice not found.");
        var trader = await _uow.Traders.GetByPublicIdWithUserAsync(traderId, cancellationToken).ConfigureAwait(false)
                     ?? throw new KeyNotFoundException("Trader not found.");
        var normalized = method.Trim().ToLowerInvariant();
        if (normalized == "email")
        {
            await _emailService.SendAsync(trader.User.Email, "Invoice shared",
                $"Invoice {invoice.InvoiceNumber} is attached/available in your account.", cancellationToken).ConfigureAwait(false);
            return "shared_by_email";
        }

        if (normalized == "sms")
        {
            await _smsService.SendPhoneOtpAsync(trader.User.Phone, $"Invoice link: /api/trader/invoices/{invoiceId}/pdf",
                cancellationToken).ConfigureAwait(false);
            return "shared_by_sms";
        }

        var exp = DateTime.UtcNow.AddHours(24);
        var payload = $"{invoiceId:D}|{exp:O}";
        var secret = _configuration["InvoiceShare:Secret"] ?? "truckmate-invoice-secret";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var signature = Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(payload)));
        return $"/api/trader/invoices/{invoiceId}/pdf?exp={Uri.EscapeDataString(exp.ToString("O"))}&sig={signature}";
    }

    public async Task<TraderWalletResponseDto> GetWalletAsync(Guid traderId, CancellationToken cancellationToken)
    {
        var wallet = await _uow.TraderWallets.GetByTraderIdAsync(traderId, cancellationToken).ConfigureAwait(false);
        if (wallet == null)
        {
            wallet = new TraderWallet
            {
                Id = Guid.NewGuid(),
                TraderId = traderId,
                BalanceEGP = 0m,
                TotalSpentEGP = 0m,
                LastUpdatedAt = DateTime.UtcNow
            };
            await _uow.TraderWallets.AddAsync(wallet, cancellationToken).ConfigureAwait(false);
            await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        }

        var cards = await _uow.TraderPaymentCards.GetByTraderIdAsync(traderId, cancellationToken).ConfigureAwait(false);
        return new TraderWalletResponseDto
        {
            BalanceEGP = decimal.Round(wallet.BalanceEGP, 2),
            TotalSpentEGP = decimal.Round(wallet.TotalSpentEGP, 2),
            SavedCards = cards.Select(x => new SavedCardDto
            {
                CardId = x.Id,
                CardBrand = x.CardBrand.ToString(),
                Last4Digits = x.Last4Digits,
                ExpiryMonth = x.ExpiryMonth,
                ExpiryYear = x.ExpiryYear,
                IsDefault = x.IsDefault,
                CardBrandLogoUrl = $"/assets/card/{x.CardBrand.ToString().ToLowerInvariant()}.png"
            }).ToList()
        };
    }

    public async Task<SavedCardDto> AddCardAsync(Guid traderId, AddCardRequestDto request, CancellationToken cancellationToken)
    {
        var token = await _paymentGateway.TokenizeCardAsync(request.CardNumber, request.ExpiryMonth, request.ExpiryYear, request.Cvv,
            cancellationToken).ConfigureAwait(false);
        var anyCards = await _uow.TraderPaymentCards.AnyByTraderAsync(traderId, cancellationToken).ConfigureAwait(false);
        var card = new TraderPaymentCard
        {
            Id = Guid.NewGuid(),
            TraderId = traderId,
            CardHolderName = request.CardHolderName,
            Last4Digits = request.CardNumber[^4..],
            CardBrand = DetectBrand(request.CardNumber),
            ExpiryMonth = request.ExpiryMonth,
            ExpiryYear = request.ExpiryYear,
            IsDefault = !anyCards,
            TokenizedCardId = token,
            CreatedAt = DateTime.UtcNow
        };
        await _uow.TraderPaymentCards.AddAsync(card, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return new SavedCardDto
        {
            CardId = card.Id,
            CardBrand = card.CardBrand.ToString(),
            Last4Digits = card.Last4Digits,
            ExpiryMonth = card.ExpiryMonth,
            ExpiryYear = card.ExpiryYear,
            IsDefault = card.IsDefault,
            CardBrandLogoUrl = $"/assets/card/{card.CardBrand.ToString().ToLowerInvariant()}.png"
        };
    }

    public async Task DeleteCardAsync(Guid traderId, Guid cardId, CancellationToken cancellationToken)
    {
        var card = await _uow.TraderPaymentCards.GetByIdForTraderAsync(cardId, traderId, cancellationToken).ConfigureAwait(false)
                   ?? throw new KeyNotFoundException("Card not found.");
        var cards = await _uow.TraderPaymentCards.GetByTraderIdAsync(traderId, cancellationToken).ConfigureAwait(false);
        if (card.IsDefault && cards.Count > 1)
        {
            throw new InvalidOperationException("Cannot delete default card. Set another card as default first.");
        }

        _uow.TraderPaymentCards.Remove(card);
        await _paymentGateway.DeleteTokenAsync(card.TokenizedCardId, cancellationToken).ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    public async Task SetDefaultCardAsync(Guid traderId, Guid cardId, CancellationToken cancellationToken)
    {
        var cards = await _uow.TraderPaymentCards.GetByTraderIdAsync(traderId, cancellationToken).ConfigureAwait(false);
        var target = cards.FirstOrDefault(x => x.Id == cardId) ?? throw new KeyNotFoundException("Card not found.");
        foreach (var card in cards)
        {
            var tracked = await _uow.TraderPaymentCards.GetByIdForTraderAsync(card.Id, traderId, cancellationToken)
                .ConfigureAwait(false);
            if (tracked != null)
            {
                tracked.IsDefault = card.Id == target.Id;
            }
        }

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task<DeliveryTrip> EnsureShipmentOwnershipAsync(Guid traderId, Guid shipmentId, CancellationToken cancellationToken)
    {
        var shipment = await _uow.DeliveryTrips.GetByIdForTraderAsync(shipmentId, traderId, cancellationToken).ConfigureAwait(false);
        if (shipment == null)
        {
            throw new KeyNotFoundException("Shipment not found.");
        }

        return shipment;
    }

    private static bool IsVehicleCompatible(VehicleType type, decimal weightLbs) =>
        type switch
        {
            VehicleType.Van => weightLbs <= 400m,
            VehicleType.PickupTruck => weightLbs <= 1200m,
            VehicleType.BoxTruck => weightLbs <= 3000m,
            VehicleType.Truck => true,
            _ => true
        };

    private static decimal ComputeDistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double r = 6371d;
        var dLat = ToRad(lat2 - lat1);
        var dLon = ToRad(lon2 - lon1);
        var a = Math.Sin(dLat / 2d) * Math.Sin(dLat / 2d) +
                Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2)) *
                Math.Sin(dLon / 2d) * Math.Sin(dLon / 2d);
        var c = 2d * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1d - a));
        return decimal.Round((decimal)(r * c), 2);
    }

    private static double ToRad(double value) => value * Math.PI / 180d;

    private static string BuildInitials(string fullName)
    {
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "NA";
        if (parts.Length == 1) return parts[0][..Math.Min(2, parts[0].Length)].ToUpperInvariant();
        return $"{parts[0][0]}{parts[1][0]}".ToUpperInvariant();
    }

    private static string VehicleTypeLabel(VehicleType type) => type switch
    {
        VehicleType.PickupTruck => "Pickup Truck",
        VehicleType.BoxTruck => "Box Truck",
        _ => type.ToString()
    };

    private static TraderShipmentStatus MapTraderStatus(DeliveryTrip shipment)
    {
        return shipment.Status switch
        {
            CourierTripStatus.Pending or CourierTripStatus.Offered => TraderShipmentStatus.Pending,
            CourierTripStatus.Assigned => TraderShipmentStatus.Assigned,
            CourierTripStatus.InProgress when shipment.InTransitAtUtc.HasValue => TraderShipmentStatus.InTransit,
            CourierTripStatus.InProgress => TraderShipmentStatus.PickedUp,
            CourierTripStatus.Completed => TraderShipmentStatus.Delivered,
            CourierTripStatus.Cancelled => TraderShipmentStatus.Cancelled,
            _ => TraderShipmentStatus.Pending
        };
    }

    private static string StatusLabel(TraderShipmentStatus status) => status switch
    {
        TraderShipmentStatus.PickedUp => "Picked Up",
        TraderShipmentStatus.InTransit => "In Transit",
        _ => status.ToString()
    };

    private static int ComputeEtaMinutes(DeliveryTrip shipment)
    {
        if (!shipment.EstimatedDeliveryTimeUtc.HasValue)
        {
            return 0;
        }

        var mins = (int)Math.Ceiling((shipment.EstimatedDeliveryTimeUtc.Value - DateTime.UtcNow).TotalMinutes);
        return Math.Max(0, mins);
    }

    private static List<TrackingTimelineStepDto> BuildTimeline(DeliveryTrip shipment, IReadOnlyList<ShipmentStatusHistory> history)
    {
        var picked = history.FirstOrDefault(x => x.Status == TraderShipmentStatus.PickedUp)?.OccurredAt ?? shipment.PickedUpAtUtc;
        var transit = history.FirstOrDefault(x => x.Status == TraderShipmentStatus.InTransit)?.OccurredAt ?? shipment.InTransitAtUtc;
        var delivered = history.FirstOrDefault(x => x.Status == TraderShipmentStatus.Delivered)?.OccurredAt ?? shipment.CompletedAtUtc;
        return
        [
            BuildStep(1, "Picked Up", picked, transit == null && delivered == null),
            BuildStep(2, "In Transit", transit, delivered == null && transit != null),
            BuildStep(3, "Delivered", delivered, delivered != null)
        ];
    }

    private static TrackingTimelineStepDto BuildStep(int step, string label, DateTime? occurredAt, bool current)
    {
        string status;
        string description;
        if (occurredAt.HasValue && !current)
        {
            status = "Completed";
            var ago = DateTime.UtcNow - occurredAt.Value;
            description = ago.TotalMinutes < 1 ? "just now" : $"{Math.Floor(ago.TotalHours)} hours ago";
        }
        else if (current)
        {
            status = "Current";
            description = "Current status";
        }
        else
        {
            status = "Pending";
            description = "Pending";
        }

        return new TrackingTimelineStepDto
        {
            Step = step,
            Label = label,
            Description = description,
            Status = status,
            OccurredAt = occurredAt
        };
    }

    private static InvoiceDetailsResponseDto MapInvoice(Invoice invoice, DriverVehicle? vehicle) =>
        new()
        {
            InvoiceId = invoice.Id,
            InvoiceNumber = invoice.InvoiceNumber,
            InvoiceDate = invoice.InvoiceDate.ToString("MMM dd, yyyy • hh:mm tt", CultureInfo.InvariantCulture),
            ShipmentId = invoice.ShipmentId,
            ShipmentNumber = invoice.Shipment.ShipmentNumber,
            Route = new InvoiceRouteDto
            {
                PickupLocation = invoice.Shipment.PickupLocation,
                DropoffLocation = invoice.Shipment.DropoffLocation
            },
            ShipmentDetails = new InvoiceShipmentDetailsDto
            {
                DistanceKm = decimal.Round(invoice.Shipment.DistanceKm, 2),
                PackagesCount = invoice.Shipment.PackagesCount,
                TotalWeightLbs = decimal.Round(invoice.Shipment.TotalWeightLbs, 2)
            },
            Driver = new InvoiceDriverDto
            {
                FullName = invoice.Driver.User.FullName,
                VehicleType = vehicle?.Type.ToString() ?? invoice.Driver.VehicleType.ToString(),
                LicensePlate = vehicle?.LicensePlate ?? invoice.Driver.PlateNumber
            },
            Pricing = new InvoicePricingDto
            {
                BasePriceEGP = decimal.Round(invoice.BasePriceEGP, 2),
                ServiceFeeEGP = decimal.Round(invoice.ServiceFeeEGP, 2),
                TaxEGP = decimal.Round(invoice.TaxEGP, 2),
                TotalAmountEGP = decimal.Round(invoice.TotalAmountEGP, 2)
            },
            Status = invoice.Status.ToString(),
            PaidWith = invoice.PaymentMethod,
            CanPay = invoice.Status == InvoiceStatus.Unpaid,
            CanDownloadPdf = true,
            CanShare = true
        };

    private static CardBrand DetectBrand(string cardNumber)
    {
        return cardNumber[0] switch
        {
            '4' => CardBrand.Visa,
            '5' => CardBrand.Mastercard,
            '3' => CardBrand.Amex,
            _ => CardBrand.Visa
        };
    }
}
