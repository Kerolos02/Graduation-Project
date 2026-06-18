using System.Reflection;
using System.Text;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using TruckMate.API.Controllers;
using TruckMate.API.Services;
using TruckMate.BackgroundServices;
using TruckMate.Core.DriverHome;
using TruckMate.Data.Context;
using TruckMate.Data.UnitOfWork;
using TruckMate.Hubs;
using TruckMate.Mappings;
using TruckMate.Middleware;
using TruckMate.Services;
using TruckMate.Services.Accounts;
using TruckMate.Services.Auth;
using TruckMate.Services.Audit;
using TruckMate.Services.DriverHome;
using TruckMate.Services.DriverSettings;
using TruckMate.Services.DriverWallet;
using TruckMate.Services.Legal;
using TruckMate.Services.Notifications;
using TruckMate.Services.Paymob;
using TruckMate.Services.TraderMobile;
using TruckMate.Services.TraderSettings;
using TruckMate.Services.DriverTrips;
using TruckMate.Swagger;
using TruckMate.Validation;
using TruckMate.Core.TraderMobile;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IShipmentService, ShipmentService>();
builder.Services.AddScoped<IAuthSessionService, AuthSessionService>();
builder.Services.AddDbContext<TruckMateDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));


////////////////////////////////
builder.Services.AddCors(options =>
{
    options.AddPolicy("MyPolicy", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});
//////////////////////////////////////////


builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]
                    ?? throw new InvalidOperationException("Jwt:Key is not configured.")))
        };

        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/hubs/driver"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = ctx =>
    {
        var errors = ctx.ModelState
            .Where(kv => kv.Value?.Errors.Count > 0)
            .ToDictionary(
                kv => kv.Key,
                kv => kv.Value!.Errors.Select(e => string.IsNullOrEmpty(e.ErrorMessage) ? "Invalid value." : e.ErrorMessage)
                    .ToArray());
        return new BadRequestObjectResult(ApiResponse<object>.Fail("Validation failed", errors));
    };
});

builder.Services.AddHttpClient<PaymobService>();
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();

builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<DriverStatusPatchRequestValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<ChangePasswordRequestValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<TraderNotificationPreferencesPatchValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<DeclineOfferRequestDtoValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<DriverWalletTripsQueryDtoValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<SelectDriverRequestDtoValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<MarketplaceAvailableRequestsQueryValidator>();
builder.Services.AddValidatorsFromAssemblyContaining<RejectTripRequestRequestDtoValidator>();

builder.Services.AddAutoMapper(typeof(DriverHomeMappingProfile), typeof(DriverSettingsMappingProfile),
    typeof(TraderSettingsMappingProfile), typeof(DriverWalletMappingProfile), typeof(DriverTripsMappingProfile));

builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddSingleton<IMarketplaceRequestCacheBumper, MarketplaceRequestCacheBumper>();
builder.Services.AddScoped<IRequestNumberGenerator, RequestNumberGenerator>();
builder.Services.AddScoped<IDriverMarketplacePublisher, DriverMarketplacePublisher>();
builder.Services.AddScoped<ITripRequestService, TripRequestService>();
builder.Services.AddScoped<IDriverHomeService, DriverHomeService>();
builder.Services.AddScoped<IDriverRealtimePublisher, DriverRealtimePublisher>();
builder.Services.AddScoped<ICourierTripDispatchService, CourierTripDispatchService>();
builder.Services.AddScoped<ITripDispatchService, TripDispatchService>();
builder.Services.AddScoped<IDriverOfferService, DriverOfferService>();
builder.Services.AddScoped<IDriverWalletService, DriverWalletService>();
builder.Services.AddScoped<ITraderMobileService, TraderMobileService>();
builder.Services.AddScoped<IPricingService, PricingService>();
builder.Services.AddScoped<IPaymentGatewayService, PaymentGatewayService>();
builder.Services.AddScoped<ICancellationFeeService, CancellationFeeService>();
builder.Services.AddScoped<ITraderRealtimePublisher, TraderRealtimePublisher>();
builder.Services.AddScoped<IDriverNotificationPreferenceGate, DriverNotificationPreferenceGate>();

builder.Services.AddScoped<IEmailService, EmailService>();

builder.Services.AddScoped<IAuditLogService, AuditLogService>();
builder.Services.AddScoped<ISmsService, SmsService>();
builder.Services.AddScoped<ILegalDocumentService, LegalDocumentService>();
builder.Services.AddScoped<IDriverSettingsService, DriverSettingsService>();
builder.Services.AddScoped<TraderAdvancedSettingsService>();
builder.Services.AddScoped<ITraderSettingsService>(sp => sp.GetRequiredService<TraderAdvancedSettingsService>());
builder.Services.AddScoped<ITraderNotificationPreferencesService>(sp =>
    sp.GetRequiredService<TraderAdvancedSettingsService>());
builder.Services.AddScoped<ITraderPrivacyService>(sp => sp.GetRequiredService<TraderAdvancedSettingsService>());
builder.Services.AddScoped<IAccountDeletionScheduler, AccountDeletionScheduler>();
builder.Services.AddScoped<IAccountHardDeletionExecutor, AccountHardDeletionExecutor>();

builder.Services.AddHostedService<DriverOnlineTimeBackgroundService>();
builder.Services.AddHostedService<AccountDeletionSweepHostedService>();
builder.Services.AddHostedService<TraderGdprDataExportHostedService>();
builder.Services.AddHostedService<OfferExpiryService>();
builder.Services.AddHostedService<RequestExpiryBackgroundService>();
builder.Services.Configure<PricingConfig>(builder.Configuration.GetSection("PricingConfig"));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TruckMate API", Version = "v1" });

    var xml = Path.Combine(AppContext.BaseDirectory,
        $"{Assembly.GetExecutingAssembly().GetName().Name}.xml");
    if (File.Exists(xml))
    {
        c.IncludeXmlComments(xml, includeControllerXmlComments: true);
    }

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter: Bearer {your token}"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });

    c.SchemaFilter<DriverMarketplaceSwaggerSchemaFilter>();
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

app.UseMiddleware<GlobalExceptionHandlingMiddleware>();
app.UseRouting();

///////////////////////////
app.UseCors("MyPolicy");
///////////////////////////////


app.UseAuthentication();
app.UseMiddleware<TokenVersionValidationMiddleware>();


app.UseAuthorization();

app.MapControllers();
app.MapHub<DriverHub>("/hubs/driver");
app.MapHub<TraderHub>("/hubs/trader");
app.MapGet("/", () => Results.Ok(new
{
    success = true,
    message = "TruckMate API is running"
}));
app.MapGet("/health", () => Results.Ok(new
{
    success = true,
    status = "Healthy"
}));


app.UseStaticFiles();


app.Run();



