using FluentValidation;
using TruckMate.Core.DriverOffers.Dtos;

namespace TruckMate.Validation;

public class DeclineOfferRequestDtoValidator : AbstractValidator<DeclineOfferRequestDto>
{
    public DeclineOfferRequestDtoValidator()
    {
        RuleFor(x => x.Reason)
            .MaximumLength(500)
            .When(x => !string.IsNullOrWhiteSpace(x.Reason));
    }
}
