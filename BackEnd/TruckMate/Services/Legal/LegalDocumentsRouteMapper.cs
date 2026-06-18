using TruckMate.Core.Enums;

namespace TruckMate.Services.Legal;

public static class LegalDocumentsRouteMapper
{
    public static LegalDocumentType? TryMap(string routeSegment)
    {
        return routeSegment.Trim().ToLowerInvariant() switch
        {
            "terms" => LegalDocumentType.TermsOfService,
            "privacy" => LegalDocumentType.PrivacyPolicy,
            "agreement" => LegalDocumentType.UserAgreement,
            _ => null
        };
    }
}
