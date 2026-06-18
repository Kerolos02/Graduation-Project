using FluentValidation;
using TruckMate.Core.TraderMobile.Dtos;

namespace TruckMate.Validation;

public class SelectDriverRequestDtoValidator : AbstractValidator<SelectDriverRequestDto>
{
    public SelectDriverRequestDtoValidator()
    {
        RuleFor(x => x.DriverId).NotEmpty();
    }
}

public class RateDriverRequestDtoValidator : AbstractValidator<RateDriverRequestDto>
{
    public RateDriverRequestDtoValidator()
    {
        RuleFor(x => x.Rating).InclusiveBetween(1, 5);
        RuleFor(x => x.Comment).MaximumLength(500);
    }
}

public class PayInvoiceRequestDtoValidator : AbstractValidator<PayInvoiceRequestDto>
{
    public PayInvoiceRequestDtoValidator()
    {
        RuleFor(x => x.PaymentCardId).NotEmpty();
    }
}

public class ShareInvoiceRequestDtoValidator : AbstractValidator<ShareInvoiceRequestDto>
{
    private static readonly string[] AllowedMethods = ["email", "sms", "link"];

    public ShareInvoiceRequestDtoValidator()
    {
        RuleFor(x => x.Method)
            .NotEmpty()
            .Must(m => AllowedMethods.Contains(m.Trim().ToLowerInvariant()))
            .WithMessage("method must be email, sms, or link.");
    }
}

public class AddCardRequestDtoValidator : AbstractValidator<AddCardRequestDto>
{
    public AddCardRequestDtoValidator()
    {
        RuleFor(x => x.CardHolderName).NotEmpty().MinimumLength(2).MaximumLength(128);
        RuleFor(x => x.CardNumber)
            .NotEmpty()
            .Matches("^[0-9]{16}$")
            .Must(BeValidLuhn)
            .WithMessage("cardNumber is invalid.");
        RuleFor(x => x.ExpiryMonth).InclusiveBetween(1, 12);
        RuleFor(x => x.ExpiryYear).GreaterThanOrEqualTo(DateTime.UtcNow.Year);
        RuleFor(x => x.Cvv).NotEmpty().Matches("^[0-9]{3,4}$");
    }

    private static bool BeValidLuhn(string cardNumber)
    {
        var sum = 0;
        var alternate = false;
        for (var i = cardNumber.Length - 1; i >= 0; i--)
        {
            var n = cardNumber[i] - '0';
            if (alternate)
            {
                n *= 2;
                if (n > 9)
                {
                    n -= 9;
                }
            }

            sum += n;
            alternate = !alternate;
        }

        return sum % 10 == 0;
    }
}
