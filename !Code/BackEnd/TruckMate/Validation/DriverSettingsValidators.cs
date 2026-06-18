using FluentValidation;
using TruckMate.Core.DriverSettings;
using TruckMate.Core.DriverSettings.Dtos;

namespace TruckMate.Validation;

public class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequestDto>
{
    private const string Complexity =
        @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}$";

    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.CurrentPassword).NotEmpty();
        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .MinimumLength(8)
            .Matches(Complexity)
            .WithMessage(
                "Password must be at least 8 characters with upper, lower, digit, and special character.");
        RuleFor(x => x.NewPassword)
            .NotEqual(x => x.CurrentPassword)
            .When(x => !string.IsNullOrEmpty(x.CurrentPassword) && !string.IsNullOrEmpty(x.NewPassword))
            .WithMessage("New password must not match current password.");

        RuleFor(x => x.ConfirmNewPassword)
            .Equal(x => x.NewPassword)
            .WithMessage("Passwords must match.");
    }
}

public class UpdateContactRequestValidator : AbstractValidator<UpdateContactRequestDto>
{
    public UpdateContactRequestValidator()
    {
        RuleFor(x => x.Email)
            .EmailAddress().When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("Invalid email.");

        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+[1-9]\d{7,14}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Phone must be in E.164 format.");

        RuleFor(x => x)
            .Must(x => !string.IsNullOrWhiteSpace(x.Email) || !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Either email or phone number must be provided.");
    }
}

public class ScheduleAccountDeletionRequestValidator : AbstractValidator<ScheduleAccountDeletionRequestDto>
{
    public ScheduleAccountDeletionRequestValidator()
    {
        RuleFor(x => x.Password).NotEmpty();
        RuleFor(x => x.ConfirmationPhrase)
            .Equal(AccountDeletionConstants.ConfirmationPhrase)
            .WithMessage($"Confirmation phrase must be exactly '{AccountDeletionConstants.ConfirmationPhrase}'.");
    }
}

public class NotificationPreferencesPatchValidator : AbstractValidator<NotificationPreferencesPatchDto>
{
    public NotificationPreferencesPatchValidator()
    {
        RuleFor(x => x).Must(HaveAtLeastOne)
            .WithMessage("At least one preference field must be provided.");
    }

    private static bool HaveAtLeastOne(NotificationPreferencesPatchDto x) =>
        x.TripAssignedEnabled.HasValue ||
        x.TripOfferEnabled.HasValue ||
        x.EarningsUpdateEnabled.HasValue ||
        x.SystemAlertsEnabled.HasValue ||
        x.PushNotificationsEnabled.HasValue ||
        x.EmailNotificationsEnabled.HasValue ||
        x.SmsNotificationsEnabled.HasValue;
}

public class PrivacySettingsPatchValidator : AbstractValidator<PrivacySettingsPatchDto>
{
    public PrivacySettingsPatchValidator()
    {
        RuleFor(x => x).Must(HaveAtLeastOne)
            .WithMessage("At least one privacy field must be provided.");
    }

    private static bool HaveAtLeastOne(PrivacySettingsPatchDto x) =>
        x.ShareLocationWithDispatcher.HasValue ||
        x.ShareTripHistoryWithThirdParties.HasValue ||
        x.AllowAnalyticsTracking.HasValue ||
        x.DataRetentionConsentGiven.HasValue;
}
