namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletTripsQueryDto
{
    public string Filter { get; set; } = "all";
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
