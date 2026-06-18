using AutoMapper;
using TruckMate.Core.DriverHome.Dtos;
using TruckMate.Core.Models;

namespace TruckMate.Mappings;

public class DriverHomeMappingProfile : Profile
{
    public DriverHomeMappingProfile()
    {
        CreateMap<CourierShipment, ShipmentDetailsDto>();
    }
}
