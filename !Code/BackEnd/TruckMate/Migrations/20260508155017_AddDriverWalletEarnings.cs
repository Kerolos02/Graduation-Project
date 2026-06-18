using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TruckMate.Migrations
{
    /// <inheritdoc />
    public partial class AddDriverWalletEarnings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Traders_Users_UserId",
                table: "Traders");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeleteRequestedAtUtc",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "EmailVerified",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastPasswordChangedAtUtc",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PhoneVerified",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledHardDeleteAtUtc",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TokenVersion",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<string>(
                name: "BusinessName",
                table: "Traders",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Traders",
                type: "nvarchar(1024)",
                maxLength: 1024,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAtUtc",
                table: "Traders",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "DeleteRequestedAtUtc",
                table: "Traders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerificationOtpExpiresUtc",
                table: "Traders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmailVerificationOtpHash",
                table: "Traders",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Traders",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "PhoneVerificationOtpExpiresUtc",
                table: "Traders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PhoneVerificationOtpHash",
                table: "Traders",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PublicId",
                table: "Traders",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledHardDeleteAtUtc",
                table: "Traders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TokenVersion",
                table: "Traders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedDeliveryTripId",
                table: "Drivers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AvailabilityStatus",
                table: "Drivers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                table: "Drivers",
                type: "nvarchar(2048)",
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CurrentZone",
                table: "Drivers",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastAvailabilityChangeUtc",
                table: "Drivers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PublicId",
                table: "Drivers",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<decimal>(
                name: "Rating",
                table: "Drivers",
                type: "decimal(3,2)",
                precision: 3,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Traders_PublicId",
                table: "Traders",
                column: "PublicId");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Drivers_PublicId",
                table: "Drivers",
                column: "PublicId");

            migrationBuilder.CreateTable(
                name: "DeliveryTrips",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AssignedDriverId = table.Column<int>(type: "int", nullable: true),
                    ShipmentNumericId = table.Column<int>(type: "int", nullable: false),
                    ShipmentNumber = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    PickupLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DropoffLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DistanceKm = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    EstimatedDurationMinutes = table.Column<int>(type: "int", nullable: false),
                    PaymentAmountEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    ScheduleStatus = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    TraderId = table.Column<int>(type: "int", nullable: false),
                    DateUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ScheduledStartTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    StartedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CompletedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Zone = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    OfferedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EarningsOnCompletionEgp = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryTrips", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DeliveryTrips_Drivers_AssignedDriverId",
                        column: x => x.AssignedDriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DeliveryTrips_Traders_TraderId",
                        column: x => x.TraderId,
                        principalTable: "Traders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DriverAuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    PerformedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    UserAgent = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    AdditionalData = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverAuditLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverAuditLogs_Drivers_DriverPublicId",
                        column: x => x.DriverPublicId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DriverDailySummaries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<int>(type: "int", nullable: false),
                    SummaryDate = table.Column<DateOnly>(type: "date", nullable: false),
                    TripsCompleted = table.Column<int>(type: "int", nullable: false),
                    EarningsEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    OnlineTimeMinutes = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverDailySummaries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverDailySummaries_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DriverNotificationPreferences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TripAssignedEnabled = table.Column<bool>(type: "bit", nullable: false),
                    TripOfferEnabled = table.Column<bool>(type: "bit", nullable: false),
                    EarningsUpdateEnabled = table.Column<bool>(type: "bit", nullable: false),
                    SystemAlertsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    PushNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    EmailNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    SmsNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverNotificationPreferences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverNotificationPreferences_Drivers_DriverPublicId",
                        column: x => x.DriverPublicId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DriverPrivacySettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShareLocationWithDispatcher = table.Column<bool>(type: "bit", nullable: false),
                    ShareTripHistoryWithThirdParties = table.Column<bool>(type: "bit", nullable: false),
                    AllowAnalyticsTracking = table.Column<bool>(type: "bit", nullable: false),
                    DataRetentionConsentGiven = table.Column<bool>(type: "bit", nullable: false),
                    ConsentGivenAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverPrivacySettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverPrivacySettings_Drivers_DriverPublicId",
                        column: x => x.DriverPublicId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LegalDocuments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Version = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    EffectiveDateUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LegalDocuments", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TraderAuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    PerformedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    UserAgent = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    AdditionalData = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderAuditLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderAuditLogs_Traders_TraderPublicId",
                        column: x => x.TraderPublicId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TraderNotificationPreferences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShipmentCreatedConfirmation = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentAssignedToDriver = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentPickedUp = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentInTransit = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentDelivered = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentDelayed = table.Column<bool>(type: "bit", nullable: false),
                    ShipmentCancelled = table.Column<bool>(type: "bit", nullable: false),
                    InvoiceGenerated = table.Column<bool>(type: "bit", nullable: false),
                    PaymentConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    PaymentFailed = table.Column<bool>(type: "bit", nullable: false),
                    PushNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    EmailNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    SmsNotificationsEnabled = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderNotificationPreferences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderNotificationPreferences_Traders_TraderPublicId",
                        column: x => x.TraderPublicId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TraderPrivacySettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShareBusinessDataWithPartners = table.Column<bool>(type: "bit", nullable: false),
                    AllowMarketingCommunications = table.Column<bool>(type: "bit", nullable: false),
                    AllowAnalyticsTracking = table.Column<bool>(type: "bit", nullable: false),
                    ShareShipmentDataForResearch = table.Column<bool>(type: "bit", nullable: false),
                    DataRetentionConsentGiven = table.Column<bool>(type: "bit", nullable: false),
                    ConsentGivenAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    GdprDataExportRequestedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    GdprDataExportDeliveredAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderPrivacySettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderPrivacySettings_Traders_TraderPublicId",
                        column: x => x.TraderPublicId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CourierShipments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TripId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClientName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    CargoType = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    WeightLbs = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    IsFragile = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourierShipments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourierShipments_DeliveryTrips_TripId",
                        column: x => x.TripId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DriverEarnings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TripId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShipmentNumber = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    PickupLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DropoffLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    AmountEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    EarnedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverEarnings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverEarnings_DeliveryTrips_TripId",
                        column: x => x.TripId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DriverEarnings_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "TripOffers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TripId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<int>(type: "int", nullable: false),
                    OfferedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    RespondedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DeclineReason = table.Column<string>(type: "nvarchar(1024)", maxLength: 1024, nullable: true),
                    CancelReason = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripOffers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripOffers_DeliveryTrips_TripId",
                        column: x => x.TripId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TripOffers_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DriverOfferHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<int>(type: "int", nullable: false),
                    TripOfferId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<int>(type: "int", nullable: false),
                    TimestampUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverOfferHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverOfferHistories_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DriverOfferHistories_TripOffers_TripOfferId",
                        column: x => x.TripOfferId,
                        principalTable: "TripOffers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Traders_PublicId",
                table: "Traders",
                column: "PublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Drivers_AssignedDeliveryTripId",
                table: "Drivers",
                column: "AssignedDeliveryTripId");

            migrationBuilder.CreateIndex(
                name: "IX_Drivers_PublicId",
                table: "Drivers",
                column: "PublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourierShipments_TripId",
                table: "CourierShipments",
                column: "TripId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_AssignedDriverId",
                table: "DeliveryTrips",
                column: "AssignedDriverId");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_ShipmentNumber",
                table: "DeliveryTrips",
                column: "ShipmentNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_Status",
                table: "DeliveryTrips",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_TraderId",
                table: "DeliveryTrips",
                column: "TraderId");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_Zone",
                table: "DeliveryTrips",
                column: "Zone");

            migrationBuilder.CreateIndex(
                name: "IX_DriverAuditLogs_DriverPublicId",
                table: "DriverAuditLogs",
                column: "DriverPublicId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverDailySummaries_DriverId_SummaryDate",
                table: "DriverDailySummaries",
                columns: new[] { "DriverId", "SummaryDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DriverEarnings_DriverId_EarnedAt",
                table: "DriverEarnings",
                columns: new[] { "DriverId", "EarnedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_DriverEarnings_DriverId_Status",
                table: "DriverEarnings",
                columns: new[] { "DriverId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_DriverEarnings_TripId",
                table: "DriverEarnings",
                column: "TripId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DriverNotificationPreferences_DriverPublicId",
                table: "DriverNotificationPreferences",
                column: "DriverPublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DriverOfferHistories_DriverId_TimestampUtc",
                table: "DriverOfferHistories",
                columns: new[] { "DriverId", "TimestampUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_DriverOfferHistories_TripOfferId",
                table: "DriverOfferHistories",
                column: "TripOfferId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverPrivacySettings_DriverPublicId",
                table: "DriverPrivacySettings",
                column: "DriverPublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LegalDocuments_Type_IsActive",
                table: "LegalDocuments",
                columns: new[] { "Type", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_TraderAuditLogs_TraderPublicId",
                table: "TraderAuditLogs",
                column: "TraderPublicId");

            migrationBuilder.CreateIndex(
                name: "IX_TraderNotificationPreferences_TraderPublicId",
                table: "TraderNotificationPreferences",
                column: "TraderPublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TraderPrivacySettings_TraderPublicId",
                table: "TraderPrivacySettings",
                column: "TraderPublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripOffers_DriverId_Status",
                table: "TripOffers",
                columns: new[] { "DriverId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_TripOffers_ExpiresAtUtc_Status",
                table: "TripOffers",
                columns: new[] { "ExpiresAtUtc", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_TripOffers_TripId_Status",
                table: "TripOffers",
                columns: new[] { "TripId", "Status" });

            migrationBuilder.AddForeignKey(
                name: "FK_Drivers_DeliveryTrips_AssignedDeliveryTripId",
                table: "Drivers",
                column: "AssignedDeliveryTripId",
                principalTable: "DeliveryTrips",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Traders_Users_UserId",
                table: "Traders",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Drivers_DeliveryTrips_AssignedDeliveryTripId",
                table: "Drivers");

            migrationBuilder.DropForeignKey(
                name: "FK_Traders_Users_UserId",
                table: "Traders");

            migrationBuilder.DropTable(
                name: "CourierShipments");

            migrationBuilder.DropTable(
                name: "DriverAuditLogs");

            migrationBuilder.DropTable(
                name: "DriverDailySummaries");

            migrationBuilder.DropTable(
                name: "DriverEarnings");

            migrationBuilder.DropTable(
                name: "DriverNotificationPreferences");

            migrationBuilder.DropTable(
                name: "DriverOfferHistories");

            migrationBuilder.DropTable(
                name: "DriverPrivacySettings");

            migrationBuilder.DropTable(
                name: "LegalDocuments");

            migrationBuilder.DropTable(
                name: "TraderAuditLogs");

            migrationBuilder.DropTable(
                name: "TraderNotificationPreferences");

            migrationBuilder.DropTable(
                name: "TraderPrivacySettings");

            migrationBuilder.DropTable(
                name: "TripOffers");

            migrationBuilder.DropTable(
                name: "DeliveryTrips");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Traders_PublicId",
                table: "Traders");

            migrationBuilder.DropIndex(
                name: "IX_Traders_PublicId",
                table: "Traders");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Drivers_PublicId",
                table: "Drivers");

            migrationBuilder.DropIndex(
                name: "IX_Drivers_AssignedDeliveryTripId",
                table: "Drivers");

            migrationBuilder.DropIndex(
                name: "IX_Drivers_PublicId",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "DeleteRequestedAtUtc",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "EmailVerified",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LastPasswordChangedAtUtc",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PhoneVerified",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "ScheduledHardDeleteAtUtc",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TokenVersion",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CreatedAtUtc",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "DeleteRequestedAtUtc",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "EmailVerificationOtpExpiresUtc",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "EmailVerificationOtpHash",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "PhoneVerificationOtpExpiresUtc",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "PhoneVerificationOtpHash",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "PublicId",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "ScheduledHardDeleteAtUtc",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "TokenVersion",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "AssignedDeliveryTripId",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "AvailabilityStatus",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "CurrentZone",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "LastAvailabilityChangeUtc",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "PublicId",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "Rating",
                table: "Drivers");

            migrationBuilder.AlterColumn<string>(
                name: "BusinessName",
                table: "Traders",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(512)",
                oldMaxLength: 512);

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Traders",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(1024)",
                oldMaxLength: 1024);

            migrationBuilder.AddForeignKey(
                name: "FK_Traders_Users_UserId",
                table: "Traders",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
