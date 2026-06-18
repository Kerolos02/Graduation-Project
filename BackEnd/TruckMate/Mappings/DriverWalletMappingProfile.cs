using AutoMapper;
using TruckMate.Core.DriverWallet.Dtos;
using TruckMate.Core.Models;

namespace TruckMate.Mappings;

public class DriverWalletMappingProfile : Profile
{
    public DriverWalletMappingProfile()
    {
        CreateMap<DriverEarning, DriverWalletTripItemDto>()
            .ForMember(d => d.Route, o => o.MapFrom(s => $"{s.PickupLocation} \u2192 {s.DropoffLocation}"))
            .ForMember(d => d.EarnedAt, o => o.MapFrom(s => DateTime.SpecifyKind(s.EarnedAt, DateTimeKind.Utc)))
            .ForMember(d => d.EarnedAtFormatted, o => o.MapFrom(s => s.EarnedAt.ToString("yyyy-MM-dd HH:mm")))
            .ForMember(d => d.AmountFormatted, o => o.MapFrom(s => $"+{s.AmountEGP:0.##} EGP"))
            .ForMember(d => d.Status, o => o.MapFrom(_ => "Completed"));
    }
}
