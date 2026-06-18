using AutoMapper;
using TruckMate.Core.DriverTrips.Dtos;
using TruckMate.Core.Models;
using TruckMate.Services.DriverTrips;

namespace TruckMate.Mappings;

public class DriverTripsMappingProfile : Profile
{
    public DriverTripsMappingProfile()
    {
        CreateMap<TripRequest, TripRequestRouteDetailDto>()
            .ForMember(d => d.DistanceFormatted,
                o => o.MapFrom(s => TripMarketplaceFormatter.FormatDistanceKm(s.DistanceKm)))
            .ForMember(d => d.EstimatedDurationFormatted,
                o => o.MapFrom(s => TripMarketplaceFormatter.FormatEstimatedDuration(s.EstimatedDurationMinutes)));

        CreateMap<TripRequest, TripRequestCargoDetailDto>()
            .ForMember(d => d.WeightFormatted, o => o.MapFrom(s => TripMarketplaceFormatter.FormatWeightLbs(s.WeightLbs)))
            .ForMember(d => d.PackagesFormatted,
                o => o.MapFrom(s => TripMarketplaceFormatter.FormatPackages(s.PackagesCount, s.PackagesUnit)));
    }
}
