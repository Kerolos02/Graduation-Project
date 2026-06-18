using Microsoft.EntityFrameworkCore;
using TruckMate.Data.Context;

namespace TruckMate.Data.Repositories;

public class Repository<TEntity> : IRepository<TEntity> where TEntity : class
{
    protected readonly TruckMateDbContext Context;
    protected readonly DbSet<TEntity> DbSet;

    public Repository(TruckMateDbContext context)
    {
        Context = context;
        DbSet = context.Set<TEntity>();
    }

    public virtual Task<TEntity?> GetByIdAsync(object id, CancellationToken cancellationToken = default) =>
        throw new NotSupportedException($"{typeof(TEntity).Name} lookup by id requires a specialized repository.");

    public virtual IQueryable<TEntity> Query() => DbSet.AsQueryable();

    public async Task AddAsync(TEntity entity, CancellationToken cancellationToken = default)
    {
        await DbSet.AddAsync(entity, cancellationToken).ConfigureAwait(false);
    }

    public async Task AddRangeAsync(IEnumerable<TEntity> entities, CancellationToken cancellationToken = default)
    {
        await DbSet.AddRangeAsync(entities, cancellationToken).ConfigureAwait(false);
    }

    public void Update(TEntity entity) => DbSet.Update(entity);

    public void Remove(TEntity entity) => DbSet.Remove(entity);
}
