using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TruckMate.Migrations
{
    /// <inheritdoc />
    public partial class AddTraderMobileScreensModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_DeliveryTrips_TraderId",
                table: "DeliveryTrips");

            migrationBuilder.AddColumn<string>(
                name: "AvatarColor",
                table: "Drivers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "IsVerified",
                table: "Drivers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<double>(
                name: "LastKnownLatitude",
                table: "Drivers",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "LastKnownLongitude",
                table: "Drivers",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLocationUpdatedAtUtc",
                table: "Drivers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ReviewCount",
                table: "Drivers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalTrips",
                table: "Drivers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalYears",
                table: "Drivers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "VehicleType",
                table: "Drivers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "AssignedAtUtc",
                table: "DeliveryTrips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAtUtc",
                table: "DeliveryTrips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DropoffCoordinatesLat",
                table: "DeliveryTrips",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DropoffCoordinatesLng",
                table: "DeliveryTrips",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EstimatedDeliveryTimeUtc",
                table: "DeliveryTrips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "InTransitAtUtc",
                table: "DeliveryTrips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PackagesCount",
                table: "DeliveryTrips",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "PickedUpAtUtc",
                table: "DeliveryTrips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupCoordinatesLat",
                table: "DeliveryTrips",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupCoordinatesLng",
                table: "DeliveryTrips",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TotalWeightLbs",
                table: "DeliveryTrips",
                type: "decimal(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.CreateTable(
                name: "DriverReviews",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Rating = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TripId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverReviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverReviews_Drivers_DriverPublicId",
                        column: x => x.DriverPublicId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DriverReviews_Traders_TraderPublicId",
                        column: x => x.TraderPublicId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DriverVehicles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverPublicId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false),
                    Model = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    LicensePlate = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverVehicles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverVehicles_Drivers_DriverPublicId",
                        column: x => x.DriverPublicId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Invoices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    InvoiceNumber = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    ShipmentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    InvoiceDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    BasePriceEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    ServiceFeeEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TaxEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalAmountEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    PaidAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PaymentMethod = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Invoices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Invoices_DeliveryTrips_ShipmentId",
                        column: x => x.ShipmentId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Invoices_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Invoices_Traders_TraderId",
                        column: x => x.TraderId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ShipmentStatusHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShipmentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    OccurredAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShipmentStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShipmentStatusHistories_DeliveryTrips_ShipmentId",
                        column: x => x.ShipmentId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TraderPaymentCards",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CardHolderName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Last4Digits = table.Column<string>(type: "nvarchar(4)", maxLength: 4, nullable: false),
                    CardBrand = table.Column<int>(type: "int", nullable: false),
                    ExpiryMonth = table.Column<int>(type: "int", nullable: false),
                    ExpiryYear = table.Column<int>(type: "int", nullable: false),
                    IsDefault = table.Column<bool>(type: "bit", nullable: false),
                    TokenizedCardId = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderPaymentCards", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderPaymentCards_Traders_TraderId",
                        column: x => x.TraderId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TraderWallets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TraderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BalanceEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalSpentEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TraderWallets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TraderWallets_Traders_TraderId",
                        column: x => x.TraderId,
                        principalTable: "Traders",
                        principalColumn: "PublicId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_TraderId_Status",
                table: "DeliveryTrips",
                columns: new[] { "TraderId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_DriverReviews_DriverPublicId_ReviewedAt",
                table: "DriverReviews",
                columns: new[] { "DriverPublicId", "ReviewedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_DriverReviews_TraderPublicId",
                table: "DriverReviews",
                column: "TraderPublicId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverReviews_TripId_TraderPublicId",
                table: "DriverReviews",
                columns: new[] { "TripId", "TraderPublicId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DriverVehicles_DriverPublicId",
                table: "DriverVehicles",
                column: "DriverPublicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Invoices_DriverId",
                table: "Invoices",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_Invoices_ShipmentId",
                table: "Invoices",
                column: "ShipmentId");

            migrationBuilder.CreateIndex(
                name: "IX_Invoices_TraderId_Status",
                table: "Invoices",
                columns: new[] { "TraderId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_ShipmentStatusHistories_ShipmentId_OccurredAt",
                table: "ShipmentStatusHistories",
                columns: new[] { "ShipmentId", "OccurredAt" });

            migrationBuilder.CreateIndex(
                name: "IX_TraderPaymentCards_TraderId_IsDefault",
                table: "TraderPaymentCards",
                columns: new[] { "TraderId", "IsDefault" });

            migrationBuilder.CreateIndex(
                name: "IX_TraderWallets_TraderId",
                table: "TraderWallets",
                column: "TraderId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DriverReviews");

            migrationBuilder.DropTable(
                name: "DriverVehicles");

            migrationBuilder.DropTable(
                name: "Invoices");

            migrationBuilder.DropTable(
                name: "ShipmentStatusHistories");

            migrationBuilder.DropTable(
                name: "TraderPaymentCards");

            migrationBuilder.DropTable(
                name: "TraderWallets");

            migrationBuilder.DropIndex(
                name: "IX_DeliveryTrips_TraderId_Status",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "AvatarColor",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "IsVerified",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "LastKnownLatitude",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "LastKnownLongitude",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "LastLocationUpdatedAtUtc",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "ReviewCount",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "TotalTrips",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "TotalYears",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "VehicleType",
                table: "Drivers");

            migrationBuilder.DropColumn(
                name: "AssignedAtUtc",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "CancelledAtUtc",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "DropoffCoordinatesLat",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "DropoffCoordinatesLng",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "EstimatedDeliveryTimeUtc",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "InTransitAtUtc",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "PackagesCount",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "PickedUpAtUtc",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "PickupCoordinatesLat",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "PickupCoordinatesLng",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "TotalWeightLbs",
                table: "DeliveryTrips");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_TraderId",
                table: "DeliveryTrips",
                column: "TraderId");
        }
    }
}
