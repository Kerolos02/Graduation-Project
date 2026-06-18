using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TruckMate.Migrations
{
    /// <inheritdoc />
    public partial class DriverMarketplaceTripRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_DeliveryTrips_AssignedDriverId",
                table: "DeliveryTrips");

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "Traders",
                type: "nvarchar(32)",
                maxLength: 32,
                nullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "TripOfferId",
                table: "DriverOfferHistories",
                type: "uniqueidentifier",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.AddColumn<Guid>(
                name: "TripRequestId",
                table: "DriverOfferHistories",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RequestNumberSequences",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    LastNumber = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RequestNumberSequences", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "RequestNumberSequences",
                columns: new[] { "Id", "LastNumber" },
                values: new object[] { 1, 4521 });

            migrationBuilder.CreateTable(
                name: "TripRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RequestNumber = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    TraderId = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    PickupLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    PickupAddress = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    PickupLat = table.Column<double>(type: "float", nullable: false),
                    PickupLng = table.Column<double>(type: "float", nullable: false),
                    DropoffLocation = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DropoffAddress = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DropoffLat = table.Column<double>(type: "float", nullable: false),
                    DropoffLng = table.Column<double>(type: "float", nullable: false),
                    DistanceKm = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    EstimatedDurationMinutes = table.Column<int>(type: "int", nullable: false),
                    PaymentAmountEGP = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    CargoType = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    WeightLbs = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    PackagesCount = table.Column<int>(type: "int", nullable: false),
                    PackagesUnit = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    IsFragile = table.Column<bool>(type: "bit", nullable: false),
                    SpecialNotes = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    PostedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AcceptedByDriverId = table.Column<int>(type: "int", nullable: true),
                    AcceptedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Zone = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    RequiredTruckType = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    CreatedDeliveryTripId = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripRequests_DeliveryTrips_CreatedDeliveryTripId",
                        column: x => x.CreatedDeliveryTripId,
                        principalTable: "DeliveryTrips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TripRequests_Drivers_AcceptedByDriverId",
                        column: x => x.AcceptedByDriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TripRequests_Traders_TraderId",
                        column: x => x.TraderId,
                        principalTable: "Traders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "TripRequestRejections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TripRequestId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DriverId = table.Column<int>(type: "int", nullable: false),
                    RejectedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TripRequestRejections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TripRequestRejections_Drivers_DriverId",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TripRequestRejections_TripRequests_TripRequestId",
                        column: x => x.TripRequestId,
                        principalTable: "TripRequests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DriverOfferHistories_TripRequestId",
                table: "DriverOfferHistories",
                column: "TripRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_AssignedDriverId_Status",
                table: "DeliveryTrips",
                columns: new[] { "AssignedDriverId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_TripRequestRejections_DriverId_TripRequestId",
                table: "TripRequestRejections",
                columns: new[] { "DriverId", "TripRequestId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripRequestRejections_TripRequestId",
                table: "TripRequestRejections",
                column: "TripRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_TripRequests_AcceptedByDriverId",
                table: "TripRequests",
                column: "AcceptedByDriverId");

            migrationBuilder.CreateIndex(
                name: "IX_TripRequests_CreatedDeliveryTripId",
                table: "TripRequests",
                column: "CreatedDeliveryTripId");

            migrationBuilder.CreateIndex(
                name: "IX_TripRequests_RequestNumber",
                table: "TripRequests",
                column: "RequestNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripRequests_Status_PostedAt",
                table: "TripRequests",
                columns: new[] { "Status", "PostedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_TripRequests_TraderId",
                table: "TripRequests",
                column: "TraderId");

            migrationBuilder.AddForeignKey(
                name: "FK_DriverOfferHistories_TripRequests_TripRequestId",
                table: "DriverOfferHistories",
                column: "TripRequestId",
                principalTable: "TripRequests",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DriverOfferHistories_TripRequests_TripRequestId",
                table: "DriverOfferHistories");

            migrationBuilder.DropTable(
                name: "RequestNumberSequences");

            migrationBuilder.DropTable(
                name: "TripRequestRejections");

            migrationBuilder.DropTable(
                name: "TripRequests");

            migrationBuilder.DropIndex(
                name: "IX_DriverOfferHistories_TripRequestId",
                table: "DriverOfferHistories");

            migrationBuilder.DropIndex(
                name: "IX_DeliveryTrips_AssignedDriverId_Status",
                table: "DeliveryTrips");

            migrationBuilder.DropColumn(
                name: "PhoneNumber",
                table: "Traders");

            migrationBuilder.DropColumn(
                name: "TripRequestId",
                table: "DriverOfferHistories");

            migrationBuilder.AlterColumn<Guid>(
                name: "TripOfferId",
                table: "DriverOfferHistories",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryTrips_AssignedDriverId",
                table: "DeliveryTrips",
                column: "AssignedDriverId");
        }
    }
}
