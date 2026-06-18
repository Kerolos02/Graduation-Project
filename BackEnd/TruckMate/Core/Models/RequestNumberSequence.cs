namespace TruckMate.Core.Models;

/// <summary>Singleton row (Id = 1) storing the last assigned REQ-#### number.</summary>
public class RequestNumberSequence
{
    public int Id { get; set; } = 1;

    public int LastNumber { get; set; }
}
