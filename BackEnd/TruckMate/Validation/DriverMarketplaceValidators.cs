using FluentValidation;
using TruckMate.Core.DriverTrips.Dtos;

namespace TruckMate.Validation;

public class MarketplaceAvailableRequestsQueryValidator : AbstractValidator<MarketplaceAvailableRequestsQuery>
{
    public MarketplaceAvailableRequestsQueryValidator()
    {
        RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
        RuleFor(x => x.PageSize).InclusiveBetween(1, 100);
        RuleFor(x => x.SortBy)
            .Must(s => s is "price_desc" or "distance_asc" or "posted_desc")
            .WithMessage("sortBy must be price_desc, distance_asc, or posted_desc.");
    }
}

public class MarketplaceAvailableRequestsQuery
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string SortBy { get; set; } = "posted_desc";
}

public class MarketplaceMyTripsQueryValidator : AbstractValidator<MarketplaceMyTripsQuery>
{
    public MarketplaceMyTripsQueryValidator()
    {
        RuleFor(x => x.Page).GreaterThanOrEqualTo(1);
        RuleFor(x => x.PageSize).InclusiveBetween(1, 100);
        RuleFor(x => x.Status)
            .Must(s => s is "active" or "completed" or "all")
            .WithMessage("status must be active, completed, or all.");
    }
}

public class MarketplaceMyTripsQuery
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string Status { get; set; } = "all";
}

public class RejectTripRequestRequestDtoValidator : AbstractValidator<RejectTripRequestRequestDto>
{
    public RejectTripRequestRequestDtoValidator()
    {
        RuleFor(x => x.Reason).MaximumLength(2000);
    }
}
