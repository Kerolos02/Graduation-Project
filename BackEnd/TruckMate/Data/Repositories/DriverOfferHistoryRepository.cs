using TruckMate.Core.Models;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class DriverOfferHistoryRepository : Repository<DriverOfferHistory>, IDriverOfferHistoryRepository
{
    public DriverOfferHistoryRepository(TruckMateDbContext context) : base(context)
    {
    }
}
