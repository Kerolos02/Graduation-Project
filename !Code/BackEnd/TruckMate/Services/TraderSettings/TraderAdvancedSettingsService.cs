using System.Security.Cryptography;
using System.Text.Json;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TruckMate.API.Services;
using TruckMate.Common.Exceptions;
using TruckMate.Core.DriverSettings;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Enums;
using TruckMate.Core.Models;
using TruckMate.Core.TraderSettings.Dtos;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.Accounts;
using TruckMate.Services.Audit;
using TruckMate.Services.Notifications;

namespace TruckMate.Services.TraderSettings;

public class TraderAdvancedSettingsService : ITraderSettingsService, ITraderNotificationPreferencesService,
    ITraderPrivacyService
{
    private static readonly TimeSpan EmailVerificationOtpTtl = TimeSpan.FromHours(24);
    private static readonly TimeSpan PhoneVerificationOtpTtl = TimeSpan.FromMinutes(10);

    private readonly IUnitOfWork _uow;
    private readonly IAuditLogService _audit;
    private readonly IEmailService _email;
    private readonly ISmsService _sms;
    private readonly IAccountDeletionScheduler _deletionScheduler;
    private readonly IMapper _mapper;
    private readonly ILogger<TraderAdvancedSettingsService> _logger;

    public TraderAdvancedSettingsService(
        IUnitOfWork uow,
        IAuditLogService audit,
        IEmailService email,
        ISmsService sms,
        IAccountDeletionScheduler deletionScheduler,
        IMapper mapper,
        ILogger<TraderAdvancedSettingsService> logger)
    {
        _uow = uow;
        _audit = audit;
        _email = email;
        _sms = sms;
        _deletionScheduler = deletionScheduler;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<TraderSettingsProfileResponseDto> GetProfileAsync(int userId,
        CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        return new TraderSettingsProfileResponseDto
        {
            FullName = trader.User.FullName,
            Initials = FullNameInitials.FromFullName(trader.User.FullName),
            Role = nameof(UserRole.Trader),
            BusinessName = string.IsNullOrWhiteSpace(trader.BusinessName) ? null : trader.BusinessName.Trim(),
            Email = trader.User.Email,
            PhoneNumber = trader.User.Phone,
            IsEmailVerified = trader.User.EmailVerified,
            IsPhoneVerified = trader.User.PhoneVerified
        };
    }

    public async Task<ChangePasswordResponseDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (traderPublicId, trader, user) =
            await ResolveTraderTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, user.PasswordHash))
        {
            throw new UnauthorizedAppException("Current password is incorrect.");
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        user.LastPasswordChangedAtUtc = DateTime.UtcNow;

        trader.TokenVersion += 1;

        await _audit.LogTraderActionAsync(traderPublicId, "PasswordChanged",
            JsonSerializer.Serialize(new { IpAddress = ipAddress, TimestampUtc = DateTime.UtcNow }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _email.SendPasswordChangedEmailAsync(user.Email, cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Trader password changed for user {UserId}", userId);

        return new ChangePasswordResponseDto { Success = true, Message = "Password updated successfully." };
    }

    public async Task<UpdateContactResponseDto> UpdateContactAsync(int userId, UpdateContactRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (traderPublicId, trader, user) =
            await ResolveTraderTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        var prevJson = JsonSerializer.Serialize(new { user.Email, user.Phone });

        var emailProvided = dto.Email != null && !string.IsNullOrWhiteSpace(dto.Email);
        var phoneProvided = dto.PhoneNumber != null && !string.IsNullOrWhiteSpace(dto.PhoneNumber);

        var emailNormalized = dto.Email?.Trim().ToLowerInvariant();
        var phoneNormalized = dto.PhoneNumber?.Trim();

        var emailChanged = emailProvided && emailNormalized != null &&
                           !string.Equals(user.Email.Trim(), emailNormalized, StringComparison.Ordinal);
        var phoneChanged = phoneProvided && phoneNormalized != null &&
                           !string.Equals(user.Phone.Trim(), phoneNormalized!, StringComparison.Ordinal);

        if (emailChanged &&
            await _uow.EmailInUseExceptUserAsync(emailNormalized!, user.Id, cancellationToken).ConfigureAwait(false))
        {
            throw new ConflictApiException("Email is already in use by another account.");
        }

        if (phoneChanged &&
            await _uow.PhoneInUseExceptUserAsync(phoneNormalized!, user.Id, cancellationToken)
                .ConfigureAwait(false))
        {
            throw new ConflictApiException("Phone number is already in use by another account.");
        }

        if (!emailChanged && !phoneChanged)
        {
            return new UpdateContactResponseDto
            {
                Success = true,
                Message = "No contact changes detected.",
                EmailVerificationRequired = false,
                PhoneVerificationRequired = false
            };
        }

        if (emailChanged && emailNormalized != null)
        {
            user.Email = emailNormalized;
            user.EmailVerified = false;
            var otp = GenerateNumericOtp(6);
            trader.EmailVerificationOtpHash = BCrypt.Net.BCrypt.HashPassword(otp);
            trader.EmailVerificationOtpExpiresUtc = DateTime.UtcNow.Add(EmailVerificationOtpTtl);
            await _email.SendEmailVerificationAsync(user.Email, otp, cancellationToken).ConfigureAwait(false);
        }

        if (phoneChanged && phoneNormalized != null)
        {
            user.Phone = phoneNormalized;
            user.PhoneVerified = false;
            var otp = GenerateNumericOtp(6);
            trader.PhoneVerificationOtpHash = BCrypt.Net.BCrypt.HashPassword(otp);
            trader.PhoneVerificationOtpExpiresUtc = DateTime.UtcNow.Add(PhoneVerificationOtpTtl);
            await _sms.SendPhoneOtpAsync(user.Phone, otp, cancellationToken).ConfigureAwait(false);
        }

        await _audit.LogTraderActionAsync(traderPublicId, "ContactUpdated",
            JsonSerializer.Serialize(new { Previous = prevJson }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new UpdateContactResponseDto
        {
            Success = true,
            Message = "Contact updated. Verification required.",
            EmailVerificationRequired = emailChanged,
            PhoneVerificationRequired = phoneChanged
        };
    }

    public async Task<ScheduleAccountDeletionResponseDto> ScheduleAccountDeletionAsync(int userId,
        ScheduleAccountDeletionRequestDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken)
    {
        var (traderPublicId, trader, user) =
            await ResolveTraderTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
        {
            throw new UnauthorizedAppException("Password verification failed.");
        }

        if (await _uow.TraderHasBlockingShipmentsAsync(trader.Id, cancellationToken).ConfigureAwait(false))
        {
            throw new BadRequestApiException(
                "Cannot delete account with active shipments. Please cancel or complete all active shipments first.");
        }

        var scheduled = DateTime.UtcNow.AddDays(30);

        user.IsDeleted = true;
        user.DeleteRequestedAtUtc = DateTime.UtcNow;
        user.ScheduledHardDeleteAtUtc = scheduled;

        trader.IsDeleted = true;
        trader.DeleteRequestedAtUtc = DateTime.UtcNow;
        trader.ScheduledHardDeleteAtUtc = scheduled;
        trader.TokenVersion += 1;

        await _audit.LogTraderActionAsync(traderPublicId, "AccountDeletionRequested",
            JsonSerializer.Serialize(new { user.ScheduledHardDeleteAtUtc }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        await _email.SendAccountDeletionConfirmationAsync(user.Email, scheduled, cancellationToken)
            .ConfigureAwait(false);
        await _deletionScheduler.ScheduleTraderDeletionAsync(traderPublicId, scheduled, cancellationToken)
            .ConfigureAwait(false);

        return new ScheduleAccountDeletionResponseDto
        {
            Success = true,
            Message = "Account deletion scheduled. You have 30 days to cancel.",
            ScheduledDeletionDate = scheduled
        };
    }

    public async Task<SimpleSuccessResponseDto> CancelAccountDeletionAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (traderPublicId, trader, user) =
            await ResolveTraderTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!trader.IsDeleted && !user.IsDeleted)
        {
            return new SimpleSuccessResponseDto { Success = true, Message = "No pending account deletion." };
        }

        if (trader.ScheduledHardDeleteAtUtc.HasValue &&
            trader.ScheduledHardDeleteAtUtc.Value <= DateTime.UtcNow)
        {
            throw new BadRequestApiException("Grace period has expired.");
        }

        user.IsDeleted = false;
        user.DeleteRequestedAtUtc = null;
        user.ScheduledHardDeleteAtUtc = null;

        trader.IsDeleted = false;
        trader.DeleteRequestedAtUtc = null;
        trader.ScheduledHardDeleteAtUtc = null;
        trader.TokenVersion += 1;

        await _audit.LogTraderActionAsync(traderPublicId, "AccountDeletionCancelled",
            JsonSerializer.Serialize(new { CancelledAtUtc = DateTime.UtcNow }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _deletionScheduler.CancelTraderDeletionAsync(user.Id, cancellationToken).ConfigureAwait(false);

        await _email.SendAccountDeletionCancelledEmailAsync(user.Email, cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto { Success = true, Message = "Account deletion cancelled successfully." };
    }

    async Task<TraderNotificationPreferencesResponseDto> ITraderNotificationPreferencesService.GetAsync(
        int userId, CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        var existing = await _uow.TraderNotificationPreferences
            .GetByTraderPublicIdForReadAsync(trader.PublicId, cancellationToken).ConfigureAwait(false);
        if (existing != null)
        {
            return _mapper.Map<TraderNotificationPreferencesResponseDto>(existing);
        }

        var created = CreateDefaultTraderNotificationPreferences(trader.PublicId);
        _uow.TraderNotificationPreferences.Add(created);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return _mapper.Map<TraderNotificationPreferencesResponseDto>(created);
    }

    async Task<SimpleSuccessResponseDto> ITraderNotificationPreferencesService.UpdateAsync(
        int userId, TraderNotificationPreferencesPatchDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        var entity = await _uow.TraderNotificationPreferences
            .GetByTraderPublicIdTrackedAsync(trader.PublicId, cancellationToken).ConfigureAwait(false);
        if (entity == null)
        {
            entity = CreateDefaultTraderNotificationPreferences(trader.PublicId);
            _uow.TraderNotificationPreferences.Add(entity);
        }

        PatchTraderNotificationPreferences(entity, dto);

        await _audit.LogTraderActionAsync(trader.PublicId, "NotificationPreferencesUpdated",
            JsonSerializer.Serialize(dto), ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto { Success = true, Message = "Notification preferences updated." };
    }

    async Task<TraderPrivacySettingsResponseDto> ITraderPrivacyService.GetAsync(int userId,
        CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        var existing = await _uow.TraderPrivacySettings
            .GetByTraderPublicIdForReadAsync(trader.PublicId, cancellationToken).ConfigureAwait(false);
        if (existing != null)
        {
            return _mapper.Map<TraderPrivacySettingsResponseDto>(existing);
        }

        var created = CreateDefaultTraderPrivacy(trader.PublicId);
        _uow.TraderPrivacySettings.Add(created);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return _mapper.Map<TraderPrivacySettingsResponseDto>(created);
    }

    async Task<SimpleSuccessResponseDto> ITraderPrivacyService.UpdateAsync(int userId,
        TraderPrivacySettingsPatchDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        var entity = await _uow.TraderPrivacySettings
            .GetByTraderPublicIdTrackedAsync(trader.PublicId, cancellationToken).ConfigureAwait(false);
        if (entity == null)
        {
            entity = CreateDefaultTraderPrivacy(trader.PublicId);
            _uow.TraderPrivacySettings.Add(entity);
        }

        var priorConsent = entity.DataRetentionConsentGiven;

        await LogPrivacyFieldChangeIfNeededAsync(trader.PublicId, nameof(entity.ShareBusinessDataWithPartners),
            entity.ShareBusinessDataWithPartners, dto.ShareBusinessDataWithPartners, ipAddress, userAgent,
            cancellationToken).ConfigureAwait(false);
        await LogPrivacyFieldChangeIfNeededAsync(trader.PublicId, nameof(entity.AllowMarketingCommunications),
            entity.AllowMarketingCommunications, dto.AllowMarketingCommunications, ipAddress, userAgent,
            cancellationToken).ConfigureAwait(false);
        await LogPrivacyFieldChangeIfNeededAsync(trader.PublicId, nameof(entity.AllowAnalyticsTracking),
            entity.AllowAnalyticsTracking, dto.AllowAnalyticsTracking, ipAddress, userAgent,
            cancellationToken).ConfigureAwait(false);
        await LogPrivacyFieldChangeIfNeededAsync(trader.PublicId, nameof(entity.ShareShipmentDataForResearch),
            entity.ShareShipmentDataForResearch, dto.ShareShipmentDataForResearch, ipAddress, userAgent,
            cancellationToken).ConfigureAwait(false);
        await LogPrivacyFieldChangeIfNeededAsync(trader.PublicId, nameof(entity.DataRetentionConsentGiven),
            entity.DataRetentionConsentGiven, dto.DataRetentionConsentGiven, ipAddress, userAgent,
            cancellationToken).ConfigureAwait(false);

        ApplyTraderPrivacyPatch(entity, dto, priorConsent);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto { Success = true, Message = "Privacy settings updated." };
    }

    public async Task<SimpleSuccessResponseDto> RequestDataExportAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdWithUserAsync(userId, cancellationToken).ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");

        var entity = await _uow.TraderPrivacySettings
            .GetByTraderPublicIdTrackedAsync(trader.PublicId, cancellationToken).ConfigureAwait(false);
        if (entity == null)
        {
            entity = CreateDefaultTraderPrivacy(trader.PublicId);
            _uow.TraderPrivacySettings.Add(entity);
        }

        if (entity.GdprDataExportRequestedAtUtc.HasValue &&
            entity.GdprDataExportRequestedAtUtc.Value.AddDays(30) > DateTime.UtcNow)
        {
            throw new TooManyRequestsApiException(
                "A data export was requested recently. Please wait 30 days between export requests.");
        }

        entity.GdprDataExportRequestedAtUtc = DateTime.UtcNow;
        entity.GdprDataExportDeliveredAtUtc = null;

        await _audit.LogTraderActionAsync(trader.PublicId, "GdprDataExportRequested", null,
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto
        {
            Success = true,
            Message = "Data export requested. You will receive an email within 48 hours."
        };
    }

    private async Task<(Guid traderPublicId, Trader trader, People user)> ResolveTraderTrackedAsync(
        int userId, CancellationToken cancellationToken)
    {
        var trader = await _uow.Traders.GetByUserIdTrackedWithUserAsync(userId, cancellationToken)
                         .ConfigureAwait(false)
                     ?? throw new UnauthorizedAppException("Trader profile missing.");
        return (trader.PublicId, trader, trader.User);
    }

    private static TraderNotificationPreference CreateDefaultTraderNotificationPreferences(Guid traderPublicId) =>
        new()
        {
            Id = Guid.NewGuid(),
            TraderPublicId = traderPublicId,
            ShipmentCreatedConfirmation = true,
            ShipmentAssignedToDriver = true,
            ShipmentPickedUp = true,
            ShipmentInTransit = false,
            ShipmentDelivered = true,
            ShipmentDelayed = true,
            ShipmentCancelled = true,
            InvoiceGenerated = true,
            PaymentConfirmed = true,
            PaymentFailed = true,
            PushNotificationsEnabled = true,
            EmailNotificationsEnabled = true,
            SmsNotificationsEnabled = true
        };

    private static TraderPrivacySetting CreateDefaultTraderPrivacy(Guid traderPublicId) =>
        new()
        {
            Id = Guid.NewGuid(),
            TraderPublicId = traderPublicId,
            ShareBusinessDataWithPartners = false,
            AllowMarketingCommunications = false,
            AllowAnalyticsTracking = false,
            ShareShipmentDataForResearch = false,
            DataRetentionConsentGiven = false,
            ConsentGivenAtUtc = null
        };

    private static void PatchTraderNotificationPreferences(
        TraderNotificationPreference entity,
        TraderNotificationPreferencesPatchDto dto)
    {
        if (dto.ShipmentCreatedConfirmation.HasValue)
        {
            entity.ShipmentCreatedConfirmation = dto.ShipmentCreatedConfirmation.Value;
        }

        if (dto.ShipmentAssignedToDriver.HasValue)
        {
            entity.ShipmentAssignedToDriver = dto.ShipmentAssignedToDriver.Value;
        }

        if (dto.ShipmentPickedUp.HasValue)
        {
            entity.ShipmentPickedUp = dto.ShipmentPickedUp.Value;
        }

        if (dto.ShipmentInTransit.HasValue)
        {
            entity.ShipmentInTransit = dto.ShipmentInTransit.Value;
        }

        if (dto.ShipmentDelivered.HasValue)
        {
            entity.ShipmentDelivered = dto.ShipmentDelivered.Value;
        }

        if (dto.ShipmentDelayed.HasValue)
        {
            entity.ShipmentDelayed = dto.ShipmentDelayed.Value;
        }

        if (dto.ShipmentCancelled.HasValue)
        {
            entity.ShipmentCancelled = dto.ShipmentCancelled.Value;
        }

        if (dto.InvoiceGenerated.HasValue)
        {
            entity.InvoiceGenerated = dto.InvoiceGenerated.Value;
        }

        if (dto.PaymentConfirmed.HasValue)
        {
            entity.PaymentConfirmed = dto.PaymentConfirmed.Value;
        }

        if (dto.PaymentFailed.HasValue)
        {
            entity.PaymentFailed = dto.PaymentFailed.Value;
        }

        if (dto.PushNotificationsEnabled.HasValue)
        {
            entity.PushNotificationsEnabled = dto.PushNotificationsEnabled.Value;
        }

        if (dto.EmailNotificationsEnabled.HasValue)
        {
            entity.EmailNotificationsEnabled = dto.EmailNotificationsEnabled.Value;
        }

        if (dto.SmsNotificationsEnabled.HasValue)
        {
            entity.SmsNotificationsEnabled = dto.SmsNotificationsEnabled.Value;
        }
    }

    private Task LogPrivacyFieldChangeIfNeededAsync(Guid traderPublicId, string field, bool currentValue,
        bool? requestedValue, string ip, string ua, CancellationToken cancellationToken)
    {
        if (!requestedValue.HasValue || requestedValue.Value == currentValue)
        {
            return Task.CompletedTask;
        }

        return _audit.LogTraderActionAsync(traderPublicId, "PrivacyConsentFieldChanged",
            JsonSerializer.Serialize(new
            {
                field,
                Old = currentValue,
                New = requestedValue.Value
            }), ip, ua, cancellationToken);
    }

    private static void ApplyTraderPrivacyPatch(
        TraderPrivacySetting entity,
        TraderPrivacySettingsPatchDto dto,
        bool priorConsent)
    {
        if (dto.ShareBusinessDataWithPartners.HasValue)
        {
            entity.ShareBusinessDataWithPartners = dto.ShareBusinessDataWithPartners.Value;
        }

        if (dto.AllowMarketingCommunications.HasValue)
        {
            entity.AllowMarketingCommunications = dto.AllowMarketingCommunications.Value;
        }

        if (dto.AllowAnalyticsTracking.HasValue)
        {
            entity.AllowAnalyticsTracking = dto.AllowAnalyticsTracking.Value;
        }

        if (dto.ShareShipmentDataForResearch.HasValue)
        {
            entity.ShareShipmentDataForResearch = dto.ShareShipmentDataForResearch.Value;
        }

        if (!dto.DataRetentionConsentGiven.HasValue)
        {
            return;
        }

        entity.DataRetentionConsentGiven = dto.DataRetentionConsentGiven.Value;
        if (dto.DataRetentionConsentGiven.Value && !priorConsent)
        {
            entity.ConsentGivenAtUtc = DateTime.UtcNow;
        }
    }

    private static string GenerateNumericOtp(int digits)
    {
        var max = (int)Math.Pow(10, digits);
        Span<byte> buf = stackalloc byte[4];
        RandomNumberGenerator.Fill(buf);
        var n = BitConverter.ToUInt32(buf) % (uint)max;
        return n.ToString($"D{digits}");
    }
}
