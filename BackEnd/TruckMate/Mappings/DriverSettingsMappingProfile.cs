using AutoMapper;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Models;

namespace TruckMate.Mappings;

public class DriverSettingsMappingProfile : Profile
{
    public DriverSettingsMappingProfile()
    {
        CreateMap<LegalDocument, LegalDocumentResponseDto>()
            .ForMember(d => d.EffectiveDate, o => o.MapFrom(s => s.EffectiveDateUtc));
    }
}
