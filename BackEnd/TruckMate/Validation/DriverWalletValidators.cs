using FluentValidation;
using TruckMate.Core.DriverWallet.Dtos;

namespace TruckMate.Validation;

public class DriverWalletTripsQueryDtoValidator : AbstractValidator<DriverWalletTripsQueryDto>
{
    private static readonly string[] AllowedFilters = ["all", "this_week", "this_month"];

    public DriverWalletTripsQueryDtoValidator()
    {
        RuleFor(x => x.Filter)
            .Must(v => string.IsNullOrWhiteSpace(v) || AllowedFilters.Contains(v.Trim().ToLowerInvariant()))
            .WithMessage("filter must be one of: all, this_week, this_month.");

        RuleFor(x => x.Page)
            .GreaterThanOrEqualTo(1);

        RuleFor(x => x.PageSize)
            .InclusiveBetween(1, 50);
    }
}
