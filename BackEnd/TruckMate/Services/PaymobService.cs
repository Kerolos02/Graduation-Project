using Microsoft.Extensions.Configuration;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace TruckMate.Services.Paymob
{
    public class PaymobService
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public PaymobService(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        // ---------------------------
        // STEP 1: AUTH TOKEN
        // ---------------------------
        public async Task<string> GetAuthTokenAsync()
        {
            var apiKey = _config["Paymob:ApiKey"];

            var response = await _http.PostAsJsonAsync("https://accept.paymob.com/api/auth/tokens",
                new { api_key = apiKey });

            var result = await response.Content.ReadFromJsonAsync<AuthResponse>();
            return result.token;
        }

        // ---------------------------
        // STEP 2: CREATE ORDER
        // ---------------------------
        public async Task<int> CreateOrderAsync(string token, int amountCents)
        {
            var merchantId = _config["Paymob:MerchantId"];

            var response = await _http.PostAsJsonAsync("https://accept.paymob.com/api/ecommerce/orders", new
            {
                auth_token = token,
                delivery_needed = false,
                amount_cents = amountCents,
                currency = "EGP",
                merchant_order_id = Guid.NewGuid().ToString(),
                items = new object[] { }
            });

            var result = await response.Content.ReadFromJsonAsync<OrderResponse>();
            return result.id;
        }

        // ---------------------------
        // STEP 3: PAYMENT KEY
        // ---------------------------
        public async Task<string> GetPaymentKeyAsync(string token, int orderId, int amountCents)
        {
            var integrationId = _config["Paymob:IntegrationId"];

            var response = await _http.PostAsJsonAsync("https://accept.paymob.com/api/acceptance/payment_keys", new
            {
                auth_token = token,
                amount_cents = amountCents,
                expiration = 3600,
                order_id = orderId,
                billing_data = new
                {
                    apartment = "NA",
                    email = "test@user.com",
                    floor = "NA",
                    first_name = "Test",
                    last_name = "User",
                    street = "NA",
                    building = "NA",
                    phone_number = "01000000000",
                    city = "NA",
                    country = "NA",
                    state = "NA"
                },
                currency = "EGP",
                integration_id = integrationId
            });

            var result = await response.Content.ReadFromJsonAsync<PaymentKeyResponse>();
            return result.token;
        }

        // =======================
        // MODELS
        // =======================
        record AuthResponse(string token);
        record OrderResponse(int id);
        record PaymentKeyResponse(string token);
    }
}