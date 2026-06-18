using TruckMate.Core.Models;
using TruckMate.Core.Shipments;

namespace TruckMate.Services
{
    public interface IShipmentService
    {
        Task<CostTimeEstimateDto> EstimateCostAndTimeAsync(CreateShipmentRequestDto request);
        string GenerateShipmentId();
    }
}
