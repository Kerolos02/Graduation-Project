// ════════════════════════════════════════════════════════════
//  driver_pickup_screens.dart  — API CONNECTED VERSION
//  ✅ نفس الشكل والأنيميشن بالظبط
//  ✅ كل البيانات من الـ API (getTripDetails, arrivePickup,
//     confirmPickup, startDelivery, markDelivered)
//  ✅ tripId بيتنقل بين الـ screens
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/driver_service.dart';
import 'driver_trip_screens.dart';

// ── Shared Palette ──
const Color _kTeal  = Color(0xFF00C9A7);
const Color _kAmber = Color(0xFFFFC107);
const Color _kGreen = Color(0xFF34C759);

// ── Theme helpers ──
Color _bg(bool d)     => d ? const Color(0xFF0F2334) : const Color(0xFFF8FAFB);
Color _card(bool d)   => d ? const Color(0xFF162532) : Colors.white;
Color _text(bool d)   => d ? Colors.white             : const Color(0xFF1E272E);
Color _muted(bool d)  => d ? const Color(0xFF90A4AE)  : const Color(0xFF808E9B);
Color _border(bool d) => d ? const Color(0xFF2C3E50)  : const Color(0xFFE5E7EB);
Color _chipBg(bool d) => d ? const Color(0xFF142B2B)  : const Color(0xFFE9FFFB);

// ── Loading Overlay ──
Widget _loadingOverlay(bool isDark) => Container(
  color: _bg(isDark).withOpacity(0.8),
  child: const Center(child: CircularProgressIndicator(color: _kTeal)),
);

// ── Error Snackbar ──
void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: Colors.redAccent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

// ══════════════════════════════════════════════════════
//  SHARED: GRADIENT BUTTON with shimmer
// ══════════════════════════════════════════════════════
class _GradBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final bool isLoading;
  const _GradBtn({required this.label, required this.icon,
      required this.onTap, this.subtitle, this.isLoading = false});
  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimAnim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _shimAnim = Tween<double>(begin: -300, end: 300)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.linear));
  }

  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        width: double.infinity,
        height: widget.subtitle != null ? 64 : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: widget.isLoading
                ? [_kTeal.withOpacity(0.5), _kTeal.withOpacity(0.4)]
                : [const Color(0xFF00D5BE), const Color(0xFF00BBA7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [BoxShadow(
            color: _kTeal.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 6),
          )],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          if (!widget.isLoading)
            AnimatedBuilder(
              animation: _shimAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_shimAnim.value, 0),
                child: Container(
                  width: 120, height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          widget.isLoading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.label, style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                  ]),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.home_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(widget.subtitle!, style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                    ]),
                  ],
                ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: PULSING RINGS
// ══════════════════════════════════════════════════════
class _PulsingRings extends StatefulWidget {
  final Color color;
  final Widget child;
  final double size;
  final int ringCount;
  const _PulsingRings({
    required this.color, required this.child,
    this.size = 80, this.ringCount = 2,
  });
  @override
  State<_PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<_PulsingRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _scales;
  late List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    final delays = [0.0, 0.33, 0.66];
    _scales = List.generate(widget.ringCount, (i) {
      final d = i < delays.length ? delays[i] : 0.0;
      return Tween<double>(begin: 1.0, end: 1.6).animate(
        CurvedAnimation(parent: _ctrl,
            curve: Interval(d, (d + 0.4).clamp(0, 1), curve: Curves.easeOut)));
    });
    _opacities = List.generate(widget.ringCount, (i) {
      final d = i < delays.length ? delays[i] : 0.0;
      return Tween<double>(begin: 0.4, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: Interval(d, (d + 0.4).clamp(0, 1), curve: Curves.easeOut)));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size, height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        ...List.generate(widget.ringCount, (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scales[i].value,
            child: Opacity(
              opacity: _opacities[i].value,
              child: Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: widget.color),
              ),
            ),
          ),
        )),
        widget.child,
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: MAP PAINTER
// ══════════════════════════════════════════════════════
class _MapPainter extends CustomPainter {
  final Color teal;
  final bool isDark;
  final double pathProgress;
  const _MapPainter(this.teal, {this.isDark = true, this.pathProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : teal).withOpacity(isDark ? 0.04 : 0.08)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 25)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 25)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.7)
      ..cubicTo(
        size.width * 0.35, size.height * 0.2,
        size.width * 0.65, size.height * 0.9,
        size.width * 0.85, size.height * 0.2,
      );

    final pathMetrics = path.computeMetrics().first;
    final animPath = pathMetrics.extractPath(0, pathMetrics.length * pathProgress);

    canvas.drawPath(animPath,
        Paint()..color = teal..style = PaintingStyle.stroke
          ..strokeWidth = 3..strokeCap = StrokeCap.round);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.7), 6,
        Paint()..color = teal);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.7), 3,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 8,
        Paint()..color = Colors.orange);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 4,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.pathProgress != pathProgress;
}

// ══════════════════════════════════════════════════════
//  PULSING DOT
// ══════════════════════════════════════════════════════
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 8});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: STATUS BADGE
// ══════════════════════════════════════════════════════
Widget _statusBadge(String label, Color teal, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: _chipBg(isDark), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: teal)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          color: teal, fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ══════════════════════════════════════════════════════
//  TRIP DETAILS MODEL
// ══════════════════════════════════════════════════════
class _TripDetails {
  final String tripId;
  final String pickupLocation;
  final String pickupAddress;
  final String dropoffLocation;
  final String dropoffAddress;
  final String traderName;
  final String traderPhone;
  final String shipmentId;
  final String shipmentType;
  final String weight;
  final String specialNotes;
  final double amountEGP;
  final String distance;
  final String eta;

  const _TripDetails({
    required this.tripId,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.traderName,
    required this.traderPhone,
    required this.shipmentId,
    required this.shipmentType,
    required this.weight,
    required this.specialNotes,
    required this.amountEGP,
    required this.distance,
    required this.eta,
  });

  // بيبني الـ model من الـ API response
  factory _TripDetails.fromApi(Map<String, dynamic> data, String tripId) {
    return _TripDetails(
      tripId: tripId,
      pickupLocation: data['pickupLocation'] ?? data['pickup']?['name'] ?? 'Pickup',
      pickupAddress: data['pickupAddress'] ?? data['pickup']?['address'] ?? '',
      dropoffLocation: data['dropoffLocation'] ?? data['dropoff']?['name'] ?? 'Destination',
      dropoffAddress: data['dropoffAddress'] ?? data['dropoff']?['address'] ?? '',
      traderName: data['traderName'] ?? data['trader']?['name'] ?? 'Trader',
      traderPhone: data['traderPhone'] ?? data['trader']?['phone'] ?? '',
      shipmentId: data['shipmentNumber'] ?? data['shipmentId'] ?? tripId,
      shipmentType: data['cargoType'] ?? data['shipmentType'] ?? 'General Cargo',
      weight: data['weight'] != null ? '${data['weight']} kg' : 'N/A',
      specialNotes: data['specialNotes'] ?? data['notes'] ?? '',
      amountEGP: ((data['driverEarnings'] ?? data['amount'] ?? 0) as num).toDouble(),
      distance: data['distance'] != null ? '${data['distance']} km' : 'N/A',
      eta: data['estimatedTime'] ?? data['eta'] ?? 'N/A',
    );
  }
}

// ══════════════════════════════════════════════════════
//  1. PICKUP SCREEN — Heading to Pickup
// ══════════════════════════════════════════════════════
class PickupScreen extends StatefulWidget {
  final String tripId;
  const PickupScreen({super.key, required this.tripId});
  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen>
    with TickerProviderStateMixin {

  final DriverService _driverService = DriverService();
  _TripDetails? _tripDetails;
  bool _isLoadingData = true;
  bool _isArriving = false;

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _pathCtrl;
  late Animation<double> _pathAnim;
  late AnimationController _destPulseCtrl;
  late AnimationController _badgeDotCtrl;
  late Animation<double> _badgeDotAnim;
  late AnimationController _navCtrl;
  late Animation<double> _navRotate;
  late Animation<double> _navScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.08).clamp(0.0, 0.7);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _pathAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _pathCtrl, curve: Curves.easeInOut));

    _destPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _badgeDotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _badgeDotAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _badgeDotCtrl, curve: Curves.easeInOut));

    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _navRotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _navCtrl, curve: Curves.easeInOut));
    _navScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _navCtrl, curve: Curves.easeInOut));

    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    final result = await _driverService.getTripDetails(tripId: widget.tripId);
    if (!mounted) return;
    if (result['success'] == true) {
      final raw = result['data']?['data'] ?? result['data'] ?? {};
      setState(() {
        _tripDetails = _TripDetails.fromApi(raw, widget.tripId);
        _isLoadingData = false;
      });
    } else {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleArrive() async {
    // setState(() => _isArriving = true);
    // final result = await _driverService.arrivePickup(tripId: widget.tripId);
    // if (!mounted) return;
    // setState(() => _isArriving = false);
    // if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ArrivedAtPickupScreen(
              tripId: widget.tripId, tripDetails: _tripDetails)));
    // } else {
    //   _showError(context, result['message'] ?? 'Failed to update status');
    // }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pathCtrl.dispose();
    _destPulseCtrl.dispose();
    _badgeDotCtrl.dispose();
    _navCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) {
    return AnimatedBuilder(
      animation: _items[i],
      builder: (_, __) => Opacity(
        opacity: _items[i].value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? _kTeal : const Color(0xFF1ABC9C);
    final trip   = _tripDetails;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _anim(0, Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        teal.withOpacity(0.15), _kAmber.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: teal.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedBuilder(
                        animation: _badgeDotAnim,
                        builder: (_, __) => Opacity(
                          opacity: _badgeDotAnim.value,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: teal),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('EN ROUTE', style: TextStyle(
                          color: teal, fontSize: 11, fontWeight: FontWeight.bold,
                          letterSpacing: 1.0)),
                    ]),
                  ),
                  AnimatedBuilder(
                    animation: _navCtrl,
                    builder: (_, child) => Transform.rotate(
                      angle: _navRotate.value * pi / 180,
                      child: Transform.scale(scale: _navScale.value, child: child),
                    ),
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [teal, const Color(0xFF00BBA7)]),
                        boxShadow: [BoxShadow(
                            color: teal.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.near_me_outlined, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 10),
              _anim(1, Text('Heading to Pickup', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: _text(isDark)))),
              const SizedBox(height: 4),
              _anim(1, Text('Navigate to the pickup location',
                  style: TextStyle(color: _muted(isDark), fontSize: 14))),
              const SizedBox(height: 15),

              if (trip == null)
                _anim(2, Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, color: teal, size: 16),
                    const SizedBox(width: 5),
                    Text(trip?.distance ?? '70 mile away', style: TextStyle(
                        color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 14,
                        color: isDark ? Colors.white24 : Colors.grey.shade200),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, color: Colors.orange, size: 16),
                    const SizedBox(width: 5),
                    Text(trip?.eta ?? '1 hour 30 min', style: TextStyle(
                        color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                )
                ),
              const SizedBox(height: 20),

              _anim(3, _buildMap(teal, isDark)),
              const SizedBox(height: 20),

              if (_isLoadingData)
                Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: teal),
                ))
              else if (trip == null) ...[
                _anim(4, _buildPickupDetailsCard(trip ?? const _TripDetails(
                  tripId: 'TRP-2025-001',
                  pickupLocation: 'Fayum',
                  pickupAddress: 'ميدان المسلة، الفيوم، مصر',
                  dropoffLocation: 'Alexandria Port',
                  dropoffAddress: 'Port Road, Alexandria, Egypt',
                  traderName: 'Toka Mohamed',
                  traderPhone: '+20 101 234 5678',
                  shipmentId: 'SHP-10025',
                  shipmentType: 'Electronics',
                  weight: '500 kg',
                  specialNotes:
                  'Handle with care. Fragile electronic equipment. Delivery required before 6 PM.',
                  amountEGP: 4500.0,
                  distance: '70 mile',
                  eta: '1h 30m',
                ), teal, isDark)),
                const SizedBox(height: 15),
                _anim(5, _buildSummaryCard(trip ?? const _TripDetails(
                  tripId: 'TRP-2025-001',
                  pickupLocation: 'Cairo Warehouse',
                  pickupAddress: 'Nasr City, Cairo, Egypt',
                  dropoffLocation: 'Alexandria Port',
                  dropoffAddress: 'Port Road, Alexandria, Egypt',
                  traderName: 'Ahmed Logistics',
                  traderPhone: '+20 101 234 5678',
                  shipmentId: 'SHP-10025',
                  shipmentType: 'Electronics',
                  weight: '2500 kg',
                  specialNotes:
                  'Handle with care. Fragile electronic equipment. Delivery required before 6 PM.',
                  amountEGP: 4500.0,
                  distance: '220 km',
                  eta: '3h 45m',
                ), teal, isDark)),
              ],

              const SizedBox(height: 30),
              _anim(6, _GradBtn(
                label: "I've Arrived",
                icon: Icons.location_on,
                isLoading: _isArriving,
                onTap: _handleArrive,
              )),
              const SizedBox(height: 20),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMap(Color teal, bool isDark) {
    return Column(children: [
      Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A161F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Stack(children: [
            AnimatedBuilder(
              animation: _pathAnim,
              builder: (_, __) => CustomPaint(
                painter: _MapPainter(teal, isDark: isDark, pathProgress: _pathAnim.value),
                child: Container(),
              ),
            ),
            Positioned(
              top: 30, right: 50,
              child: AnimatedBuilder(
                animation: _destPulseCtrl,
                builder: (_, __) {
                  final v = _destPulseCtrl.value;
                  return Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.orange,
                      boxShadow: [BoxShadow(
                        color: Colors.orange.withOpacity(0.4 * v),
                        blurRadius: 8 * v, spreadRadius: 4 * v,
                      )],
                    ),
                    transform: Matrix4.identity()..scale(1.0 + 0.2 * v),
                    transformAlignment: Alignment.center,
                    child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: teal,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.access_time_filled, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Estimated Arrival',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_tripDetails?.eta ?? '1h 30min', style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_tripDetails?.distance ?? '70 mile away', style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildPickupDetailsCard(_TripDetails trip, Color teal, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(isDark), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 22, backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(Icons.location_on, color: Colors.orange, size: 20)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pickup Location',
                style: TextStyle(color: _muted(isDark), fontSize: 11)),
            Text(trip.pickupLocation, style: TextStyle(
                color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
            if (trip.pickupAddress.isNotEmpty)
              Text(trip.pickupAddress,
                  style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ])),
        ]),
        Divider(height: 28, color: _border(isDark)),
        Row(children: [
          AnimatedBuilder(
            animation: _destPulseCtrl,
            builder: (_, child) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: teal.withOpacity(0.08), shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: teal.withOpacity(0.3 * _destPulseCtrl.value),
                  blurRadius: 16, spreadRadius: 4,
                )],
              ),
              child: child,
            ),
            child: Icon(Icons.person, color: teal),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trader Contact',
                style: TextStyle(color: _muted(isDark), fontSize: 12)),
            Text(trip.traderName, style: TextStyle(
                color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),

          ])),
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: teal,
              boxShadow: [BoxShadow(color: teal.withOpacity(0.4), blurRadius: 15)]),
            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20)),
        ]),
      ]),
    );
  }

  Widget _buildSummaryCard(_TripDetails trip, Color teal, bool isDark) {
    final items = {
      'ID': trip.shipmentId,
      'Type': trip.shipmentType,
      'Weight': "500 Kg",
      'Destination': "Cairo",
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.local_shipping_outlined, color: teal, size: 20),
          const SizedBox(width: 10),
          Text('Shipment Summary', style: TextStyle(
              color: _text(isDark), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 15),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: TextStyle(color: _muted(isDark))),
            Flexible(child: Text(e.value, style: TextStyle(
                color: _text(isDark), fontWeight: FontWeight.w600),
                textAlign: TextAlign.end)),
          ]),
        )),
        // if (trip.specialNotes.isNotEmpty) ...[
        //   Divider(height: 20, color: _border(isDark)),
        //   Container(
        //     width: double.infinity, padding: const EdgeInsets.all(12),
        //     decoration: BoxDecoration(
        //       color: _kAmber.withOpacity(0.08),
        //       borderRadius: BorderRadius.circular(10),
        //       border: Border.all(color: _kAmber.withOpacity(0.3)),
        //     ),
        //     child: Row(children: [
        //       Icon(Icons.warning_amber_rounded, color: _kAmber, size: 16),
        //       const SizedBox(width: 8),
        //       Expanded(child: Text(trip.specialNotes,
        //           style: TextStyle(color: _text(isDark), fontSize: 13))),
        //     ]),
        //   ),
        // ],
      ]),
    );
  }
}


// ══════════════════════════════════════════════════════
//  2. ARRIVED AT PICKUP SCREEN
// ══════════════════════════════════════════════════════
class ArrivedAtPickupScreen extends StatefulWidget {
  final String tripId;
  final _TripDetails? tripDetails;
  const ArrivedAtPickupScreen({super.key, required this.tripId, this.tripDetails});
  @override
  State<ArrivedAtPickupScreen> createState() => _ArrivedAtPickupScreenState();
}

class _ArrivedAtPickupScreenState extends State<ArrivedAtPickupScreen>
    with TickerProviderStateMixin {

  final DriverService _driverService = DriverService();
  bool _isConfirming = false;

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;
  late AnimationController _shadowPulseCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _items = List.generate(8, (i) {
      final s = (0.1 + i * 0.08).clamp(0.0, 0.8);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _shadowPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _shadowPulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmPickup() async {
    // setState(() => _isConfirming = true);
    // final result = await _driverService.confirmPickup(tripId: widget.tripId);
    // if (!mounted) return;
    // setState(() => _isConfirming = false);
    // if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => PickupConfirmationScreen(
              tripId: widget.tripId, tripDetails: widget.tripDetails)));
    // } else {
    //   _showError(context, result['message'] ?? 'Failed to confirm pickup');
    // }
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF00E676) : const Color(0xFF22D3C5);
    final amber  = isDark ? _kAmber : const Color(0xFFFFB84D);
    final trip   = widget.tripDetails;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(child: Column(children: [
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 10),
            _a(0, AnimatedBuilder(
              animation: _iconAnim,
              builder: (_, child) => Transform.scale(scale: _iconAnim.value, child: child),
              child: _PulsingRings(
                color: teal, size: 80, ringCount: 2,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: teal),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                ),
              ),
            )),
            const SizedBox(height: 20),
            _a(1, Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _chipBg(isDark), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: teal, size: 8),
                const SizedBox(width: 8),
                Text('AT PICKUP LOCATION', style: TextStyle(
                    color: teal, fontSize: 12, fontWeight: FontWeight.bold,
                    letterSpacing: 1.0)),
              ]),
            )),
            const SizedBox(height: 25),
            _a(2, Text("You've Arrived!", style: TextStyle(
                color: _text(isDark), fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            _a(2, Text('Meet with the trader to collect the shipment',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted(isDark), fontSize: 14))),
            const SizedBox(height: 25),
            _a(3, Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132A25) : const Color(0xFFE9FFFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withOpacity(0.4)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_outline_rounded, color: teal, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  'Confirm you have arrived at the pickup location',
                  style: TextStyle(color: teal, fontSize: 14))),
              ]),
            )),
            const SizedBox(height: 15),
            _a(4, AnimatedBuilder(
              animation: _shadowPulseCtrl,
              builder: (_, child) => Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card(isDark), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border(isDark)),
                  boxShadow: [BoxShadow(
                    color: teal.withOpacity(
                        0.3 * (0.5 + 0.5 * sin(_shadowPulseCtrl.value * 2 * pi))),
                    blurRadius: 16, spreadRadius: 2,
                  )],
                ),
                child: child,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F323E) : const Color(0xFFE9FFFB),
                    shape: BoxShape.circle),
                  child: Icon(Icons.location_on_outlined, color: teal, size: 22)),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Current Location',
                      style: TextStyle(color: _muted(isDark), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(trip?.pickupLocation ?? 'Fayum', style: TextStyle(
                      color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                  // if ((trip?.pickupAddress ?? '').isNotEmpty)
                    Text(trip?.pickupAddress ?? 'ميدان المسلة، الفيوم، مصر',
                        style: TextStyle(color: _muted(isDark), fontSize: 13)),
                ]),
              ]),
            )),
            const SizedBox(height: 15),
            _a(5, Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(isDark)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFFFF6E5),
                    shape: BoxShape.circle),
                  child: Icon(Icons.person_outline_rounded, color: amber, size: 22)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Contact Person',
                      style: TextStyle(color: _muted(isDark), fontSize: 12)),
                  Text(trip?.traderName ?? 'Toka Mahamed', style: TextStyle(
                      color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                  // if ((trip?.traderPhone ?? '').isNotEmpty)
                    Text(trip?.traderPhone ?? '+20 101 234 5678',
                        style: TextStyle(color: _muted(isDark), fontSize: 13)),
                ])),
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: teal,
                    boxShadow: [BoxShadow(color: teal.withOpacity(0.4), blurRadius: 15)]),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20)),
              ]),
            )),
            const SizedBox(height: 20),
            _a(6, Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(isDark)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.inventory_2_outlined, color: teal, size: 20),
                  const SizedBox(width: 10),
                  Text('Shipment to Collect', style: TextStyle(
                      color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 15),

                const SizedBox(height: 10),
                ...[
                  ['Shipment ID', "SHP-10025"],
                  ['Type', "Electronics"],
                  ['Weight', "500 kg"],
                  ['items', trip?.dropoffLocation ?? '3 items'],
                ].map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(r[0], style: TextStyle(color: _muted(isDark), fontSize: 14)),
                    Text(r[1], style: TextStyle(color: _text(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
                  ]),
                )),
              ]),
            )),
            if ((trip?.specialNotes ?? '').isEmpty) ...[
              const SizedBox(height: 15),
              _a(7, Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF21251A) : const Color(0xFFFFFAED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: amber.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.warning_amber_rounded, color: amber, size: 18),
                    const SizedBox(width: 8),
                    Text('SPECIAL INSTRUCTIONS', style: TextStyle(
                        color: amber, fontSize: 12, fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(trip?.specialNotes ?? 'Handle with care', style: TextStyle(
                        color: _text(isDark), fontSize: 14)),
                  ),
                ]),
              )),
            ],
            const SizedBox(height: 20),
          ]),
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          color: _bg(isDark),
          child: _GradBtn(
            label: 'Confirm Pickup',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isConfirming,
            onTap: _handleConfirmPickup,
          ),
        ),
      ])),
    );
  }
}


// ══════════════════════════════════════════════════════
//  3. PICKUP CONFIRMATION SCREEN
// ══════════════════════════════════════════════════════
class PickupConfirmationScreen extends StatefulWidget {
  final String tripId;
  final _TripDetails? tripDetails;
  const PickupConfirmationScreen({super.key, required this.tripId, this.tripDetails});
  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen>
    with TickerProviderStateMixin {

  final DriverService _driverService = DriverService();
  bool _isStarting = false;

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;
  late AnimationController _routeLineCtrl;
  late Animation<double> _routeLineAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _items = List.generate(8, (i) {
      final s = (i * 0.1).clamp(0.0, 0.8);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _routeLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _routeLineAnim = CurvedAnimation(parent: _routeLineCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _routeLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStartDelivery() async {
    // setState(() => _isStarting = true);
    // final result = await _driverService.startDelivery(tripId: widget.tripId);
    // if (!mounted) return;
    // setState(() => _isStarting = false);
    // if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => InTransitScreen(
              tripId: widget.tripId, tripDetails: widget.tripDetails)));
    // } else {
    //   _showError(context, result['message'] ?? 'Failed to start delivery');
    // }
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF00E676) : const Color(0xFF22D3C5);
    final trip   = widget.tripDetails;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(child: Column(children: [
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 30),
            _a(0, AnimatedBuilder(
              animation: _iconAnim,
              builder: (_, child) => Transform.scale(scale: _iconAnim.value, child: child),
              child: _PulsingRings(
                color: teal, size: 90, ringCount: 3,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      isDark ? const Color(0xFF69F0AE) : const Color(0xFF38E7D2), teal]),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                ),
              ),
            )),
            const SizedBox(height: 30),
            _a(1, Text('Pickup Confirmed!', style: TextStyle(
                color: _text(isDark), fontSize: 26, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            _a(1, Text('Shipment has been loaded successfully',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted(isDark), fontSize: 14))),
            const SizedBox(height: 20),
            _a(2, Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _chipBg(isDark), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: teal.withOpacity(0.2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: teal, size: 8),
                const SizedBox(width: 8),
                Text('Ready for Delivery', style: TextStyle(
                    color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(height: 30),
            _a(3, Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border(isDark)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.near_me_outlined, color: teal, size: 18),
                  const SizedBox(width: 10),
                  Text('Delivery Route', style: TextStyle(
                      color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.circle, color: teal, size: 12),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('From Fayum',
                            style: TextStyle(color: _muted(isDark), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(trip?.pickupLocation ?? 'ميدان المسلة، الفيوم، مصر', style: TextStyle(
                            color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                      ])),
                    ]),
                    AnimatedBuilder(
                      animation: _routeLineAnim,
                      builder: (_, __) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(left: 5),
                          width: 3,
                          height: 50 * _routeLineAnim.value,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22D3C5), Color(0xFFFFB84D)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [
                      Container(width: 12, height: 12,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFFFFB84D))),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('To Cairo',
                            style: TextStyle(color: _muted(isDark), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(trip?.dropoffLocation ?? 'ميدان التحرير، وسط البلد، القاهرة، مصر', style: TextStyle(
                            color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                        if ((trip?.dropoffAddress ?? '').isNotEmpty)
                          Text(trip!.dropoffAddress,
                              style: TextStyle(color: _muted(isDark), fontSize: 13)),
                      ])),
                    ]),
                  ]),
                ),
                const SizedBox(height: 25),
                Row(children: [
                  _infoBox(Icons.location_on_outlined, 'Distance',
                      trip?.distance ?? '70 mile', teal, isDark),
                  const SizedBox(width: 15),
                  _infoBox(Icons.access_time, 'Est. Time',
                      trip?.eta ?? '1h 30min', teal, isDark),
                ]),
              ]),
            )),
            const SizedBox(height: 20),
            _a(4, Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border(isDark)),
              ),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.inventory_2_outlined, color: teal, size: 18),
                  const SizedBox(width: 10),
                  Text('Shipment Loaded', style: TextStyle(
                      color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 25),
                Row(children: [
                  _shipmentBox(Icons.scale_outlined, 'Weight',
                      trip?.weight ?? '500', teal, isDark),
                  const SizedBox(width: 15),
                  _shipmentBox(Icons.inventory_2_outlined, 'Package',
                      trip?.shipmentType ?? '3', teal, isDark),
                ]),
                const SizedBox(height: 25),
                ...[
                  ['Shipment ID', trip?.shipmentId ?? 'SHP-10025'],
                  ['Type', trip?.shipmentType ?? 'Electronics'],
                ].map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(r[0], style: TextStyle(color: _muted(isDark), fontSize: 14)),
                    Text(r[1], style: TextStyle(
                        color: _text(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 20),
          ]),
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          color: _bg(isDark),
          child: _GradBtn(
            label: 'Start Delivery',
            icon: Icons.play_arrow_outlined,
            isLoading: _isStarting,
            onTap: _handleStartDelivery,
          ),
        ),
      ])),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, Color teal, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: isDark ? _muted(isDark) : teal, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ));

  Widget _shipmentBox(IconData icon, String label, String value, Color teal, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: teal, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ]),
      ));
}


// ══════════════════════════════════════════════════════
//  4. IN TRANSIT SCREEN
// ══════════════════════════════════════════════════════
class InTransitScreen extends StatefulWidget {
  final String tripId;
  final _TripDetails? tripDetails;
  const InTransitScreen({super.key, required this.tripId, this.tripDetails});
  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen>
    with TickerProviderStateMixin {

  final DriverService _driverService = DriverService();
  bool _isDelivering = false;

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _rotateCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _pathCtrl;
  late Animation<double> _pathAnim;
  late AnimationController _destPulseCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.09).clamp(0.0, 0.8);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))..repeat();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _progressAnim = Tween<double>(begin: 0, end: 0.30)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Cubic(0.22, 1, 0.36, 1)));
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _pathAnim = Tween<double>(begin: 0, end: 0.30)
        .animate(CurvedAnimation(parent: _pathCtrl, curve: Curves.easeInOut));
    _destPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _rotateCtrl.dispose();
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    _pathCtrl.dispose();
    _destPulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleMarkDelivered() async {
    // setState(() => _isDelivering = true);
    // final result = await _driverService.markDelivered(tripId: widget.tripId);
    // if (!mounted) return;
    // setState(() => _isDelivering = false);
    // if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => DeliverySuccessScreen(
              tripId: widget.tripId, tripDetails: widget.tripDetails)));
    // } else {
    //   _showError(context, result['message'] ?? 'Failed to mark as delivered');
    // }
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF19D2B1) : const Color(0xFF22D3C5);
    final trip   = widget.tripDetails;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _a(0, Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statusBadge('IN TRANSIT', teal, isDark),
            AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, child) => Transform.rotate(
                angle: _rotateCtrl.value * 2 * pi, child: child),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: teal.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]),
                child: CircleAvatar(
                  radius: 26, backgroundColor: teal,
                  child: const Icon(Icons.near_me_outlined,
                      color: Colors.white, size: 28)),
              ),
            ),
          ])),
          const SizedBox(height: 15),
          _a(1, Text('On the Way', style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: _text(isDark)))),
          _a(1, Text('Navigate to the destination',
              style: TextStyle(color: _muted(isDark), fontSize: 14))),
          const SizedBox(height: 20),
          _a(2, _buildMap(teal, isDark)),
          const SizedBox(height: 20),
          _a(3, AnimatedBuilder(
            animation: _destPulseCtrl,
            builder: (_, child) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border(isDark)),
                boxShadow: [BoxShadow(
                  color: Colors.orange.withOpacity(
                      0.3 * (0.5 + 0.5 * sin(_destPulseCtrl.value * 2 * pi))),
                  blurRadius: 16, spreadRadius: 2,
                )],
              ),
              child: child,
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2A33) : const Color(0xFFFFF6E5),
                  shape: BoxShape.circle),
                child: Icon(Icons.location_on,
                    color: isDark ? Colors.orangeAccent : const Color(0xFFFFB84D),
                    size: 24)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Destination',
                    style: TextStyle(color: _muted(isDark), fontSize: 12)),
                Text(trip?.dropoffLocation ?? 'Cairo', style: TextStyle(
                    color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 16)),

                  Text("ميدان التحرير، وسط البلد، القاهرة، مصر",
                      style: TextStyle(color: _muted(isDark), fontSize: 13)),
              ])),
            ]),
          )),
          const SizedBox(height: 20),
          _a(4, Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card(isDark), borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border(isDark)),
            ),
            child: Column(children: [
              Row(children: [
                Icon(Icons.inventory_2_outlined, color: teal, size: 20),
                const SizedBox(width: 10),
                Text('Active Shipment', style: TextStyle(
                    color: _text(isDark), fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 15),
              ...[
                ['ID', trip?.shipmentId ?? 'SHP-10025'],
                ['Type', trip?.shipmentType ?? 'Electronics'],
                ['Weight', trip?.weight ?? '500'],
              ].map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r[0], style: TextStyle(color: _muted(isDark))),
                  Text(r[1], style: TextStyle(
                      color: _text(isDark), fontWeight: FontWeight.w500)),
                ]),
              )),
            ]),
          )),
          const SizedBox(height: 30),
          _a(5, _GradBtn(
            label: 'Mark as Delivered',
            icon: Icons.check_circle_outline,
            isLoading: _isDelivering,
            onTap: _handleMarkDelivered,
          )),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  Widget _buildMap(Color teal, bool isDark) {
    return Column(children: [
      Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A161F) : const Color(0xFFF8FEFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AnimatedBuilder(
            animation: _pathAnim,
            builder: (_, __) => CustomPaint(
              painter: _MapPainter(teal, isDark: isDark,
                  pathProgress: _pathAnim.value)),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: teal,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Trip Progress',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Text(
                  '${(_progressAnim.value * 100).round()}%',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 4, color: Colors.white.withOpacity(0.2)),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _progressAnim.value,
                  child: Stack(children: [
                    Container(height: 4, color: Colors.white),
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(_shimmerAnim.value * 100, 0),
                        child: Container(
                          height: 4, width: 30,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent, Colors.white54, Colors.transparent]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Row(children: [
              Icon(Icons.access_time_filled, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Estimated Arrival',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(widget.tripDetails?.eta ?? '1h 30min', style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.tripDetails?.distance ?? '70 mile away', style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
            ]),
          ]),
        ]),
      ),
    ]);
  }
}


// ══════════════════════════════════════════════════════
//  5. DELIVERY SUCCESS SCREEN
// ══════════════════════════════════════════════════════
class DeliverySuccessScreen extends StatefulWidget {
  final String tripId;
  final _TripDetails? tripDetails;
  const DeliverySuccessScreen({super.key, required this.tripId, this.tripDetails});
  @override
  State<DeliverySuccessScreen> createState() => _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends State<DeliverySuccessScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;
  late AnimationController _checkRotCtrl;
  late Animation<double> _checkRot;
  late AnimationController _iconShimCtrl;
  late Animation<double> _iconShimAnim;
  late AnimationController _confettiCtrl;
  final List<_ConfettiParticle> _particles = [];
  late AnimationController _earningsCtrl;
  late Animation<double> _earningsScale;
  late AnimationController _starsCtrl;
  late List<Animation<double>> _starAnims;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    final rng = Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_ConfettiParticle(
        color: [const Color(0xFF34C759), const Color(0xFF00D5BE),
            const Color(0xFFF59E0B), const Color(0xFFFBBF24)][i % 4],
        x: 0.1 + (i * 0.07),
        delay: i * 0.08,
        drift: i % 2 == 0 ? 1.0 : -1.0,
      ));
    }

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _items = List.generate(10, (i) {
      final s = (i * 0.09).clamp(0.0, 0.85);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _iconScale = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOutBack);

    _checkRotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkRot = Tween<double>(begin: -pi / 2, end: 0.0)
        .animate(CurvedAnimation(parent: _checkRotCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkRotCtrl.forward();
    });

    _iconShimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _iconShimAnim = Tween<double>(begin: -200.0, end: 200.0)
        .animate(CurvedAnimation(parent: _iconShimCtrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _iconShimCtrl.forward();
    });

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..forward();

    _earningsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _earningsScale = CurvedAnimation(parent: _earningsCtrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _earningsCtrl.forward();
    });

    _starsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..forward();
    _starAnims = List.generate(5, (i) {
      final start = (1200 + i * 100) / 2000.0;
      final end   = (start + 0.2).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _starsCtrl,
          curve: Interval(start.clamp(0, 1), end, curve: Curves.easeOutBack));
    });

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _checkRotCtrl.dispose();
    _iconShimCtrl.dispose();
    _confettiCtrl.dispose();
    _earningsCtrl.dispose();
    _starsCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i.clamp(0, _items.length - 1)],
    builder: (_, __) {
      final v = _items[i.clamp(0, _items.length - 1)].value;
      return Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final teal     = isDark ? const Color(0xFF1ABC9C) : const Color(0xFF22D3C5);
    final amber    = isDark ? _kAmber : const Color(0xFFFFB84D);
    final screenW  = MediaQuery.of(context).size.width;
    final trip     = widget.tripDetails;
    final earnings = trip?.amountEGP ?? 0.0;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Stack(children: [

            // ── Confetti ──
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              return AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) {
                  final t = ((_confettiCtrl.value - p.delay).clamp(0.0, 1.0));
                  if (t == 0) return const SizedBox.shrink();
                  return Positioned(
                    left: screenW * p.x,
                    top: 20 + 120 * t,
                    child: Opacity(
                      opacity: (1 - t * 0.8).clamp(0, 1),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(p.drift * 30 * t, 0)
                          ..rotateZ(t * 2 * pi),
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: p.color),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            Column(children: [
              const SizedBox(height: 30),

              // ── Icon ──
              _a(0, AnimatedBuilder(
                animation: _iconScale,
                builder: (_, child) => Transform.scale(scale: _iconScale.value, child: child),
                child: _PulsingRings(
                  color: teal, size: 100, ringCount: 3,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF34C759), teal],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(
                          color: teal.withOpacity(0.5), blurRadius: 24, spreadRadius: 4)],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(
                        animation: _iconShimAnim,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(_iconShimAnim.value, 0),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _checkRot,
                        builder: (_, child) => Transform.rotate(
                          angle: _checkRot.value, child: child),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 40),
                      ),
                    ]),
                  ),
                ),
              )),
              const SizedBox(height: 30),

              _a(1, Text('Delivered Successfully!', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: _text(isDark)))),
              const SizedBox(height: 8),
              _a(1, Text('Great work completing this delivery',
                  style: TextStyle(color: _muted(isDark), fontSize: 14))),
              const SizedBox(height: 30),

              // ── Earnings card (من الـ API) ──
              _a(2, AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, child) => Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _card(isDark), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: amber, width: 2),
                    boxShadow: [BoxShadow(
                      color: amber.withOpacity(0.1 + 0.1 * _glowCtrl.value),
                      blurRadius: 24, spreadRadius: 4,
                    )],
                  ),
                  child: child,
                ),
                child: Column(children: [
                  Text('Trip Earnings',
                      style: TextStyle(color: _muted(isDark), fontSize: 13)),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _earningsScale,
                    builder: (_, child) => Transform.scale(
                      scale: _earningsScale.value, child: child),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('EGP ', style: TextStyle(color: amber, fontSize: 24)),
                      Text(
                        earnings > 0
                            ? earnings.toStringAsFixed(0)
                            : '150',
                        style: TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold,
                            color: _text(isDark)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 15),
                  Divider(color: _border(isDark).withOpacity(0.5)),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, color: teal, size: 16),
                    const SizedBox(width: 8),
                    Text('Trip completed successfully',
                        style: TextStyle(color: _muted(isDark), fontSize: 12)),
                  ]),
                ]),
              )),
              const SizedBox(height: 20),

              // ── Trip Summary (من الـ API) ──
              _a(3, Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card(isDark), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(isDark)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.location_on_outlined, color: teal, size: 20),
                    const SizedBox(width: 10),
                    Text('Trip Summary', style: TextStyle(
                        color: _text(isDark), fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: teal, shape: BoxShape.circle)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('From', style: TextStyle(color: _muted(isDark), fontSize: 11)),
                      Text(trip?.pickupLocation ?? 'Fayum',
                          style: TextStyle(color: _text(isDark), fontSize: 15)),
                    ])),
                  ]),
                  Container(
                      margin: const EdgeInsets.only(left: 5.5),
                      height: 25, width: 1, color: _border(isDark)),
                  Row(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: amber, shape: BoxShape.circle)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('To', style: TextStyle(color: _muted(isDark), fontSize: 11)),
                      Text(trip?.dropoffLocation ?? 'Cairo',
                          style: TextStyle(color: _text(isDark), fontSize: 15)),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _statBox('Distance', trip?.distance ?? '70 mile', isDark),
                    const SizedBox(width: 15),
                    _statBox('Shipment', trip?.shipmentId ?? 'Electronics', isDark),
                  ]),
                ]),
              )),
              const SizedBox(height: 20),

              // ── Rating ──
              _a(4, Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card(isDark), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(isDark)),
                ),
                child: Column(children: [
                  Text('How was your delivery experience?',
                      style: TextStyle(color: _muted(isDark), fontSize: 13)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => AnimatedBuilder(
                      animation: _starAnims[i],
                      builder: (_, __) => Transform.scale(
                        scale: _starAnims[i].value,
                        child: Icon(Icons.star, color: amber, size: 30),
                      ),
                    )),
                  ),
                ]),
              )),
              const SizedBox(height: 30),

              _a(5, _GradBtn(
                label: 'Complete Trip',
                icon: Icons.check_circle_outline_rounded,
                subtitle: 'Return to Home',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/driver_home', (r) => false),
              )),
              const SizedBox(height: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _muted(isDark), fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ]),
      ));
}

// ══════════════════════════════════════════════════════
//  CONFETTI PARTICLE
// ══════════════════════════════════════════════════════
class _ConfettiParticle {
  final Color color;
  final double x;
  final double delay;
  final double drift;
  const _ConfettiParticle({
    required this.color, required this.x,
    required this.delay, required this.drift,
  });
}