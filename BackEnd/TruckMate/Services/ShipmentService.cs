using TruckMate.Core.Shipments;

namespace TruckMate.Services
{
    public class ShipmentService : IShipmentService
    {
        public Task<CostTimeEstimateDto> EstimateCostAndTimeAsync(CreateShipmentRequestDto request)
        {
            var distance = EstimateDistance(request.PickupLocation, request.DropOffLocation);
            var baseCostPerMile = 1.5m;
            var cost = (decimal)distance * baseCostPerMile;

            if (request.IsFragile) cost *= 1.2m;
            if (request.IsRefrigerated) cost *= 1.5m;
            if (request.Weight > 50) cost *= 1.1m;

            var minCost = cost * 0.9m;
            var maxCost = cost * 1.2m;

            var hours = distance / 45.0;
            var timeStr = hours >= 1
                ? $"{(int)hours}h {(int)((hours % 1) * 60)}min"
                : $"{(int)(hours * 60)}min";

            return Task.FromResult(new CostTimeEstimateDto
            {
                DistanceMiles = Math.Round(distance, 1),
                EstimatedTime = timeStr,
                MinCost = Math.Round(minCost, 2),
                MaxCost = Math.Round(maxCost, 2)
            });
        }

        public string GenerateShipmentId()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            var random = new Random();
            var suffix = new string(Enumerable.Range(0, 8).Select(_ => chars[random.Next(chars.Length)]).ToArray());
            return $"TH-{suffix}";
        }

        private static double EstimateDistance(string pickup, string dropOff)
        {
            var hash1 = Math.Abs(pickup.GetHashCode() % 200);
            var hash2 = Math.Abs(dropOff.GetHashCode() % 200);
            return Math.Abs(hash1 - hash2) + 50;
        }
    }
}
