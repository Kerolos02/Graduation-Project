namespace TruckMate.Common.Exceptions;

public class TooManyRequestsApiException : Exception
{
    public TooManyRequestsApiException(string message) : base(message)
    {
    }
}
