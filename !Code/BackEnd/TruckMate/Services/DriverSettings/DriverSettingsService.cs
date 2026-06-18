using System.Text.Json;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using TruckMate.API.Services;
using TruckMate.Common.Exceptions;
using TruckMate.Core.DriverSettings;
using TruckMate.Core.DriverSettings.Dtos;
using TruckMate.Core.Models;
using TruckMate.Data.UnitOfWork;
using TruckMate.Services.Accounts;
using TruckMate.Services.Audit;
using TruckMate.Services.Notifications;

namespace TruckMate.Services.DriverSettings;

public interface IDriverSettingsService
{
    Task<DriverSettingsProfileResponseDto> GetProfileAsync(int userId, CancellationToken cancellationToken);

    Task<ChangePasswordResponseDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task<UpdateContactResponseDto> UpdateContactAsync(int userId, UpdateContactRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken);

    Task<NotificationPreferencesDto> GetNotificationPreferencesAsync(int userId,
        CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> UpsertNotificationPreferencesAsync(int userId,
        NotificationPreferencesPatchDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken);

    Task<PrivacySettingsResponseDto> GetPrivacySettingsAsync(int userId,
        CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> UpsertPrivacySettingsAsync(int userId,
        PrivacySettingsPatchDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken);

    Task<ScheduleAccountDeletionResponseDto> ScheduleAccountDeletionAsync(int userId,
        ScheduleAccountDeletionRequestDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken);

    Task<SimpleSuccessResponseDto> CancelAccountDeletionAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken);
}

public class DriverSettingsService : IDriverSettingsService
{
    private readonly IUnitOfWork _uow;
    private readonly IAuditLogService _audit;
    private readonly IEmailService _email;
    private readonly ISmsService _sms;
    private readonly IAccountDeletionScheduler _deletionScheduler;
    private readonly ILogger<DriverSettingsService> _logger;
    private readonly IHttpContextAccessor? _httpAccessor;

    private static readonly Random OtpRandom = new();

    public DriverSettingsService(
        IUnitOfWork uow,
        IAuditLogService audit,
        IEmailService email,
        ISmsService sms,
        IAccountDeletionScheduler deletionScheduler,
        ILogger<DriverSettingsService> logger,
        IHttpContextAccessor? httpAccessor = null)
    {
        _uow = uow;
        _audit = audit;
        _email = email;
        _sms = sms;
        _deletionScheduler = deletionScheduler;
        _logger = logger;
        _httpAccessor = httpAccessor;
    }

    public async Task<DriverSettingsProfileResponseDto> GetProfileAsync(int userId,
        CancellationToken cancellationToken)
    {
        var (driverPublicId, _, user) = await ResolveDriverAsync(userId, cancellationToken).ConfigureAwait(false);
        await AuditReadAsync(driverPublicId, "AdvancedSettingsProfileViewed", cancellationToken)
            .ConfigureAwait(false);

        return new DriverSettingsProfileResponseDto
        {
            FullName = user.FullName,
            Initials = FullNameInitials.FromFullName(user.FullName),
            Role = user.Role.ToString()
        };
    }

    public async Task<ChangePasswordResponseDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (driverPublicId, _, user) =
            await ResolveTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, user.PasswordHash))
        {
            throw new UnauthorizedAppException("Current password is incorrect.");
        }

        if (dto.NewPassword == dto.CurrentPassword)
        {
            throw new ValidationException(new[]
            {
                new ValidationFailure(nameof(dto.NewPassword), "Must differ from the current password.")
            });
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        user.TokenVersion += 1;
        user.LastPasswordChangedAtUtc = DateTime.UtcNow;

        await _audit.LogDriverActionAsync(driverPublicId, "PasswordChanged",
            JsonSerializer.Serialize(new { IpAddress = ipAddress, TimestampUtc = DateTime.UtcNow }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Password changed for user {UserId} from IP {Ip}", userId, ipAddress);

        return new ChangePasswordResponseDto
            { Success = true, Message = "Password updated successfully." };
    }

    public async Task<UpdateContactResponseDto> UpdateContactAsync(int userId, UpdateContactRequestDto dto,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (driverPublicId, _, user) =
            await ResolveTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        var prevJson = JsonSerializer.Serialize(new { user.Email, user.Phone });

        var emailProvided = dto.Email != null && !string.IsNullOrWhiteSpace(dto.Email);
        var phoneProvided = dto.PhoneNumber != null && !string.IsNullOrWhiteSpace(dto.PhoneNumber);

        var emailNormalized = dto.Email?.Trim().ToLowerInvariant();
        var phoneNormalized = dto.PhoneNumber?.Trim();

        bool emailChanged = emailProvided && emailNormalized != null &&
                            !string.Equals(user.Email.Trim(), emailNormalized, StringComparison.Ordinal);
        bool phoneChanged = phoneProvided && phoneNormalized != null &&
                            !string.Equals(user.Phone.Trim(), phoneNormalized!, StringComparison.Ordinal);

        if (emailChanged &&
            await _uow.EmailInUseExceptUserAsync(emailNormalized!, user.Id, cancellationToken)
                .ConfigureAwait(false))
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
            var otp = OtpRandom.Next(100000, 999999).ToString();
            await _email.SendVerificationEmailAsync(user.Email, otp, cancellationToken).ConfigureAwait(false);
        }

        if (phoneChanged && phoneNormalized != null)
        {
            user.Phone = phoneNormalized;
            user.PhoneVerified = false;
            var otp = OtpRandom.Next(100000, 999999).ToString();
            await _sms.SendPhoneOtpAsync(user.Phone, otp, cancellationToken).ConfigureAwait(false);
        }

        await _audit.LogDriverActionAsync(driverPublicId, "ContactUpdated",
            JsonSerializer.Serialize(new { Previous = prevJson }), ipAddress, userAgent, cancellationToken)
            .ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new UpdateContactResponseDto
        {
            Success = true,
            Message = "Contact information updated. Please verify your new email/phone.",
            EmailVerificationRequired = emailChanged,
            PhoneVerificationRequired = phoneChanged
        };
    }

    public async Task<NotificationPreferencesDto> GetNotificationPreferencesAsync(int userId,
        CancellationToken cancellationToken)
    {
        var driverPublicId = await GetDriverPublicIdAsync(userId, cancellationToken).ConfigureAwait(false);

        var existing =
            await _uow.DriverNotificationPreferences.GetByDriverPublicIdAsync(driverPublicId,
                cancellationToken).ConfigureAwait(false);
        if (existing != null)
        {
            await AuditReadAsync(driverPublicId, "NotificationPreferencesViewed", cancellationToken)
                .ConfigureAwait(false);
            return MapPrefs(existing);
        }

        var created = new DriverNotificationPreference
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driverPublicId
        };

        _uow.DriverNotificationPreferences.Add(created);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await AuditReadAsync(driverPublicId, "NotificationPreferencesViewed", cancellationToken)
            .ConfigureAwait(false);
        return MapPrefs(created);
    }

    public async Task<SimpleSuccessResponseDto> UpsertNotificationPreferencesAsync(int userId,
        NotificationPreferencesPatchDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken)
    {
        var driverPublicId = await GetDriverPublicIdAsync(userId, cancellationToken).ConfigureAwait(false);

        var entity =
            await _uow.DriverNotificationPreferences.GetByDriverPublicIdAsync(driverPublicId,
                cancellationToken).ConfigureAwait(false);
        if (entity == null)
        {
            entity = new DriverNotificationPreference { Id = Guid.NewGuid(), DriverPublicId = driverPublicId };
            _uow.DriverNotificationPreferences.Add(entity);
        }

        PatchPrefs(entity, dto);

        await _audit.LogDriverActionAsync(driverPublicId, "NotificationPreferencesUpdated",
            JsonSerializer.Serialize(dto), ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto { Success = true, Message = "Notification preferences updated." };
    }

    public async Task<PrivacySettingsResponseDto> GetPrivacySettingsAsync(int userId,
        CancellationToken cancellationToken)
    {
        var driverPublicId = await GetDriverPublicIdAsync(userId, cancellationToken).ConfigureAwait(false);

        var existing =
            await _uow.DriverPrivacySettings.GetByDriverPublicIdAsync(driverPublicId, cancellationToken)
                .ConfigureAwait(false);
        if (existing != null)
        {
            await AuditReadAsync(driverPublicId, "PrivacySettingsViewed", cancellationToken)
                .ConfigureAwait(false);
            return MapPrivacy(existing);
        }

        var created = CreateDefaultPrivacy(driverPublicId);
        _uow.DriverPrivacySettings.Add(created);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await AuditReadAsync(driverPublicId, "PrivacySettingsViewed", cancellationToken)
            .ConfigureAwait(false);
        return MapPrivacy(created);
    }

    public async Task<SimpleSuccessResponseDto> UpsertPrivacySettingsAsync(int userId,
        PrivacySettingsPatchDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken)
    {
        var driverPublicId = await GetDriverPublicIdAsync(userId, cancellationToken).ConfigureAwait(false);

        var entity =
            await _uow.DriverPrivacySettings.GetByDriverPublicIdAsync(driverPublicId, cancellationToken)
                .ConfigureAwait(false);

        if (entity == null)
        {
            entity = CreateDefaultPrivacy(driverPublicId);
            _uow.DriverPrivacySettings.Add(entity);
        }

        var priorConsent = entity.DataRetentionConsentGiven;
        var before = SerializePrivacy(entity);

        ApplyPrivacyPatch(entity, dto, priorConsent);

        var after = SerializePrivacy(entity);

        await _audit.LogDriverActionAsync(driverPublicId, "PrivacyConsentChanged",
            JsonSerializer.Serialize(new { Before = before, After = after }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto { Success = true, Message = "Privacy settings updated." };
    }

    public async Task<ScheduleAccountDeletionResponseDto> ScheduleAccountDeletionAsync(int userId,
        ScheduleAccountDeletionRequestDto dto, string ipAddress, string userAgent,
        CancellationToken cancellationToken)
    {
        var (driverPublicId, _, user) =
            await ResolveTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
        {
            throw new UnauthorizedAppException("Password verification failed.");
        }

        user.IsDeleted = true;
        user.DeleteRequestedAtUtc = DateTime.UtcNow;
        user.ScheduledHardDeleteAtUtc = DateTime.UtcNow.AddDays(30);
        user.TokenVersion += 1;

        await _audit.LogDriverActionAsync(driverPublicId, "AccountDeletionScheduled",
            JsonSerializer.Serialize(new { user.ScheduledHardDeleteAtUtc }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        if (user.ScheduledHardDeleteAtUtc.HasValue)
        {
            await _email.SendAccountDeletionConfirmationAsync(user.Email, user.ScheduledHardDeleteAtUtc.Value,
                    cancellationToken)
                .ConfigureAwait(false);
            await _deletionScheduler
                .ScheduleDeletionAsync(driverPublicId, user.ScheduledHardDeleteAtUtc.Value, cancellationToken)
                .ConfigureAwait(false);
        }

        return new ScheduleAccountDeletionResponseDto
        {
            Success = true,
            Message = "Account deletion scheduled. You have 30 days to cancel.",
            ScheduledDeletionDate = user.ScheduledHardDeleteAtUtc ?? DateTime.UtcNow.AddDays(30)
        };
    }

    public async Task<SimpleSuccessResponseDto> CancelAccountDeletionAsync(int userId,
        string ipAddress, string userAgent, CancellationToken cancellationToken)
    {
        var (driverPublicId, _, user) =
            await ResolveTrackedAsync(userId, cancellationToken).ConfigureAwait(false);

        if (!user.IsDeleted)
        {
            return new SimpleSuccessResponseDto { Success = true, Message = "No pending account deletion." };
        }

        user.IsDeleted = false;
        user.DeleteRequestedAtUtc = null;
        user.ScheduledHardDeleteAtUtc = null;
        user.TokenVersion += 1;

        await _audit.LogDriverActionAsync(driverPublicId, "AccountDeletionCancelled",
            JsonSerializer.Serialize(new { CancelledAtUtc = DateTime.UtcNow }),
            ipAddress, userAgent, cancellationToken).ConfigureAwait(false);

        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        await _deletionScheduler.CancelDeletionAsync(user.Id, cancellationToken).ConfigureAwait(false);

        return new SimpleSuccessResponseDto
            { Success = true, Message = "Account deletion has been cancelled." };
    }

    private static string SerializePrivacy(DriverPrivacySetting entity) =>
        JsonSerializer.Serialize(new
        {
            entity.ShareLocationWithDispatcher,
            entity.ShareTripHistoryWithThirdParties,
            entity.AllowAnalyticsTracking,
            entity.DataRetentionConsentGiven,
            entity.ConsentGivenAtUtc
        });

    private static void ApplyPrivacyPatch(DriverPrivacySetting entity, PrivacySettingsPatchDto dto,
        bool priorConsent)
    {
        if (dto.ShareLocationWithDispatcher.HasValue)
        {
            entity.ShareLocationWithDispatcher = dto.ShareLocationWithDispatcher.Value;
        }

        if (dto.ShareTripHistoryWithThirdParties.HasValue)
        {
            entity.ShareTripHistoryWithThirdParties = dto.ShareTripHistoryWithThirdParties.Value;
        }

        if (dto.AllowAnalyticsTracking.HasValue)
        {
            entity.AllowAnalyticsTracking = dto.AllowAnalyticsTracking.Value;
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

    private static DriverPrivacySetting CreateDefaultPrivacy(Guid driverPublicId) =>
        new()
        {
            Id = Guid.NewGuid(),
            DriverPublicId = driverPublicId,
            ShareLocationWithDispatcher = true,
            ShareTripHistoryWithThirdParties = false,
            AllowAnalyticsTracking = false,
            DataRetentionConsentGiven = false,
            ConsentGivenAtUtc = null
        };

    private static void PatchPrefs(DriverNotificationPreference entity, NotificationPreferencesPatchDto dto)
    {
        if (dto.TripAssignedEnabled.HasValue)
        {
            entity.TripAssignedEnabled = dto.TripAssignedEnabled.Value;
        }

        if (dto.TripOfferEnabled.HasValue)
        {
            entity.TripOfferEnabled = dto.TripOfferEnabled.Value;
        }

        if (dto.EarningsUpdateEnabled.HasValue)
        {
            entity.EarningsUpdateEnabled = dto.EarningsUpdateEnabled.Value;
        }

        if (dto.SystemAlertsEnabled.HasValue)
        {
            entity.SystemAlertsEnabled = dto.SystemAlertsEnabled.Value;
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

    private static NotificationPreferencesDto MapPrefs(DriverNotificationPreference x) =>
        new()
        {
            TripAssignedEnabled = x.TripAssignedEnabled,
            TripOfferEnabled = x.TripOfferEnabled,
            EarningsUpdateEnabled = x.EarningsUpdateEnabled,
            SystemAlertsEnabled = x.SystemAlertsEnabled,
            PushNotificationsEnabled = x.PushNotificationsEnabled,
            EmailNotificationsEnabled = x.EmailNotificationsEnabled,
            SmsNotificationsEnabled = x.SmsNotificationsEnabled
        };

    private static PrivacySettingsResponseDto MapPrivacy(DriverPrivacySetting x) =>
        new()
        {
            ShareLocationWithDispatcher = x.ShareLocationWithDispatcher,
            ShareTripHistoryWithThirdParties = x.ShareTripHistoryWithThirdParties,
            AllowAnalyticsTracking = x.AllowAnalyticsTracking,
            DataRetentionConsentGiven = x.DataRetentionConsentGiven,
            ConsentGivenAt = x.ConsentGivenAtUtc
        };

    private async Task<(Guid driverPublicId, Driver driver, People user)> ResolveDriverAsync(int userId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.Query()
                       .Include(d => d.User)
                       .FirstOrDefaultAsync(d => d.UserId == userId, cancellationToken)
                       .ConfigureAwait(false)
                   ?? throw new UnauthorizedAppException("Driver profile missing.");
        return (driver.PublicId, driver, driver.User);
    }

    private async Task<(Guid driverPublicId, Driver driver, People user)> ResolveTrackedAsync(int userId,
        CancellationToken cancellationToken)
    {
        var driver = await _uow.Drivers.Query()
            .Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId, cancellationToken)
            .ConfigureAwait(false)
                   ?? throw new UnauthorizedAppException("Driver profile missing.");
        return (driver.PublicId, driver, driver.User);
    }
    private async Task<Guid> GetDriverPublicIdAsync(int userId, CancellationToken cancellationToken)
    {
        var (pid, _, _) = await ResolveDriverAsync(userId, cancellationToken).ConfigureAwait(false);
        return pid;
    }

    private (string Ip, string Ua) RequestMetaFromAccessor()
    {
        var ctx = _httpAccessor?.HttpContext;
        if (ctx == null)
        {
            return ("unknown", "unknown");
        }

        var ip = ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var ua = ctx.Request.Headers.UserAgent.ToString();
        return (ip, string.IsNullOrWhiteSpace(ua) ? "unknown" : ua);
    }

    private async Task AuditReadAsync(Guid driverPublicId, string action,
        CancellationToken cancellationToken)
    {
        var m = RequestMetaFromAccessor();
        await _audit.LogDriverActionAsync(driverPublicId, action, null, m.Ip, m.Ua, cancellationToken)
            .ConfigureAwait(false);
        await _uow.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }
}
