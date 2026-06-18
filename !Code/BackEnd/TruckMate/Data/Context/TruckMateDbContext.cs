using Microsoft.EntityFrameworkCore;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;

namespace TruckMate.Data.Context;

public class TruckMateDbContext : DbContext
{
    public TruckMateDbContext(DbContextOptions<TruckMateDbContext> options)
        : base(options)
    {
    }

    public DbSet<People> Users { get; set; } = null!;
    public DbSet<Driver> Drivers { get; set; } = null!;
    public DbSet<Trader> Traders { get; set; } = null!;
    public DbSet<ShipmentRequest> ShipmentRequests { get; set; } = null!;
    public DbSet<Review> Reviews { get; set; } = null!;
    public DbSet<Offer> Offers { get; set; } = null!;
    public DbSet<Trip> Trips { get; set; } = null!;
    public DbSet<Truck> trucks { get; set; } = null!;

    public DbSet<DeliveryTrip> DeliveryTrips { get; set; } = null!;
    public DbSet<CourierShipment> CourierShipments { get; set; } = null!;
    public DbSet<TripOffer> TripOffers { get; set; } = null!;
    public DbSet<DriverOfferHistory> DriverOfferHistories { get; set; } = null!;
    public DbSet<DriverDailySummary> DriverDailySummaries { get; set; } = null!;
    public DbSet<DriverEarning> DriverEarnings { get; set; } = null!;
    public DbSet<DriverVehicle> DriverVehicles { get; set; } = null!;
    public DbSet<DriverReview> DriverReviews { get; set; } = null!;
    public DbSet<ShipmentStatusHistory> ShipmentStatusHistories { get; set; } = null!;
    public DbSet<Invoice> Invoices { get; set; } = null!;
    public DbSet<TraderPaymentCard> TraderPaymentCards { get; set; } = null!;
    public DbSet<TraderWallet> TraderWallets { get; set; } = null!;

    public DbSet<DriverNotificationPreference> DriverNotificationPreferences { get; set; } = null!;
    public DbSet<DriverPrivacySetting> DriverPrivacySettings { get; set; } = null!;
    public DbSet<DriverAuditLog> DriverAuditLogs { get; set; } = null!;
    public DbSet<LegalDocument> LegalDocuments { get; set; } = null!;
    public DbSet<TraderNotificationPreference> TraderNotificationPreferences { get; set; } = null!;
    public DbSet<TraderPrivacySetting> TraderPrivacySettings { get; set; } = null!;
    public DbSet<TraderAuditLog> TraderAuditLogs { get; set; } = null!;

    public DbSet<TripRequest> TripRequests { get; set; } = null!;
    public DbSet<TripRequestRejection> TripRequestRejections { get; set; } = null!;
    public DbSet<RequestNumberSequence> RequestNumberSequences { get; set; } = null!;

    public override int SaveChanges()
    {
        ApplyCourierTripCompletionSideEffects();
        return base.SaveChanges();
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        ApplyCourierTripCompletionSideEffects();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        ApplyCourierTripCompletionSideEffects();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess,
        CancellationToken cancellationToken = default)
    {
        ApplyCourierTripCompletionSideEffects();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

    /// <summary>
    /// Applies business rule updates when a <see cref="DeliveryTrip"/> transitions to Completed
    /// (trips count, earnings, clearing assigned-trip pointer).
    /// </summary>
    private void ApplyCourierTripCompletionSideEffects()
    {
        foreach (var entry in ChangeTracker.Entries<DeliveryTrip>())
        {
            if (entry.State != EntityState.Modified)
            {
                continue;
            }

            var entity = entry.Entity;
            var oldStatusRaw = entry.OriginalValues[nameof(DeliveryTrip.Status)];
            var oldStatus = oldStatusRaw is CourierTripStatus s
                ? s
                : CourierTripStatus.Pending;

            if (entity.Status != CourierTripStatus.Completed || oldStatus == CourierTripStatus.Completed)
            {
                continue;
            }

            if (entity.AssignedDriverId is not int driverId)
            {
                continue;
            }

            var utcToday = DateOnly.FromDateTime(DateTime.UtcNow);
            var summary = DriverDailySummaries.Local.FirstOrDefault(x =>
                x.DriverId == driverId && x.SummaryDate == utcToday);
            summary ??=
                DriverDailySummaries.FirstOrDefault(x =>
                    x.DriverId == driverId && x.SummaryDate == utcToday);

            if (summary == null)
            {
                summary = new DriverDailySummary
                {
                    Id = Guid.NewGuid(),
                    DriverId = driverId,
                    SummaryDate = utcToday
                };
                DriverDailySummaries.Add(summary);
            }

            summary.TripsCompleted += 1;
            summary.EarningsEGP += entity.EarningsOnCompletionEgp;

            var driver = Drivers.Find(driverId);
            if (driver != null && driver.AssignedDeliveryTripId == entity.Id)
            {
                driver.AssignedDeliveryTripId = null;
            }
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<DeliveryTrip>(entity =>
        {
            entity.HasKey(t => t.Id);
            entity.Property(t => t.ShipmentNumber).HasMaxLength(32).IsRequired();
            entity.Property(t => t.ScheduleStatus).HasMaxLength(256);
            entity.Property(t => t.PickupLocation).HasMaxLength(512);
            entity.Property(t => t.DropoffLocation).HasMaxLength(512);
            entity.Property(t => t.Zone).HasMaxLength(256);
            entity.Property(t => t.DistanceKm).HasPrecision(18, 2);
            entity.Property(t => t.PaymentAmountEGP).HasPrecision(18, 2);
            entity.Property(t => t.EarningsOnCompletionEgp).HasPrecision(18, 2);
            entity.Property(t => t.TotalWeightLbs).HasPrecision(18, 2);
            entity.HasIndex(t => t.ShipmentNumber).IsUnique();
            entity.HasIndex(t => t.Status);
            entity.HasIndex(t => new { t.TraderId, t.Status });
            entity.HasIndex(t => t.Zone);
            entity.HasIndex(t => new { t.AssignedDriverId, t.Status });

            entity.HasOne(t => t.AssignedDriver)
                .WithMany()
                .HasForeignKey(t => t.AssignedDriverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(t => t.Trader)
                .WithMany()
                .HasForeignKey(t => t.TraderId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<CourierShipment>(entity =>
        {
            entity.HasKey(s => s.Id);
            entity.Property(s => s.ClientName).HasMaxLength(256);
            entity.Property(s => s.CargoType).HasMaxLength(256);
            entity.Property(s => s.WeightLbs).HasPrecision(18, 2);

            entity.HasOne(s => s.Trip)
                .WithOne(t => t.CourierShipment)
                .HasForeignKey<CourierShipment>(s => s.TripId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Driver>(entity =>
        {
            entity.Property(d => d.Rating).HasPrecision(3, 2);
            entity.Property(d => d.AvatarUrl).HasMaxLength(2048);
            entity.Property(d => d.CurrentZone).HasMaxLength(256);
            entity.HasIndex(d => d.PublicId).IsUnique();
            entity.HasAlternateKey(d => d.PublicId);

            entity.HasOne(d => d.AssignedDeliveryTrip)
                .WithMany()
                .HasForeignKey(d => d.AssignedDeliveryTripId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<DriverDailySummary>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.EarningsEGP).HasPrecision(18, 2);
            entity.HasIndex(x => new { x.DriverId, x.SummaryDate }).IsUnique();
            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverEarning>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.ShipmentNumber).HasMaxLength(64).IsRequired();
            entity.Property(x => x.PickupLocation).HasMaxLength(512).IsRequired();
            entity.Property(x => x.DropoffLocation).HasMaxLength(512).IsRequired();
            entity.Property(x => x.AmountEGP).HasPrecision(18, 2);
            entity.HasIndex(x => new { x.DriverId, x.EarnedAt }).IsDescending(false, true);
            entity.HasIndex(x => x.TripId).IsUnique();
            entity.HasIndex(x => new { x.DriverId, x.Status });

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.Trip)
                .WithMany()
                .HasForeignKey(x => x.TripId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverNotificationPreference>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.DriverPublicId).IsUnique();

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverPublicId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverVehicle>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Model).HasMaxLength(128).IsRequired();
            entity.Property(x => x.LicensePlate).HasMaxLength(64).IsRequired();
            entity.HasIndex(x => x.DriverPublicId).IsUnique();
            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverPublicId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverReview>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.TraderName).HasMaxLength(256).IsRequired();
            entity.Property(x => x.Comment).HasMaxLength(500);
            entity.HasIndex(x => new { x.DriverPublicId, x.ReviewedAt }).IsDescending(false, true);
            entity.HasIndex(x => new { x.TripId, x.TraderPublicId }).IsUnique();
            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverPublicId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderPublicId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ShipmentStatusHistory>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Note).HasMaxLength(512);
            entity.HasIndex(x => new { x.ShipmentId, x.OccurredAt });
            entity.HasOne(x => x.Shipment)
                .WithMany()
                .HasForeignKey(x => x.ShipmentId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Invoice>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.InvoiceNumber).HasMaxLength(64).IsRequired();
            entity.Property(x => x.BasePriceEGP).HasPrecision(18, 2);
            entity.Property(x => x.ServiceFeeEGP).HasPrecision(18, 2);
            entity.Property(x => x.TaxEGP).HasPrecision(18, 2);
            entity.Property(x => x.TotalAmountEGP).HasPrecision(18, 2);
            entity.Property(x => x.PaymentMethod).HasMaxLength(128);
            entity.HasIndex(x => x.ShipmentId);
            entity.HasIndex(x => new { x.TraderId, x.Status });

            entity.HasOne(x => x.Shipment)
                .WithMany()
                .HasForeignKey(x => x.ShipmentId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TraderPaymentCard>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.CardHolderName).HasMaxLength(128).IsRequired();
            entity.Property(x => x.Last4Digits).HasMaxLength(4).IsRequired();
            entity.Property(x => x.TokenizedCardId).HasMaxLength(256).IsRequired();
            entity.HasIndex(x => new { x.TraderId, x.IsDefault });
            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TraderWallet>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.BalanceEGP).HasPrecision(18, 2);
            entity.Property(x => x.TotalSpentEGP).HasPrecision(18, 2);
            entity.HasIndex(x => x.TraderId).IsUnique();
            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverPrivacySetting>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.DriverPublicId).IsUnique();

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverPublicId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverAuditLog>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Action).HasMaxLength(128);
            entity.Property(x => x.IpAddress).HasMaxLength(64);
            entity.Property(x => x.UserAgent).HasMaxLength(512);

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverPublicId)
                .HasPrincipalKey(d => d.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TripOffer>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.DeclineReason).HasMaxLength(1024);
            entity.Property(x => x.CancelReason).HasMaxLength(128);
            entity.HasIndex(x => new { x.DriverId, x.Status });
            entity.HasIndex(x => new { x.TripId, x.Status });
            entity.HasIndex(x => new { x.ExpiresAtUtc, x.Status });

            entity.HasOne(x => x.Trip)
                .WithMany()
                .HasForeignKey(x => x.TripId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<DriverOfferHistory>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.DriverId, x.TimestampUtc });

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.TripOffer)
                .WithMany()
                .HasForeignKey(x => x.TripOfferId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.TripRequest)
                .WithMany()
                .HasForeignKey(x => x.TripRequestId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LegalDocument>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Title).HasMaxLength(512);
            entity.Property(x => x.Version).HasMaxLength(64);
            entity.HasIndex(x => new { x.Type, x.IsActive });
        });

        modelBuilder.Entity<TripRequest>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.RequestNumber).HasMaxLength(32).IsRequired();
            entity.Property(x => x.PickupLocation).HasMaxLength(512);
            entity.Property(x => x.PickupAddress).HasMaxLength(512);
            entity.Property(x => x.DropoffLocation).HasMaxLength(512);
            entity.Property(x => x.DropoffAddress).HasMaxLength(512);
            entity.Property(x => x.DistanceKm).HasPrecision(18, 2);
            entity.Property(x => x.PaymentAmountEGP).HasPrecision(18, 2);
            entity.Property(x => x.CargoType).HasMaxLength(256);
            entity.Property(x => x.WeightLbs).HasPrecision(18, 2);
            entity.Property(x => x.PackagesUnit).HasMaxLength(64);
            entity.Property(x => x.SpecialNotes).HasMaxLength(4000);
            entity.Property(x => x.Zone).HasMaxLength(256);
            entity.Property(x => x.RequiredTruckType).HasMaxLength(128);

            entity.HasIndex(x => x.RequestNumber).IsUnique();
            entity.HasIndex(x => new { x.Status, x.PostedAt }).IsDescending(false, true);
            entity.HasIndex(x => x.AcceptedByDriverId);

            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.AcceptedByDriver)
                .WithMany()
                .HasForeignKey(x => x.AcceptedByDriverId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(x => x.CreatedDeliveryTrip)
                .WithMany()
                .HasForeignKey(x => x.CreatedDeliveryTripId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TripRequestRejection>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Reason).HasMaxLength(2000);
            entity.HasIndex(x => new { x.DriverId, x.TripRequestId }).IsUnique();

            entity.HasOne(x => x.TripRequest)
                .WithMany(t => t.Rejections)
                .HasForeignKey(x => x.TripRequestId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(x => x.Driver)
                .WithMany()
                .HasForeignKey(x => x.DriverId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<RequestNumberSequence>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).ValueGeneratedNever();
        });

        modelBuilder.Entity<Trader>(entity =>
        {
            entity.Property(x => x.BusinessName).HasMaxLength(512).IsRequired();
            entity.Property(x => x.PhoneNumber).HasMaxLength(32);
            entity.Property(x => x.Address).HasMaxLength(1024).IsRequired();
            entity.Property(x => x.EmailVerificationOtpHash).HasMaxLength(512);
            entity.Property(x => x.PhoneVerificationOtpHash).HasMaxLength(512);

            entity.HasIndex(x => x.PublicId).IsUnique();
            entity.HasAlternateKey(x => x.PublicId);

            entity.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TraderNotificationPreference>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.TraderPublicId).IsUnique();

            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderPublicId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TraderPrivacySetting>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.TraderPublicId).IsUnique();

            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderPublicId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TraderAuditLog>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Action).HasMaxLength(128);
            entity.Property(x => x.IpAddress).HasMaxLength(64);
            entity.Property(x => x.UserAgent).HasMaxLength(512);

            entity.HasOne(x => x.Trader)
                .WithMany()
                .HasForeignKey(x => x.TraderPublicId)
                .HasPrincipalKey(t => t.PublicId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
