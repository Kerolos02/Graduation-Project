import 'package:flutter/material.dart';

enum ShipmentStatus { pending, inTransit, delivered, cancelled }

enum OfferStatus { pending, accepted, rejected }

enum NotificationType { shipment, offer, payment, system }

class ShipmentMilestone {
  const ShipmentMilestone({
    required this.label,
    required this.time,
    required this.isDone,
  });
  final String label;
  final String time;
  final bool isDone;
}

class Shipment {
  const Shipment({
    required this.id,
    required this.title,
    required this.reference,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.price,
    required this.weightTons,
    required this.status,
    required this.progress,
    required this.driverName,
    required this.driverInitials, // ✅ جديد
    required this.vehicleInfo,
    required this.goodsType,
    required this.priority,
    required this.timeline,
    this.cancelReason,             // ✅ جديد — nullable
  });

  final String id;
  final String title;
  final String reference;
  final String origin;
  final String destination;
  final String departureDate;
  final double price;
  final double weightTons;
  final ShipmentStatus status;
  final double progress;
  final String driverName;
  final String driverInitials;   // ✅ جديد
  final String vehicleInfo;
  final String goodsType;
  final String priority;
  final List<ShipmentMilestone> timeline;
  final String? cancelReason;    // ✅ جديد

  bool get isActive =>
      status == ShipmentStatus.pending || status == ShipmentStatus.inTransit;
}

class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.shipmentId,
    required this.driverName,
    required this.driverInitials, // ✅ جديد
    required this.rating,
    required this.completedTrips,
    required this.price,
    required this.etaHours,
    required this.vehicleType,
    required this.status,
    required this.note,
  });

  final String id;
  final String shipmentId;
  final String driverName;
  final String driverInitials;   // ✅ جديد
  final double rating;
  final int completedTrips;
  final double price;
  final int etaHours;
  final String vehicleType;
  final OfferStatus status;
  final String note;
}

class TraderNotification {
  const TraderNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.type,
    required this.isRead,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final NotificationType type;
  final bool isRead;
}

class TraderSummary {
  const TraderSummary({
    required this.totalSpent,
    required this.activeShipments,
    required this.pendingOffers,
    required this.completedDeliveries,
  });

  final double totalSpent;
  final int activeShipments;
  final int pendingOffers;
  final int completedDeliveries;
}

// ── Status helpers ─────────────────────────────────────────────────────────────
Color shipmentStatusColor(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.pending:   return const Color(0xFFF3B64C);
    case ShipmentStatus.inTransit: return const Color(0xFF45D6D1);
    case ShipmentStatus.delivered: return const Color(0xFF5CD67A);
    case ShipmentStatus.cancelled: return const Color(0xFFFF6C7A);
  }
}

String shipmentStatusLabel(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.pending:   return 'Pending';
    case ShipmentStatus.inTransit: return 'In Transit';
    case ShipmentStatus.delivered: return 'Delivered';
    case ShipmentStatus.cancelled: return 'Cancelled';
  }
}

Color offerStatusColor(OfferStatus status) {
  switch (status) {
    case OfferStatus.pending:  return const Color(0xFFF3B64C);
    case OfferStatus.accepted: return const Color(0xFF5CD67A);
    case OfferStatus.rejected: return const Color(0xFFFF6C7A);
  }
}

IconData notificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.shipment: return Icons.local_shipping_outlined;
    case NotificationType.offer:    return Icons.handshake_outlined;
    case NotificationType.payment:  return Icons.account_balance_wallet_outlined;
    case NotificationType.system:   return Icons.info_outline;
  }
}

// ── Initials helper ────────────────────────────────────────────────────────────
String makeInitials(String name) =>
    name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();