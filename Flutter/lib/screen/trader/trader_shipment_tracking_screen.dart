// ════════════════════════════════════════════════════════════
//  trader_shipment_tracking_screen.dart
//  UI بالظبط زي الـ design
//  API: GET /api/trader/shipments/{shipmentId}/tracking
//       POST /api/trader/shipments/{shipmentId}/mark-delivered
//       POST /api/trader/shipments/{shipmentId}/cancel
// ════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ─── Colors ──────────────────────────────────────────────
const _kBg       = Color(0xFF0B1F35);
const _kCard     = Color(0xFF0F2A40);
const _kTeal     = Color(0xFF00D5BE);
const _kTeal2    = Color(0xFF00BBA7);
const _kBlue     = Color(0xFF2563EB);
const _kMuted    = Color(0xFF8A9BB0);
const _kRed      = Color(0xFFFF4444);
const _kRedBg    = Color(0xFF2A1015);
const _kBorder   = Color(0xFF1A3550);

// ════════════════════════════════════════════════════════════
//  Press Scale Helper
// ════════════════════════════════════════════════════════════
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _s,
          builder: (_, child) =>
              Transform.scale(scale: _s.value, child: child),
          child: widget.child,
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  Map Area — خريطة حقيقية مع mock truck movement
// ════════════════════════════════════════════════════════════
class _TrackingMapWidget extends StatefulWidget {
  final String destinationName;
  const _TrackingMapWidget({required this.destinationName});

  @override
  State<_TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<_TrackingMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Destination: Nasr City
  final LatLng _destination = const LatLng(30.0561, 31.3327);

  // Truck starts near Maadi
  double _truckLat = 30.0100;
  double _truckLng = 31.2700;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startMockTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMockTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _truckLat += 0.0018;
        _truckLng += 0.0030;
        if (_truckLat >= _destination.latitude) {
          _truckLat = _destination.latitude;
          _truckLng = _destination.longitude;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final truckPos = LatLng(_truckLat, _truckLng);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              (_truckLat + _destination.latitude) / 2,
              (_truckLng + _destination.longitude) / 2,
            ),
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            // خط متقطع من التراك لـ Destination
            PolylineLayer(
              polylines: [
               Polyline(
  points: [truckPos, _destination],
  color: _kTeal,
  strokeWidth: 3.0,
),
              ],
            ),
            MarkerLayer(
              markers: [
                // Destination label
                Marker(
                  point: _destination,
                  width: 110,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F2D).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _kTeal.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      widget.destinationName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Truck marker (زرقاء زي الـ design)
                Marker(
                  point: truckPos,
                  width: 56,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Top info card — SHIPMENT # + ETA
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _TopInfoCard(
            shipmentNumber: 'SH-1247',
            status: 'In Transit',
            etaMinutes: 45,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Top Info Card  (SHIPMENT # | ETA)
// ════════════════════════════════════════════════════════════
class _TopInfoCard extends StatelessWidget {
  final String shipmentNumber;
  final String status;
  final int etaMinutes;

  const _TopInfoCard({
    required this.shipmentNumber,
    required this.status,
    required this.etaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTeal.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHIPMENT #$shipmentNumber',
                style: TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kBlue.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: _kBlue, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ETA',
                  style: TextStyle(
                      color: _kMuted, fontSize: 11, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$etaMinutes',
                      style: const TextStyle(
                          color: _kTeal,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1),
                    ),
                    const TextSpan(
                      text: 'm',
                      style: TextStyle(
                          color: _kTeal,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Status Timeline Item
// ════════════════════════════════════════════════════════════
class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final _TimelineState state;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color outerColor;
    Color innerColor;
    Color textColor;
    Color subtitleColor;

    switch (state) {
      case _TimelineState.done:
        outerColor = _kTeal.withOpacity(0.25);
        innerColor = _kTeal;
        textColor = Colors.white;
        subtitleColor = _kMuted;
        break;
      case _TimelineState.current:
        outerColor = _kBlue.withOpacity(0.25);
        innerColor = _kBlue;
        textColor = Colors.white;
        subtitleColor = _kMuted;
        break;
      case _TimelineState.pending:
        outerColor = _kMuted.withOpacity(0.15);
        innerColor = _kMuted.withOpacity(0.4);
        textColor = _kMuted;
        subtitleColor = _kMuted.withOpacity(0.6);
        break;
    }

    return Row(
      children: [
        // Circle indicator
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: outerColor,
            shape: BoxShape.circle,
            border: Border.all(color: innerColor, width: 2),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: innerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

enum _TimelineState { done, current, pending }

// ════════════════════════════════════════════════════════════
//  Bottom Sheet Content
// ════════════════════════════════════════════════════════════
class _BottomSheetContent extends StatefulWidget {
  final VoidCallback onMarkDelivered;
  final VoidCallback onCancelShipment;
  final bool isLoading;

  const _BottomSheetContent({
    required this.onMarkDelivered,
    required this.onCancelShipment,
    required this.isLoading,
  });

  @override
  State<_BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<_BottomSheetContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: const BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // STATUS TIMELINE title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'STATUS TIMELINE',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Timeline items
              const _TimelineItem(
                title: 'Picked Up',
                subtitle: '5 hours ago',
                state: _TimelineState.done,
              ),
              const SizedBox(height: 20),
              const _TimelineItem(
                title: 'In Transit',
                subtitle: 'Current status',
                state: _TimelineState.current,
              ),
              const SizedBox(height: 20),
              const _TimelineItem(
                title: 'Delivered',
                subtitle: 'Pending',
                state: _TimelineState.pending,
              ),

              const SizedBox(height: 32),

              // Mark as Delivered button
              _PressScale(
                onTap: widget.isLoading ? () {} : widget.onMarkDelivered,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kTeal, _kTeal2],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _kTeal.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Mark as Delivered',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Shipment button
              _PressScale(
                onTap: widget.isLoading ? () {} : widget.onCancelShipment,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _kRedBg,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: _kRed.withOpacity(0.3), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel Shipment',
                    style: TextStyle(
                        color: _kRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ════════════════════════════════════════════════════════════
class TraderShipmentTrackingScreen extends StatefulWidget {
  /// shipmentId بييجي من شاشة الـ trader home لما يضغط Continue Setup
  final String shipmentId;

  const TraderShipmentTrackingScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  State<TraderShipmentTrackingScreen> createState() =>
      _TraderShipmentTrackingScreenState();
}

class _TraderShipmentTrackingScreenState
    extends State<TraderShipmentTrackingScreen> {
  bool _isLoading = false;

  // ── Mark as Delivered ──────────────────────────────────
  Future<void> _markAsDelivered() async {
    setState(() => _isLoading = true);

    // TODO: ربط بالـ API
    // final success = await context.read<TraderProvider>()
    //     .markAsDelivered(widget.shipmentId);

    await Future.delayed(const Duration(seconds: 1)); // mock
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shipment marked as delivered ✓'),
        backgroundColor: _kTeal,
      ),
    );
    Navigator.pop(context);
  }

  // ── Cancel Shipment ────────────────────────────────────
  Future<void> _cancelShipment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Shipment?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to cancel this shipment?',
          style: TextStyle(color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    // TODO: ربط بالـ API
    // await context.read<TraderProvider>().cancelShipment(widget.shipmentId);

    await Future.delayed(const Duration(seconds: 1)); // mock
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Map (upper 55%) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: const _TrackingMapWidget(
              destinationName: 'Nasr City',
            ),
          ),

          // ── Bottom sheet (lower part, draggable feel) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomSheetContent(
              onMarkDelivered: _markAsDelivered,
              onCancelShipment: _cancelShipment,
              isLoading: _isLoading,
            ),
          ),

          // ── Back button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _kTeal.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── Loading overlay ──
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: CircularProgressIndicator(
                      color: _kTeal, strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}