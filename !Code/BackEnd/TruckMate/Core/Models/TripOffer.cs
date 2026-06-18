using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class TripOffer
{
    public Guid Id { get; set; }

    public Guid TripId { get; set; }
    public DeliveryTrip Trip { get; set; } = null!;

    public int DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public DateTime OfferedAtUtc { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
    public TripOfferStatus Status { get; set; } = TripOfferStatus.Pending;
    public DateTime? RespondedAtUtc { get; set; }
    public string? DeclineReason { get; set; }
    public string? CancelReason { get; set; }
}
