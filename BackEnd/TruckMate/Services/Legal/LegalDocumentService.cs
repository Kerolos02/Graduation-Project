using AutoMapper;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Data.UnitOfWork;

namespace TruckMate.Services.Legal;

public interface ILegalDocumentService
{
    Task<LegalDocumentResponseDto?> GetActiveCachedAsync(string routeTypeSegment,
        CancellationToken cancellationToken);
}

public class LegalDocumentService : ILegalDocumentService
{
    private readonly IUnitOfWork _uow;
    private readonly IMemoryCache _cache;
    private readonly IMapper _mapper;
    private readonly ILogger<LegalDocumentService> _logger;

    public LegalDocumentService(IUnitOfWork uow, IMemoryCache cache,
        IMapper mapper, ILogger<LegalDocumentService> logger)
    {
        _uow = uow;
        _cache = cache;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<LegalDocumentResponseDto?> GetActiveCachedAsync(string routeTypeSegment,
        CancellationToken cancellationToken)
    {
        var typeNullable = LegalDocumentsRouteMapper.TryMap(routeTypeSegment);
        if (typeNullable is not LegalDocumentType typeVal)
        {
            return null;
        }

        var cacheKey = $"legal:active:{(int)typeVal}";
        if (_cache.TryGetValue(cacheKey, out LegalDocumentResponseDto? cached) && cached is not null)
        {
            return cached;
        }

        var entity = await _uow.LegalDocuments.GetActiveByTypeAsync(typeVal, cancellationToken)
            .ConfigureAwait(false);
        if (entity == null)
        {
            _logger.LogWarning("Missing active legal doc for type {Type}", typeVal);
            return null;
        }

        var dto = _mapper.Map<LegalDocumentResponseDto>(entity);
        _cache.Set(cacheKey, dto, TimeSpan.FromHours(1));
        return dto;
    }
}
