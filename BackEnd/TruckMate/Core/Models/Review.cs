using System;

namespace TruckMate.Core.Models
{
    public class Review
    {
        public int Id { get; set; }

        // من أنهى الـ Trip
        public int TripId { get; set; }
        public Trip Trip { get; set; } = null!;

        // الـ Trader اللي بيعمل الـ Review
        public int TraderId { get; set; }
        public Trader Trader { get; set; } = null!;

        // الـ Driver اللي بيتعمله الـ Review
        public int DriverId { get; set; }
        public Driver Driver { get; set; } = null!;

        // Rating من 1 لـ 5
        public int Rating { get; set; }

        // Review text (اختياري)
        public string? Comment { get; set; }

        public bool IsDeleted { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}