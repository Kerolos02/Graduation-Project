namespace TruckMate.Common.Exceptions;

public class ConflictApiException : Exception
{
    public ConflictApiException(string message) : base(message)
    {
    }
}
