using Microsoft.OpenApi.Any;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using TruckMate.Core.DriverTrips.Dtos;

namespace TruckMate.Swagger;

public class DriverMarketplaceSwaggerSchemaFilter : ISchemaFilter
{
    public void Apply(OpenApiSchema schema, SchemaFilterContext context)
    {
        if (context.Type == typeof(AvailableTripRequestCardDto))
        {
            schema.Example = new OpenApiObject
            {
                ["requestId"] = new OpenApiString("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
                ["requestNumber"] = new OpenApiString("REQ-4522"),
                ["offeredPaymentEGP"] = new OpenApiDouble(240),
                ["offeredPaymentFormatted"] = new OpenApiString("$240 EGP"),
                ["pickupLocation"] = new OpenApiString("Cairo Distribution Hub"),
                ["dropoffLocation"] = new OpenApiString("Alexandria Port Terminal"),
                ["distanceKm"] = new OpenApiDouble(120),
                ["distanceFormatted"] = new OpenApiString("120 km"),
                ["estimatedDurationMinutes"] = new OpenApiInteger(150),
                ["estimatedDurationFormatted"] = new OpenApiString("2 hr 30 min"),
                ["weightLbs"] = new OpenApiDouble(3200),
                ["weightFormatted"] = new OpenApiString("3,200 lbs"),
                ["cargoType"] = new OpenApiString("Construction Materials"),
                ["postedAt"] = new OpenApiString("2026-04-25T14:25:00Z"),
                ["postedAgoFormatted"] = new OpenApiString("5 mins ago")
            };
        }
        else if (context.Type == typeof(RejectTripRequestRequestDto))
        {
            schema.Example = new OpenApiObject
            {
                ["reason"] = new OpenApiString("Schedule conflict")
            };
        }
        else if (context.Type == typeof(TripRequestAcceptanceDto))
        {
            schema.Example = new OpenApiObject
            {
                ["requestId"] = new OpenApiString("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
                ["requestNumber"] = new OpenApiString("REQ-4522"),
                ["tripId"] = new OpenApiString("8d9e0f1a-2b3c-4d5e-6f70-8192a3b4c5d6"),
                ["route"] = new OpenApiObject
                {
                    ["pickupLocation"] = new OpenApiString("Cairo Distribution Hub"),
                    ["dropoffLocation"] = new OpenApiString("Alexandria Port Terminal")
                },
                ["youllEarnEGP"] = new OpenApiDouble(240),
                ["youllEarnFormatted"] = new OpenApiString("240 EGP"),
                ["nextStep"] = new OpenApiString("Navigate to the pickup location and confirm arrival"),
                ["pickupNavigationUrl"] = new OpenApiString("https://maps.google.com/?q=30.0626,31.3361")
            };
        }
    }
}
