namespace TruckMate.Core.DriverWallet.Dtos;

public class DriverWalletTripsResponseDto
{
    public string Filter { get; set; } = "all";
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public List<DriverWalletTripItemDto> Trips { get; set; } = new();
}
