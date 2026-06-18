using TruckMate.Core.Enums;

namespace TruckMate.Core.Models;

public class DriverOfferHistory
{
    public Guid Id { get; set; }
    public int DriverId { get; set; }
    public Driver Driver { get; set; } = null!;
    public Guid? TripOfferId { get; set; }
    public TripOffer? TripOffer { get; set; }
    public Guid? TripRequestId { get; set; }
    public TripRequest? TripRequest { get; set; }
    public DriverOfferHistoryAction Action { get; set; }
    public DateTime TimestampUtc { get; set; }
}
