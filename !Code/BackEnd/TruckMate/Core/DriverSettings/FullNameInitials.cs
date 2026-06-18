using System.Globalization;
using System.Text;

namespace TruckMate.Core.DriverSettings;

public static class FullNameInitials
{
    /// <summary>First letter of first name + first letter of last name, uppercased.</summary>
    public static string FromFullName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            return "??";
        }

        var parts = fullName.Trim().Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
        {
            return "??";
        }

        if (parts.Length == 1)
        {
            var w = parts[0];
            return w.Length >= 2
                ? char.ToUpper(w[0], CultureInfo.InvariantCulture).ToString() +
                  char.ToUpper(w[1], CultureInfo.InvariantCulture).ToString()
                : char.ToUpper(w[0], CultureInfo.InvariantCulture).ToString();
        }

        var first = parts[0];
        var last = parts[^1];
        var sb = new StringBuilder(2);
        sb.Append(char.ToUpper(first[0], CultureInfo.InvariantCulture));
        sb.Append(char.ToUpper(last[0], CultureInfo.InvariantCulture));
        return sb.ToString();
    }
}
