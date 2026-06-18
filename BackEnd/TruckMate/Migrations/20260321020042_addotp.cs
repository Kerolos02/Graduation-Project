using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TruckMate.Migrations
{
    /// <inheritdoc />
    public partial class addotp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_Trucks",
                table: "Trucks");

            migrationBuilder.RenameTable(
                name: "Trucks",
                newName: "trucks");

            migrationBuilder.AddColumn<string>(
                name: "Otp",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OtpExpiry",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AssignedDriverId",
                table: "ShipmentRequests",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "FinalCost",
                table: "ShipmentRequests",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsFragile",
                table: "ShipmentRequests",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsRefrigerated",
                table: "ShipmentRequests",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<double>(
                name: "MaxTemperature",
                table: "ShipmentRequests",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "MinTemperature",
                table: "ShipmentRequests",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PackageCount",
                table: "ShipmentRequests",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledDate",
                table: "ShipmentRequests",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<TimeSpan>(
                name: "ScheduledTime",
                table: "ShipmentRequests",
                type: "time",
                nullable: false,
                defaultValue: new TimeSpan(0, 0, 0, 0, 0));

            migrationBuilder.AddColumn<string>(
                name: "ShipmentId",
                table: "ShipmentRequests",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddPrimaryKey(
                name: "PK_trucks",
                table: "trucks",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_ShipmentRequests_AssignedDriverId",
                table: "ShipmentRequests",
                column: "AssignedDriverId");

            migrationBuilder.AddForeignKey(
                name: "FK_ShipmentRequests_Drivers_AssignedDriverId",
                table: "ShipmentRequests",
                column: "AssignedDriverId",
                principalTable: "Drivers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ShipmentRequests_Drivers_AssignedDriverId",
                table: "ShipmentRequests");

            migrationBuilder.DropPrimaryKey(
                name: "PK_trucks",
                table: "trucks");

            migrationBuilder.DropIndex(
                name: "IX_ShipmentRequests_AssignedDriverId",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "Otp",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "OtpExpiry",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AssignedDriverId",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "FinalCost",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "IsFragile",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "IsRefrigerated",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "MaxTemperature",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "MinTemperature",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "PackageCount",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "ScheduledDate",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "ScheduledTime",
                table: "ShipmentRequests");

            migrationBuilder.DropColumn(
                name: "ShipmentId",
                table: "ShipmentRequests");

            migrationBuilder.RenameTable(
                name: "trucks",
                newName: "Trucks");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Trucks",
                table: "Trucks",
                column: "Id");
        }
    }
}
