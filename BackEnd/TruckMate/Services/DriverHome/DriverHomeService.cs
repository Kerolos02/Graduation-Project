using System.Globalization;
using AutoMapper;
using Microsoft.Extensions.Logging;
using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.DriverWallet;

namespace TruckMate.Services.DriverHome;

/// <summary>Aggregates driver home payloads and coordinates courier-trip transitions.</summary>
public class DriverHomeService : IDriverHomeService
{
    private readonly IUnitOfWork _uow;
    private readonly IMapper _mapper;
    private readonly IDriverRealtimePublisher _realtime;
    private readonly IDriverWalletService _walletService;
    private readonly ILogger<DriverHomeService> _logger;

    public DriverHomeService(IUnitOfWork uow, IMapper mapper,
        IDriverRealtimePublisher realtime, IDriverWalletService walletService, ILogger<DriverHomeService> logger)
    {
        _uow = uow;
        _mapper = mapper;
        _realtime = realtime;
        _walletService = walletService;
        _logger = logger;
    }

    public async Task<DriverHomeResponseDto> BuildHomePayloadAsync(int userId, CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var summary = await _uow.DriverDailySummaries
            .GetForDriverAndDateAsync(driver.Id, today, cancellationToken)
            .ConfigureAwait(false);

        var recentEntities = await _uow.DeliveryTrips.GetRecentCompletedAsync(driver.Id, 0, 5, cancellationToken)
            .ConfigureAwait(false);

        var dto = new DriverHomeResponseDto
        {
            DriverName = driver.User.FullName,
            Rating = driver.Rating,
            Status = FormatAvailability(driver.AvailabilityStatus),
            CurrentZone = driver.CurrentZone,
            TodaySummary = new TodaySummaryDto
            {
                TripsCompleted = summary?.TripsCompleted ?? 0,
                EarningsEGP = summary?.EarningsEGP ?? 0,
                OnlineTimeFormatted = FormatOnlineMinutes(summary?.OnlineTimeMinutes ?? 0)
            },
            RecentTrips = recentEntities.Select(MapRecentTrip).ToList()
        };

        if (driver.AssignedDeliveryTrip is { } assigned
            && (assigned.Status == CourierTripStatus.Assigned || assigned.Status == CourierTripStatus.InProgress))
        {
            if (assigned.CourierShipment == null)
            {
                throw new InvalidOperationException(
                    $"Courier shipment payload missing for trip {assigned.Id}."
                );
            }

            dto.ActiveTrip = MapActiveTrip(assigned);
        }

        _logger.LogDebug("Built driver home snapshot for driver db id {DriverId}", driver.Id);
        return dto;
    }

    public async Task<DriverStatusPatchResponse> UpdateAvailabilityAsync(int userId, string requestedStatus,
        CancellationToken cancellationToken)
    {
        var next = ParseAvailability(requestedStatus);
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        var prior = driver.AvailabilityStatus;

        if (prior == DriverAvailabilityStatus.Offline &&
            next == DriverAvailabilityStatus.Online)
        {
            driver.LastAvailabilityChangeUtc = DateTime.UtcNow;
        }

        driver.AvailabilityStatus = next;
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Driver db id {DriverId} availability {Prior} → {Next}", driver.Id, prior, next);

        await _realtime.PublishDriverAvailabilityChangedAsync(userId, FormatAvailability(next), cancellationToken)
            .ConfigureAwait(false);

        return new DriverStatusPatchResponse
        {
            Status = FormatAvailability(next),
            Message = next == DriverAvailabilityStatus.Online
                ? "You are now online."
                : "You are now offline."
        };
    }

    public async Task<DriverStatusPatchResponse?> TryApplySignalRStatusAsync(int userId, string requestedStatus,
        CancellationToken cancellationToken)
    {
        try
        {
            return await UpdateAvailabilityAsync(userId, requestedStatus, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "SignalR availability update rejected for user {UserId}", userId);
            return null;
        }
    }

    public async Task<IncomingTripsResponseDto> GetIncomingOffersAsync(int userId, CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online)
        {
            return new IncomingTripsResponseDto();
        }

        if (HasBlockingCourierAssignment(driver))
        {
            return new IncomingTripsResponseDto();
        }

        var offers = await _uow.DeliveryTrips.GetIncomingPendingForZoneAsync(driver.CurrentZone, cancellationToken)
            .ConfigureAwait(false);

        var dtos = offers.Select(static t =>
        {
            var ship = t.CourierShipment;

            return new IncomingTripOfferDto
            {
                TripId = t.Id,
                ShipmentNumber = t.ShipmentNumber,
                PickupLocation = t.PickupLocation,
                DropoffLocation = t.DropoffLocation,
                CargoType = ship?.CargoType ?? string.Empty,
                WeightLbs = ship?.WeightLbs ?? 0,
                IsFragile = ship?.IsFragile ?? false,
                OfferedAt = t.OfferedAtUtc
            };
        }).ToList();

        return new IncomingTripsResponseDto { Trips = dtos };
    }

    public async Task<StartTripResponseDto> StartAssignedTripAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        var trip =
            await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken)
                .ConfigureAwait(false);

        if (trip == null)
        {
            throw new InvalidOperationException("Trip could not be found.");
        }

        if (trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("Trip is not assigned to this driver.");
        }

        if (trip.Status != CourierTripStatus.Assigned)
        {
            throw new InvalidOperationException($"Trip cannot start while status is {trip.Status}.");
        }

        var startedUtc = DateTime.UtcNow;
        trip.Status = CourierTripStatus.InProgress;
        trip.StartedAtUtc = startedUtc;
        trip.ScheduledStartTime = startedUtc.TimeOfDay;

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Courier trip {TripId} started by driver db id {DriverId}", trip.Id, driver.Id);

        await _realtime.PublishTripStartedAsync(trip.Id, driver.Id, startedUtc, cancellationToken)
            .ConfigureAwait(false);

        return new StartTripResponseDto
        {
            TripId = trip.Id,
            Status = nameof(CourierTripStatus.InProgress),
            StartedAt = startedUtc
        };
    }

    public async Task<DriverTripExecutionScreenDto> GetTripExecutionScreenAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");
        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentAsync(tripId, cancellationToken).ConfigureAwait(false)
                   ?? throw new InvalidOperationException("Trip could not be found.");
        if (trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("Trip is not assigned to this driver.");
        }

        var state = ResolveExecutionState(trip);
        return new DriverTripExecutionScreenDto
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            ScreenState = state,
            Title = ResolveTitle(state),
            Subtitle = ResolveSubtitle(state),
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            DistanceKm = decimal.Round(trip.DistanceKm, 2),
            EtaMinutes = Math.Max(0, trip.EstimatedDurationMinutes),
            EtaFormatted = FormatDuration(trip.EstimatedDurationMinutes),
            Driver = new DriverTripExecutionDriverDto
            {
                Name = driver.User.FullName,
                Phone = driver.User.Phone
            },
            Shipment = new DriverTripExecutionShipmentDto
            {
                CargoType = trip.CourierShipment?.CargoType ?? "General",
                WeightLbs = trip.CourierShipment?.WeightLbs ?? 0m,
                PackagesCount = trip.PackagesCount <= 0 ? 1 : trip.PackagesCount
            },
            Actions = new DriverTripExecutionActionsDto
            {
                CanMarkArrived = state == "going_to_pickup",
                CanConfirmPickup = state == "arrived_at_pickup",
                CanStartDelivery = state == "pickup_confirmed",
                CanMarkDelivered = state == "in_transit",
                CanCompleteTrip = state == "delivered"
            }
        };
    }

    public async Task<StartTripResponseDto> MarkArrivedAtPickupAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var (driver, trip) = await GetDriverAndAssignedTripForUpdateAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
        if (trip.Status != CourierTripStatus.InProgress || trip.PickedUpAtUtc.HasValue)
        {
            throw new InvalidOperationException("Trip is not in a valid state for arrival.");
        }

        trip.ScheduleStatus = "Arrived at pickup";
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogInformation("Driver {DriverId} arrived at pickup for trip {TripId}", driver.Id, trip.Id);
        return BuildTripStatusResponse(trip.Id, "ArrivedAtPickup", DateTime.UtcNow);
    }

    public async Task<StartTripResponseDto> ConfirmPickupAsync(int userId, Guid tripId, CancellationToken cancellationToken)
    {
        var (driver, trip) = await GetDriverAndAssignedTripForUpdateAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
        if (trip.Status != CourierTripStatus.InProgress || trip.PickedUpAtUtc.HasValue)
        {
            throw new InvalidOperationException("Trip is not in a valid state for pickup confirmation.");
        }

        var now = DateTime.UtcNow;
        trip.PickedUpAtUtc = now;
        trip.ScheduleStatus = "Pickup confirmed";
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogInformation("Driver {DriverId} confirmed pickup for trip {TripId}", driver.Id, trip.Id);
        return BuildTripStatusResponse(trip.Id, "PickupConfirmed", now);
    }

    public async Task<StartTripResponseDto> StartDeliveryAsync(int userId, Guid tripId, CancellationToken cancellationToken)
    {
        var (driver, trip) = await GetDriverAndAssignedTripForUpdateAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
        if (trip.Status != CourierTripStatus.InProgress || !trip.PickedUpAtUtc.HasValue || trip.InTransitAtUtc.HasValue)
        {
            throw new InvalidOperationException("Trip is not in a valid state for starting delivery.");
        }

        var now = DateTime.UtcNow;
        trip.InTransitAtUtc = now;
        trip.ScheduleStatus = "In transit";
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogInformation("Driver {DriverId} started delivery for trip {TripId}", driver.Id, trip.Id);
        return BuildTripStatusResponse(trip.Id, "InTransit", now);
    }

    public async Task<StartTripResponseDto> MarkDeliveredAsync(int userId, Guid tripId, CancellationToken cancellationToken)
    {
        var (driver, trip) = await GetDriverAndAssignedTripForUpdateAsync(userId, tripId, cancellationToken).ConfigureAwait(false);
        if (trip.Status != CourierTripStatus.InProgress || !trip.InTransitAtUtc.HasValue)
        {
            throw new InvalidOperationException("Trip is not in a valid state for delivery.");
        }

        var now = DateTime.UtcNow;
        trip.CompletedAtUtc = now;
        trip.ScheduleStatus = "Delivered";
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        _logger.LogInformation("Driver {DriverId} marked trip {TripId} delivered", driver.Id, trip.Id);
        return BuildTripStatusResponse(trip.Id, "Delivered", now);
    }

    public async Task<TripDetailsResponseDto> GetCourierTripDetailsAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentAsync(tripId, cancellationToken).ConfigureAwait(false);
        if (trip == null)
        {
            throw new InvalidOperationException("Trip could not be found.");
        }

        if (trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("Trip is not assigned to this driver.");
        }

        if (trip.CourierShipment == null)
        {
            throw new InvalidOperationException("Shipment metadata missing for this trip.");
        }

        return new TripDetailsResponseDto
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            ScheduleStatus = trip.ScheduleStatus,
            Shipment = _mapper.Map<ShipmentDetailsDto>(trip.CourierShipment),
            Status = trip.Status.ToString()
        };
    }

    public async Task<StartTripResponseDto> CompleteAssignedTripAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken).ConfigureAwait(false)
                   ?? throw new InvalidOperationException("Trip could not be found.");

        if (trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("Trip is not assigned to this driver.");
        }

        if (trip.Status != CourierTripStatus.InProgress)
        {
            throw new InvalidOperationException($"Trip cannot complete while status is {trip.Status}.");
        }

        var completedAtUtc = DateTime.UtcNow;
        trip.Status = CourierTripStatus.Completed;
        trip.CompletedAtUtc = completedAtUtc;
        driver.AssignedDeliveryTripId = null;

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _walletService.CreateEarningRecordAsync(trip.Id, cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Courier trip {TripId} completed by driver db id {DriverId}", trip.Id, driver.Id);

        return new StartTripResponseDto
        {
            TripId = trip.Id,
            Status = nameof(CourierTripStatus.Completed),
            StartedAt = completedAtUtc
        };
    }

    public async Task<RecentTripsPageResponseDto> GetRecentCourierTripsPageAsync(int userId, int page, int pageSize,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var skip = (page - 1) * pageSize;

        var total = await _uow.DeliveryTrips.CountRecentCompletedAsync(driver.Id, cancellationToken)
            .ConfigureAwait(false);
        var items = await _uow.DeliveryTrips.GetRecentCompletedAsync(driver.Id, skip, pageSize, cancellationToken)
            .ConfigureAwait(false);

        var totalPages = (int)Math.Ceiling(total / (double)pageSize);

        return new RecentTripsPageResponseDto
        {
            Items = items.Select(MapRecentTrip).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = total,
            TotalPages = totalPages
        };
    }

    private static bool HasBlockingCourierAssignment(Driver driver) =>
        driver.AssignedDeliveryTripId != null;

    private async Task<(Driver driver, DeliveryTrip trip)> GetDriverAndAssignedTripForUpdateAsync(int userId, Guid tripId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.GetByUserIdForUpdateAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new InvalidOperationException("Driver profile missing for authenticated user.");
        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken).ConfigureAwait(false)
                   ?? throw new InvalidOperationException("Trip could not be found.");
        if (trip.AssignedDriverId != driver.Id)
        {
            throw new InvalidOperationException("Trip is not assigned to this driver.");
        }

        return (driver, trip);
    }

    private static string ResolveExecutionState(DeliveryTrip trip)
    {
        if (trip.Status == CourierTripStatus.Completed || trip.CompletedAtUtc.HasValue)
        {
            return "delivered";
        }

        if (trip.InTransitAtUtc.HasValue)
        {
            return "in_transit";
        }

        if (trip.PickedUpAtUtc.HasValue)
        {
            return "pickup_confirmed";
        }

        if (trip.Status == CourierTripStatus.InProgress &&
            string.Equals(trip.ScheduleStatus, "Arrived at pickup", StringComparison.OrdinalIgnoreCase))
        {
            return "arrived_at_pickup";
        }

        return "going_to_pickup";
    }

    private static string ResolveTitle(string state) => state switch
    {
        "going_to_pickup" => "Heading to Pickup",
        "arrived_at_pickup" => "You've Arrived!",
        "pickup_confirmed" => "Pickup Confirmed!",
        "in_transit" => "On the Way",
        "delivered" => "Delivered Successfully!",
        _ => "Trip Status"
    };

    private static string ResolveSubtitle(string state) => state switch
    {
        "going_to_pickup" => "Navigate to the pickup location",
        "arrived_at_pickup" => "Confirm you have reached the pickup point",
        "pickup_confirmed" => "Shipment loaded successfully",
        "in_transit" => "Navigate to destination",
        "delivered" => "Great work completing this delivery",
        _ => "Track and complete your shipment"
    };

    private static StartTripResponseDto BuildTripStatusResponse(Guid tripId, string status, DateTime atUtc) =>
        new()
        {
            TripId = tripId,
            Status = status,
            StartedAt = atUtc
        };

    private ActiveTripCardDto MapActiveTrip(DeliveryTrip trip)
    {
        return new ActiveTripCardDto
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            Status = trip.Status.ToString(),
            ScheduleStatus = trip.ScheduleStatus,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            Shipment = _mapper.Map<ShipmentDetailsDto>(trip.CourierShipment!)
        };
    }

    private static RecentTripListItemDto MapRecentTrip(DeliveryTrip trip)
    {
        var completedAt = trip.CompletedAtUtc ?? trip.DateUtc;
        return new RecentTripListItemDto
        {
            ShipmentNumber = trip.ShipmentNumber,
            Route = $"{trip.PickupLocation} → {trip.DropoffLocation}",
            Status = nameof(CourierTripStatus.Completed),
            Date = completedAt.ToString("MMM dd, yyyy", CultureInfo.InvariantCulture),
            Time = completedAt.ToString("h:mm tt", CultureInfo.InvariantCulture)
        };
    }

    public static string FormatOnlineMinutes(int minutes)
    {
        if (minutes < 0)
        {
            minutes = 0;
        }

        var h = minutes / 60;
        var m = minutes % 60;
        return $"{h}h {m}m";
    }

    private static string FormatDuration(int minutes)
    {
        var safe = Math.Max(0, minutes);
        var hours = safe / 60;
        var rem = safe % 60;
        if (hours == 0)
        {
            return $"{rem} min";
        }

        if (rem == 0)
        {
            return $"{hours} hr";
        }

        return $"{hours} hr {rem} min";
    }

    private static string FormatAvailability(DriverAvailabilityStatus status) =>
        status == DriverAvailabilityStatus.Online ? "Online" : "Offline";

    private static DriverAvailabilityStatus ParseAvailability(string status)
    {
        if (string.Equals(status, "Online", StringComparison.OrdinalIgnoreCase))
        {
            return DriverAvailabilityStatus.Online;
        }

        if (string.Equals(status, "Offline", StringComparison.OrdinalIgnoreCase))
        {
            return DriverAvailabilityStatus.Offline;
        }

        throw new ArgumentException("Status must be Online or Offline.", nameof(status));
    }
}
