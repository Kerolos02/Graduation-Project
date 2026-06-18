import '/models/trader_models.dart';

class TraderDummyData {

  static List<Shipment> shipments() {
    const origins      = ['Maadi', 'Zamalek', 'Nasr City', 'Giza', 'October', 'New Cairo'];
    const destinations = ['Nasr City', 'Heliopolis', 'Maadi', 'Downtown', 'October', 'Zamalek'];
    const goods        = ['Electronics', 'Fresh Produce', 'Textiles', 'Building Materials', 'Medical Supplies', 'Furniture'];
    const priorities   = ['Standard', 'Express', 'High Value'];
    const drivers      = ['Ahmed Hassan', 'Mohamed Ali', 'Omar Khaled', 'Youssef Ibrahim', 'Kareem Nabil', 'Hany Samir'];
    const vehicles     = ['Flatbed Truck', 'Box Truck', 'Cargo Van', 'Heavy Trailer', 'Reefer Truck', 'Curtainsider'];

    // ✅ أسباب الإلغاء — بيتعرض لما الشحنة status == cancelled
    const cancelReasons = [
      'Driver cancelled due to vehicle breakdown',
      'Shipment cancelled by trader',
      'No available drivers in the area',
      'Weather conditions prevented delivery',
      'Recipient was unavailable at drop-off location',
      'Payment issue — shipment put on hold',
    ];

    return List<Shipment>.generate(24, (index) {
      final status = ShipmentStatus.values[index % ShipmentStatus.values.length];
      final progress = switch (status) {
        ShipmentStatus.pending   => 0.22,
        ShipmentStatus.inTransit => 0.64,
        ShipmentStatus.delivered => 1.0,
        ShipmentStatus.cancelled => 0.15,
      };

      final driverName = drivers[index % drivers.length];

      return Shipment(
        id:             'SHP-${1000 + index}',
        title:          '${goods[index % goods.length]} Delivery',
        reference:      'TM-${20260 + index}',
        origin:         origins[index % origins.length],
        destination:    destinations[index % destinations.length],
        departureDate:  '2026-01-${(index % 20) + 10}',
        price:          195 + (index * 25).toDouble(),
        weightTons:     1.5 + ((index % 7) * 0.5),
        status:         status,
        progress:       progress,
        driverName:     driverName,
        driverInitials: makeInitials(driverName),          // ✅
        vehicleInfo:    vehicles[index % vehicles.length],
        goodsType:      goods[index % goods.length],
        priority:       priorities[index % priorities.length],
        // ✅ cancelReason فقط لو الشحنة متكنسلة
        cancelReason: status == ShipmentStatus.cancelled
            ? cancelReasons[index % cancelReasons.length]
            : null,
        timeline: [
          const ShipmentMilestone(label: 'Picked Up',  time: '5 hours ago',    isDone: true),
          ShipmentMilestone(
            label: 'In Transit',
            time:  'Current status',
            isDone: status == ShipmentStatus.inTransit ||
                    status == ShipmentStatus.delivered,
          ),
          ShipmentMilestone(
            label: 'Delivered',
            time:  'Pending',
            isDone: status == ShipmentStatus.delivered,
          ),
        ],
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  static List<DriverOffer> offers(List<Shipment> shipments) {
    const names    = ['محمود ناصر', 'Mohamed Ali', 'Omar Khaled', 'Youssef Ibrahim', 'Sherif Taha', 'Ibrahim Mostafa'];
    const notes    = [
      'Temperature-controlled trailer available.',
      'Can load within 2 hours from confirmation.',
      'Experienced with fragile cargo lanes.',
      'Night delivery slot available if needed.',
      'Offers live GPS tracking for the full trip.',
      'Backup driver assigned for long-haul route.',
    ];
    const vehicles = ['Flatbed Truck', 'Box Truck', 'Cargo Van', 'Flatbed Truck', 'Heavy Trailer', 'Box Truck'];
    const ratings  = [4.8, 4.9, 4.7, 4.6, 4.5, 4.8];
    const trips    = [127, 203, 89, 156, 98, 172];
    const prices   = [285, 270, 295, 280, 310, 265];

    return List<DriverOffer>.generate(24, (index) {
      final shipment   = shipments[index % shipments.length];
      final status     = OfferStatus.values[index % OfferStatus.values.length];
      final driverName = names[index % names.length];

      return DriverOffer(
        id:             'OFF-${5000 + index}',
        shipmentId:     shipment.id,
        driverName:     driverName,
        driverInitials: makeInitials(driverName),         // ✅
        rating:         ratings[index % ratings.length],
        completedTrips: trips[index % trips.length],
        price:          prices[index % prices.length].toDouble(),
        etaHours:       4 + (index % 3),
        vehicleType:    vehicles[index % vehicles.length],
        status:         status,
        note:           notes[index % notes.length],
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  static List<TraderNotification> notifications() {
    const titles = [
      'Driver submitted a new offer',
      'Shipment moved to in-transit',
      'Proof of delivery uploaded',
      'Payment request is ready',
      'Route ETA updated by driver',
      'Shipment needs confirmation',
    ];
    const subtitles = [
      'Compare driver quotes and accept the best match.',
      'Live tracking has started for this route.',
      'Receiver signature and photos are available.',
      'Review invoice and release payment.',
      'Arrival estimate changed due to traffic.',
      'Please confirm loading window before noon.',
    ];

    return List<TraderNotification>.generate(12, (index) => TraderNotification(
      id:        'NOT-${3000 + index}',
      title:     titles[index % titles.length],
      subtitle:  subtitles[index % subtitles.length],
      timeLabel: '${(index % 12) + 1}h ago',
      type:      NotificationType.values[index % NotificationType.values.length],
      isRead:    index % 3 == 0,
    ));
  }

  // ───────────────────────────────────────────────────────────────────────────
  static TraderSummary summary(List<Shipment> shipments, List<DriverOffer> offers) =>
      TraderSummary(
        totalSpent:           shipments.fold(0, (s, x) => s + x.price),
        activeShipments:      shipments.where((x) => x.isActive).length,
        pendingOffers:        offers.where((x) => x.status == OfferStatus.pending).length,
        completedDeliveries:  shipments.where((x) => x.status == ShipmentStatus.delivered).length,
      );
}