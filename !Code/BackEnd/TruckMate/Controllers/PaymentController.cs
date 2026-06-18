using Microsoft.AspNetCore.Mvc;
using TruckMate.Services.Paymob;

namespace TruckMate.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly PaymobService _paymob;

        public PaymentController(PaymobService paymob)
        {
            _paymob = paymob;
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreatePayment([FromBody] int amount)
        {
            int amountCents = amount * 100;

            var authToken = await _paymob.GetAuthTokenAsync();
            var orderId = await _paymob.CreateOrderAsync(authToken, amountCents);
            var paymentKey = await _paymob.GetPaymentKeyAsync(authToken, orderId, amountCents);

            return Ok(new
            {
                iframe_url = $"https://accept.paymob.com/api/acceptance/iframes/{HttpContext.RequestServices
                   .GetService<IConfiguration>()["Paymob:IframeId"]}?payment_token={paymentKey}"
            });
        }
    }
}