using System.Globalization;

namespace TruckMate.Services.DriverTrips;

public static class TripMarketplaceFormatter
{
    private static readonly CultureInfo En = CultureInfo.GetCultureInfo("en-US");

    public static string FormatPaymentEgp(decimal amount) => $"${Math.Round(amount, 0):0} EGP";

    public static string FormatDistanceKm(decimal km) => $"{Math.Round(km, 0):0} km";

    public static string FormatWeightLbs(decimal lbs) => $"{Math.Round(lbs, 0).ToString("N0", En)} lbs";

    public static string FormatEarnEgp(decimal amount) => $"{Math.Round(amount, 0):0} EGP";

    public static string FormatEstimatedDuration(int totalMinutes)
    {
        if (totalMinutes < 60)
        {
            return $"{totalMinutes} min";
        }

        var h = totalMinutes / 60;
        var m = totalMinutes % 60;
        return m == 0 ? $"{h} hr" : $"{h} hr {m} min";
    }

    public static string FormatPostedAgo(DateTime postedAtUtc, DateTime nowUtc)
    {
        var delta = nowUtc - postedAtUtc;
        if (delta.TotalSeconds < 60)
        {
            return "Just now";
        }

        if (delta.TotalMinutes < 60)
        {
            var n = (int)delta.TotalMinutes;
            return $"{n} mins ago";
        }

        if (delta.TotalHours < 24)
        {
            var n = (int)delta.TotalHours;
            return n == 1 ? "1 hour ago" : $"{n} hours ago";
        }

        return postedAtUtc.ToString("MMM d, yyyy", En);
    }

    public static string FormatAcceptedAt(DateTime utc) =>
        utc.ToString("MMM d, yyyy • h:mm tt", En);

    public static string FormatPackages(int count, string unit) => $"{count} {unit}";

    public static string BuildGoogleMapsUrl(double lat, double lng) =>
        $"https://maps.google.com/?q={lat.ToString(CultureInfo.InvariantCulture)},{lng.ToString(CultureInfo.InvariantCulture)}";
}
