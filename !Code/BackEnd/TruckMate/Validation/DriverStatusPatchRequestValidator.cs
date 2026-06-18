using FluentValidation;
using TruckMate.Core.DriverHome.Dtos;

namespace TruckMate.Validation;

public class DriverStatusPatchRequestValidator : AbstractValidator<DriverStatusPatchRequest>
{
    public DriverStatusPatchRequestValidator()
    {
        RuleFor(x => x.Status)
            .NotEmpty()
            .Must(s => s.Equals("Online", StringComparison.OrdinalIgnoreCase)
                       || s.Equals("Offline", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Status must be Online or Offline.");
    }
}
