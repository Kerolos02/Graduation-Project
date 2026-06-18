namespace TruckMate.Core.DriverHome.Dtos;

public class DriverStatusPatchRequest
{
    /// <summary>Online or Offline.</summary>
    public string Status { get; set; } = string.Empty;
}
