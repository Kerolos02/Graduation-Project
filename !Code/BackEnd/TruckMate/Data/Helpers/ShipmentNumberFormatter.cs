namespace TruckMate.Data.Helpers;

public static class ShipmentNumberFormatter
{
    public static string Format(int numericId) => $"SHP-{numericId:D4}";
}
