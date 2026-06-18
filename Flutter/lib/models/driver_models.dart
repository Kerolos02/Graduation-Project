// ══════════════════════════════════════════
//  DRIVER MODELS
// ══════════════════════════════════════════

enum TripStatus { available, accepted, inProgress, completed, cancelled }

class AvailableTrip {
  final String id;
  final String traderName;
  final String traderRating;
  final String origin;
  final String destination;
  final String distance;
  final String estimatedTime;
  final double price;
  final String goodsType;
  final double weightTons;
  final bool isFragile;
  final bool isRefrigerated;
  final String scheduledDate;
  final String scheduledTime;
  TripStatus status;

  AvailableTrip({
    required this.id,
    required this.traderName,
    required this.traderRating,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedTime,
    required this.price,
    required this.goodsType,
    required this.weightTons,
    required this.isFragile,
    required this.isRefrigerated,
    required this.scheduledDate,
    required this.scheduledTime,
    this.status = TripStatus.available,
  });
}

class CompletedTrip {
  final String id;
  final String date;
  final String time;
  final String origin;
  final String destination;
  final double earnings;
  final int miles;
  final TripStatus status;

  const CompletedTrip({
    required this.id,
    required this.date,
    required this.time,
    required this.origin,
    required this.destination,
    required this.earnings,
    required this.miles,
    required this.status,
  });
}

class DailyStats {
  final int tripsCompleted;
  final double earnings;
  final String onlineTime;

  const DailyStats({
    required this.tripsCompleted,
    required this.earnings,
    required this.onlineTime,
  });
}