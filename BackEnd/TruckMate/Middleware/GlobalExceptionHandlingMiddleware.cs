using System.Net;
using System.Text.Json;
using FluentValidation;
using TruckMate.Common.Exceptions;
using TruckMate.Core.DriverHome;

namespace TruckMate.Middleware;

public class GlobalExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlingMiddleware> _logger;

    public GlobalExceptionHandlingMiddleware(RequestDelegate next,
        ILogger<GlobalExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context).ConfigureAwait(false);
        }
        catch (ValidationException vex)
        {
            _logger.LogWarning(vex, "Validation rejected for {Path}", context.Request.Path);
            await WriteJsonAsync(context, (int)HttpStatusCode.UnprocessableEntity,
                    ApiResponse<object>.Fail(
                        "Validation failed",
                        vex.Errors.GroupBy(e => e.PropertyName)
                            .ToDictionary(g => g.Key, g => g.Select(x => x.ErrorMessage).ToArray())))
                .ConfigureAwait(false);
        }
        catch (ConflictApiException cex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.Conflict, ApiResponse<object>.Fail(cex.Message))
                .ConfigureAwait(false);
        }
        catch (NotFoundApiException nfex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.NotFound, ApiResponse<object>.Fail(nfex.Message))
                .ConfigureAwait(false);
        }
        catch (GoneApiException gox)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.Gone, ApiResponse<object>.Fail(gox.Message))
                .ConfigureAwait(false);
        }
        catch (UnauthorizedAppException uaex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.Unauthorized, ApiResponse<object>.Fail(uaex.Message))
                .ConfigureAwait(false);
        }
        catch (ForbiddenAccessException fex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.Forbidden, ApiResponse<object>.Fail(fex.Message))
                .ConfigureAwait(false);
        }
        catch (BadRequestApiException brex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.BadRequest, ApiResponse<object>.Fail(brex.Message))
                .ConfigureAwait(false);
        }
        catch (TooManyRequestsApiException trex)
        {
            await WriteJsonAsync(context, (int)HttpStatusCode.TooManyRequests, ApiResponse<object>.Fail(trex.Message))
                .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled error for {Path}", context.Request.Path);
            await WriteJsonAsync(context, (int)HttpStatusCode.InternalServerError,
                    ApiResponse<object>.Fail("An unexpected error occurred."))
                .ConfigureAwait(false);
        }
    }

    private static Task WriteJsonAsync(HttpContext ctx, int statusCode, ApiResponse<object> body)
    {
        ctx.Response.StatusCode = statusCode;
        ctx.Response.ContentType = "application/json";
        return ctx.Response.WriteAsync(JsonSerializer.Serialize(body,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));
    }
}
