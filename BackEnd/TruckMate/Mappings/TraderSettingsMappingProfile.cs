using AutoMapper;
using TruckMate.Core.Models;
using TruckMate.Core.TraderSettings.Dtos;

namespace TruckMate.Mappings;

public class TraderSettingsMappingProfile : Profile
{
    public TraderSettingsMappingProfile()
    {
        CreateMap<TraderNotificationPreference, TraderNotificationPreferencesResponseDto>();

        CreateMap<TraderPrivacySetting, TraderPrivacySettingsResponseDto>()
            .ForMember(d => d.ConsentGivenAt, o => o.MapFrom(s => s.ConsentGivenAtUtc))
            .ForMember(d => d.GdprDataExportRequestedAt, o => o.MapFrom(s => s.GdprDataExportRequestedAtUtc));
    }
}
