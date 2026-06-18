using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class LegalDocumentRepository : ILegalDocumentRepository
{
    private readonly TruckMateDbContext _context;

    public LegalDocumentRepository(TruckMateDbContext context)
    {
        _context = context;
    }

    public Task<LegalDocument?> GetActiveByTypeAsync(LegalDocumentType type, CancellationToken cancellationToken) =>
        _context.LegalDocuments.AsNoTracking()
            .OrderByDescending(d => d.EffectiveDateUtc)
            .FirstOrDefaultAsync(d => d.Type == type && d.IsActive, cancellationToken);
}
