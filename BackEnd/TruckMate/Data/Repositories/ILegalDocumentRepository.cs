using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;

namespace TruckMate.Data.Repositories;

public interface ILegalDocumentRepository
{
    Task<LegalDocument?> GetActiveByTypeAsync(LegalDocumentType type, CancellationToken cancellationToken);
}
