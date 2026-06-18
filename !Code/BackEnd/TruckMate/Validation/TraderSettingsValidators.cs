using FluentValidation;
using TruckMate.Core.TraderSettings.Dtos;

namespace TruckMate.Validation;

public class TraderNotificationPreferencesPatchValidator : AbstractValidator<TraderNotificationPreferencesPatchDto>
{
    public TraderNotificationPreferencesPatchValidator()
    {
        RuleFor(x => x).Must(HaveAtLeastOne)
            .WithMessage("At least one preference field must be provided.");
    }

    private static bool HaveAtLeastOne(TraderNotificationPreferencesPatchDto x) =>
        x.ShipmentCreatedConfirmation.HasValue ||
        x.ShipmentAssignedToDriver.HasValue ||
        x.ShipmentPickedUp.HasValue ||
        x.ShipmentInTransit.HasValue ||
        x.ShipmentDelivered.HasValue ||
        x.ShipmentDelayed.HasValue ||
        x.ShipmentCancelled.HasValue ||
        x.InvoiceGenerated.HasValue ||
        x.PaymentConfirmed.HasValue ||
        x.PaymentFailed.HasValue ||
        x.PushNotificationsEnabled.HasValue ||
        x.EmailNotificationsEnabled.HasValue ||
        x.SmsNotificationsEnabled.HasValue;
}

public class TraderPrivacySettingsPatchValidator : AbstractValidator<TraderPrivacySettingsPatchDto>
{
    public TraderPrivacySettingsPatchValidator()
    {
        RuleFor(x => x).Must(HaveAtLeastOne)
            .WithMessage("At least one privacy field must be provided.");
    }

    private static bool HaveAtLeastOne(TraderPrivacySettingsPatchDto x) =>
        x.ShareBusinessDataWithPartners.HasValue ||
        x.AllowMarketingCommunications.HasValue ||
        x.AllowAnalyticsTracking.HasValue ||
        x.ShareShipmentDataForResearch.HasValue ||
        x.DataRetentionConsentGiven.HasValue;
}
