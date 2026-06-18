// ════════════════════════════════════════════════════════════
//  live_navigation_screen.dart
//  ✨ ALL ANIMATIONS PRESERVED — API CONNECTED
//  API: POST /api/driver/trips/{tripId}/mark-delivered
//  ✅ Map موحّدة عبر AppMapWidget (نفس شكل التريدر + live tracking)
// ════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/driver_provider.dart';
import '/screen/widgets/app_map_widget.dart'; // ✅ الـ map الموحّدة

// ─── Colors ──────────────────────────────────────────────
const _kCyan    = Color(0xFF00D5BE);
const _kCyan2   = Color(0xFF00BBA7);
const _kRed     = Color(0xFFFF6B6B);
const _kRedDark = Color(0xFFEE5A52);
const _kBg      = Color(0xFF0F2334);
const _kMuted   = Color(0xFFCBFBF1);

// ════════════════════════════════════════════════════════════
//  PRESS SCALE
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
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _s,
      builder: (_, child) => Transform.scale(scale: _s.value, child: child),
      child: widget.child,
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  NEXT TURN CARD
// ════════════════════════════════════════════════════════════
class _NextTurnCard extends StatefulWidget {
  const _NextTurnCard();

  @override
  State<_NextTurnCard> createState() => _NextTurnCardState();
}

class _NextTurnCardState extends State<_NextTurnCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kBg.withOpacity(0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCyan.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kCyan, _kCyan2],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Turn right on Ring Road',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('in 0.5 mi', style: TextStyle(color: _kCyan.withOpacity(0.8), fontSize: 12)),
          ])),
        ]),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  BOTTOM INFO CARD  — بيجيب البيانات من DriverProvider
// ════════════════════════════════════════════════════════════
class _BottomInfoCard extends StatefulWidget {
  final VoidCallback onContact;
  final VoidCallback onEndTrip;
  const _BottomInfoCard({required this.onContact, required this.onEndTrip});

  @override
  State<_BottomInfoCard> createState() => _BottomInfoCardState();
}

class _BottomInfoCardState extends State<_BottomInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final driver      = context.watch<DriverProvider>();
    final trip        = driver.activeTrip;
    final shipmentId  = trip?.id             ?? '—';
    final destination = trip?.destination    ?? '—';
    final eta         = trip?.estimatedTime  ?? '—';
    final distance    = trip?.distance       ?? '—';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25, 1.0],
              colors: [Colors.transparent, _kBg, _kBg],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kBg.withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kCyan.withOpacity(0.3)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 32, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ETA', style: TextStyle(color: _kMuted.withOpacity(0.5), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(eta, style: const TextStyle(
                        color: _kCyan, fontSize: 24, fontWeight: FontWeight.w700)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Distance', style: TextStyle(color: _kMuted.withOpacity(0.5), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(distance, style: const TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: _kCyan.withOpacity(0.15)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Destination', style: TextStyle(color: _kMuted.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(destination, style: const TextStyle(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w500, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(shipmentId, style: TextStyle(
                      color: _kMuted.withOpacity(0.5),
                      fontSize: 12, fontFamily: 'monospace')),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _PressScale(
                    onTap: widget.onContact,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kCyan.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.phone_outlined, color: _kCyan, size: 16),
                        const SizedBox(width: 8),
                        Text('Contact', style: TextStyle(
                            color: _kCyan, fontSize: 14, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PressScale(
                    onTap: widget.onEndTrip,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kRed, _kRedDark]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                            color: _kRed.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('End Trip', style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  END TRIP MODAL
// ════════════════════════════════════════════════════════════
class _EndTripModal extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String destination;
  const _EndTripModal({required this.onConfirm, required this.onCancel, required this.destination});

  @override
  State<_EndTripModal> createState() => _EndTripModalState();
}

class _EndTripModalState extends State<_EndTripModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _backdrop;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
    _backdrop  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _cardScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _cardFade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        color: Colors.black.withOpacity(0.8 * _backdrop.value),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () {},
          child: Transform.scale(
            scale: _cardScale.value,
            child: Opacity(
              opacity: _cardFade.value,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 384),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kCyan.withOpacity(0.3)),
                  boxShadow: const [BoxShadow(
                      color: Colors.black38, blurRadius: 32, offset: Offset(0, 8))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 64, height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_kRed, _kRedDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Complete Trip?', style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Confirm that you have successfully delivered the shipment to ${widget.destination}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _kMuted.withOpacity(0.6), fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _PressScale(
                    onTap: widget.onConfirm,
                    child: Container(
                      width: double.infinity, height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kCyan, _kCyan2]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: _kCyan.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Yes, Complete Trip', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PressScale(
                    onTap: widget.onCancel,
                    child: Container(
                      width: double.infinity, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E8E93).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8E8E93).withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Cancel', style: TextStyle(
                          color: _kMuted.withOpacity(0.8),
                          fontWeight: FontWeight.w500, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  LIVE NAVIGATION SCREEN
// ════════════════════════════════════════════════════════════
class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key});

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  bool _showModal  = false;
  bool _completing = false;

  Future<void> _completeTrip() async {
    setState(() => _completing = true);
    final success = await context.read<DriverProvider>().completeTrip();
    if (!mounted) return;
    setState(() { _completing = false; _showModal = false; });
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/driver_home', (_) => false);
    } else {
      final err = context.read<DriverProvider>().error ?? 'Failed to complete trip';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: _kRed,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip        = context.watch<DriverProvider>().activeTrip;
    final destination = trip?.destination ?? '—';
    // ✅ pickup/dropoff لتشغيل AppMapWidget
    // لو trip model عندها origin استخدميه، لو لأ اتركي pickup فاضي والخريطة هتظهر Cairo كـ default
    final dropoff = trip?.destination ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        SafeArea(
          child: Stack(children: [

              // ✅ الخريطة الموحّدة — Live tracking للدرايفر
              Positioned.fill(
                child: AppMapWidget(
                  dropoffLocation:      dropoff.isNotEmpty ? dropoff : null,
                  showLiveTracking:     true,
                  showMyLocationButton: true,
                  height: null,
                  emptyStateLabel:      'Locating destination...',
                ),
              ),

            // Top controls
            Positioned(
              top: 20, left: 20, right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBg.withOpacity(0.95),
                        border: Border.all(color: _kCyan.withOpacity(0.3)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  _PressScale(
                    onTap: () {},
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBg.withOpacity(0.95),
                        border: Border.all(color: _kCyan.withOpacity(0.3)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Next Turn Card
            const Positioned(top: 80, left: 0, right: 0, child: _NextTurnCard()),

            // Bottom Info Card
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _BottomInfoCard(
                onContact: () {},
                onEndTrip: () => setState(() => _showModal = true),
              ),
            ),
          ]),
        ),

        // End Trip Modal
        if (_showModal)
          Positioned.fill(
            child: _EndTripModal(
              destination: destination,
              onConfirm: _completeTrip,
              onCancel: () => setState(() => _showModal = false),
            ),
          ),

        // Loading overlay
        if (_completing)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: _kCyan, strokeWidth: 2.5),
              ),
            ),
          ),
      ]),
    );
  }
}