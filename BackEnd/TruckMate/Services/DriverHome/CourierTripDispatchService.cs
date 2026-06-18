using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.DriverHome;

/// <summary>Used by dispatcher integrations to assign courier trips and raise SignalR payloads.</summary>
public interface ICourierTripDispatchService
{
    Task AssignPendingTripAsync(Guid tripId, int driverDbId, CancellationToken cancellationToken);
}

public class CourierTripDispatchService : ICourierTripDispatchService
{
    private readonly IUnitOfWork _uow;
    private readonly IMapper _mapper;
    private readonly IDriverRealtimePublisher _publisher;
    private readonly ILogger<CourierTripDispatchService> _logger;

    public CourierTripDispatchService(IUnitOfWork uow, IMapper mapper,
        IDriverRealtimePublisher publisher, ILogger<CourierTripDispatchService> logger)
    {
        _uow = uow;
        _mapper = mapper;
        _publisher = publisher;
        _logger = logger;
    }

    public async Task AssignPendingTripAsync(Guid tripId, int driverDbId, CancellationToken cancellationToken)
    {
        var driver =
            await _uow.Drivers.Query()
                .Include(d => d.User)
                .FirstOrDefaultAsync(d => d.Id == driverDbId, cancellationToken)
                .ConfigureAwait(false)
            ?? throw new InvalidOperationException("Driver record not found.");

        if (driver.AssignedDeliveryTripId != null)
        {
            throw new InvalidOperationException("Driver already has an active courier assignment.");
        }

        if (driver.AvailabilityStatus != DriverAvailabilityStatus.Online)
        {
            throw new InvalidOperationException("Only online drivers can receive new assignments.");
        }

        var trip = await _uow.DeliveryTrips.GetByIdWithShipmentTrackedAsync(tripId, cancellationToken)
                   .ConfigureAwait(false);

        if (trip == null)
        {
            throw new InvalidOperationException("Trip not found.");
        }

        if (trip.Status != CourierTripStatus.Pending || trip.AssignedDriverId != null)
        {
            throw new InvalidOperationException("Trip must be pending and unassigned.");
        }

        if (!string.Equals(driver.CurrentZone, trip.Zone, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Driver zone does not match the trip zone.");
        }

        trip.AssignedDriverId = driver.Id;
        trip.Status = CourierTripStatus.Assigned;
        if (string.IsNullOrWhiteSpace(trip.ScheduleStatus))
        {
            trip.ScheduleStatus = "Ready to start";
        }
        driver.AssignedDeliveryTripId = trip.Id;

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Assigned courier trip {TripId} to driver db id {DriverId}", trip.Id, driver.Id);

        if (trip.CourierShipment == null)
        {
            throw new InvalidOperationException("Cannot broadcast assignment without courier shipment metadata.");
        }

        var payload = new TripAssignedSignalPayload
        {
            TripId = trip.Id,
            ShipmentNumber = trip.ShipmentNumber,
            PickupLocation = trip.PickupLocation,
            DropoffLocation = trip.DropoffLocation,
            Shipment = _mapper.Map<ShipmentDetailsDto>(trip.CourierShipment)
        };

        await _publisher.PublishTripAssignedAsync(driver.UserId, payload, cancellationToken)
            .ConfigureAwait(false);
    }
}
