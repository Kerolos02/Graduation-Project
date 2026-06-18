import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TraderShipmentScheduled — trader_shipment_scheduled_screen.dart
//  ✅ Matched 1:1 with ShipmentScheduledScreen.tsx (React Native / Framer Motion)
//
//  RN → Flutter animation map:
//  • Page:          opacity:0→1  0.5s                     → _pageFade
//  • Glow:          scale:[1,1.5,1.2] opacity:[0.4,0.8,0.4] 2s loop → _glowCtrl
//  • Icon circle:   scale:0, rotate:-180→0  spring s:200 d:15 delay:0.2 → _iconCtrl
//  • SVG path:      pathLength:0→1  delay:0.5              → _pathCtrl (dash trick)
//  • Title+desc:    opacity:0, y:+20→0  0.6s  delay:0.6   → _textCtrl
//  • Details card:  opacity:0, y:+40, scale:0.95→1  delay:0.8 ease[0.22,1,0.36,1] → _cardCtrl
//  • Driver notice: opacity:0, x:-30→0  0.6s  delay:1.0   → _noticeCtrl
//  • Track btn:     opacity:0, y:+20→0  delay:1.2 + whileHover scale:1.03 → _btn1Ctrl
//  • Return btn:    opacity:0, y:+20→0  delay:1.3 + whileHover scale:1.02 → _btn2Ctrl
//  • Shipment ID:   opacity:0→1  delay:1.5                → _idCtrl
//  • whileTap:      scale:0.98  → _TapScaleButton
// ══════════════════════════════════════════════════════════════════════════════

class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    const s = 200.0, d = 15.0, m = 1.0;
    final omega0 = math.sqrt(s / m);
    final zeta   = d / (2 * math.sqrt(s * m));
    if (zeta < 1) {
      final omegaD = omega0 * math.sqrt(1 - zeta * zeta);
      return 1 -
          math.exp(-zeta * omega0 * t) *
              (math.cos(omegaD * t) +
                  (zeta * omega0 / omegaD) * math.sin(omegaD * t));
    }
    return 1 - math.exp(-omega0 * t) * (1 + omega0 * t);
  }
}

const Cubic _kEaseSpring = Cubic(0.22, 1.0, 0.36, 1.0);

class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  const _TapScaleButton({
    required this.child,
    required this.onTap,
    this.hoverScale = 1.0,
  });

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovering = true),
    onExit:  (_) => setState(() => _hovering = false),
    child: GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: AnimatedScale(
          scale: _hovering ? widget.hoverScale : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity, _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.4)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: widget.color.withOpacity(0.8),
              blurRadius: 8, spreadRadius: 1)],
          ),
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TraderShipmentScheduled extends StatefulWidget {
  final String pickup, dropoff, date, time, packages, weight;

  const TraderShipmentScheduled({
    super.key,
    this.pickup   = 'rt45',
    this.dropoff  = '3434',
    this.date     = '2025-12-02',
    this.time     = '02:23',
    this.packages = '1',
    this.weight   = '11',
  });

  @override
  State<TraderShipmentScheduled> createState() =>
      _TraderShipmentScheduledState();
}

class _TraderShipmentScheduledState extends State<TraderShipmentScheduled>
    with TickerProviderStateMixin {

  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;

  late AnimationController _glowCtrl;
  late Animation<double>   _glowScale;
  late Animation<double>   _glowOpacity;

  late AnimationController _iconCtrl;
  late Animation<double>   _iconScale;
  late Animation<double>   _iconRotate;
  late Animation<double>   _iconFade;

  late AnimationController _pathCtrl;
  late Animation<double>   _pathProgress;

  late AnimationController _textCtrl;
  late Animation<double>   _textFade;
  late Animation<Offset>   _textSlide;

  late AnimationController _cardCtrl;
  late Animation<double>   _cardFade;
  late Animation<Offset>   _cardSlide;
  late Animation<double>   _cardScale;

  late AnimationController _noticeCtrl;
  late Animation<double>   _noticeFade;
  late Animation<Offset>   _noticeSlide;

  late AnimationController _btn1Ctrl;
  late Animation<double>   _btn1Fade;
  late Animation<Offset>   _btn1Slide;

  late AnimationController _btn2Ctrl;
  late Animation<double>   _btn2Fade;
  late Animation<Offset>   _btn2Slide;

  late AnimationController _idCtrl;
  late Animation<double>   _idFade;

  String get _shipmentId {
    final now = DateTime.now();
    return 'TM-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 8)}';
  }

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
    _glowScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.8), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.4), weight: 60),
    ]).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _iconCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _iconScale  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: const _SpringCurve()));
    _iconRotate = Tween<double>(begin: -math.pi, end: 0.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: const _SpringCurve()));
    _iconFade   = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _iconCtrl.forward(); });

    _pathCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _pathProgress = CurvedAnimation(parent: _pathCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _pathCtrl.forward(); });

    _textCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) _textCtrl.forward(); });

    _cardCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
            begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: _kEaseSpring));
    _cardScale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) _cardCtrl.forward(); });

    _noticeCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _noticeFade  = CurvedAnimation(parent: _noticeCtrl, curve: Curves.easeOut);
    _noticeSlide = Tween<Offset>(
            begin: const Offset(-0.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _noticeCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1000),
        () { if (mounted) _noticeCtrl.forward(); });

    _btn1Ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _btn1Fade  = CurvedAnimation(parent: _btn1Ctrl, curve: Curves.easeOut);
    _btn1Slide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btn1Ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1200),
        () { if (mounted) _btn1Ctrl.forward(); });

    _btn2Ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _btn2Fade  = CurvedAnimation(parent: _btn2Ctrl, curve: Curves.easeOut);
    _btn2Slide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btn2Ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1300),
        () { if (mounted) _btn2Ctrl.forward(); });

    _idCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _idFade  = CurvedAnimation(parent: _idCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 1500),
        () { if (mounted) _idCtrl.forward(); });
  }

  @override
  void dispose() {
    _pageCtrl.dispose(); _glowCtrl.dispose(); _iconCtrl.dispose();
    _pathCtrl.dispose(); _textCtrl.dispose(); _cardCtrl.dispose();
    _noticeCtrl.dispose(); _btn1Ctrl.dispose(); _btn2Ctrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xEB1C3041),
              Color(0xFF1C3449),
              Color(0xEB1C3041),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _pageFade,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // ── Success icon + glow ──
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: SizedBox(
                        width: 96, height: 96,
                        child: Stack(alignment: Alignment.center, children: [
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: _glowScale.value,
                              child: Opacity(
                                opacity: _glowOpacity.value,
                                child: Container(
                                  width: 96, height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00D5BE).withOpacity(0.2),
                                    boxShadow: [BoxShadow(
                                      color: const Color(0xFF00D5BE).withOpacity(0.3),
                                      blurRadius: 64, spreadRadius: 16)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _iconCtrl,
                            builder: (_, child) => Opacity(
                              opacity: _iconFade.value,
                              child: Transform.scale(
                                scale: _iconScale.value,
                                child: Transform.rotate(
                                  angle: _iconRotate.value,
                                  child: child,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF009689), Color(0xFF00BBA7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFF00D5BE).withOpacity(0.5),
                                  blurRadius: 20, spreadRadius: 0)],
                              ),
                              child: AnimatedBuilder(
                                animation: _pathCtrl,
                                builder: (_, __) => CustomPaint(
                                  painter: _CheckPainter(_pathProgress.value),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Title + desc ──
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(children: [
                        const Text('Shipment Scheduled!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFF0FDF9),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                        const SizedBox(height: 10),
                        Text(
                          'Your shipment has been confirmed and\na driver has been assigned',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: const Color(0xFFCBFBF1).withOpacity(0.5),
                              fontSize: 15, height: 1.6),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Details card ──
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1628).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF00D5BE).withOpacity(0.2),
                              width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRoute(),
                              Divider(
                                  color: const Color(0xFF00D5BE).withOpacity(0.2),
                                  height: 28),
                              Row(children: [
                                Expanded(child: _infoItem(
                                  'Scheduled Date', widget.date,
                                  icon: Icons.calendar_month_outlined,
                                )),
                                Expanded(child: _infoItem('Time', widget.time)),
                              ]),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(child: _infoItem(
                                  'Packages', widget.packages,
                                  icon: Icons.widgets_outlined,
                                )),
                                Expanded(child: _infoItem(
                                    'Weight', '${widget.weight} lbs')),
                              ]),
                              Divider(
                                  color: const Color(0xFF00D5BE).withOpacity(0.2),
                                  height: 28),
                              _buildVehicleCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Driver notice ──
                  FadeTransition(
                    opacity: _noticeFade,
                    child: SlideTransition(
                      position: _noticeSlide,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D3F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00D3F2).withOpacity(0.3),
                            width: 0.8),
                        ),
                        child: Row(children: [
                          const _PulsingDot(color: Color(0xFF00D3F2)),
                          const SizedBox(width: 10),
                          const Text(
                            'Driver will arrive at pickup in 15 minutes',
                            style: TextStyle(
                                color: Color(0xFF00D3F2), fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Track Shipment btn ──
                  // ✅ التعديل: بيروح لشاشة الـ tracking بدل الـ home
                  FadeTransition(
                    opacity: _btn1Fade,
                    child: SlideTransition(
                      position: _btn1Slide,
                      child: _TapScaleButton(
                        hoverScale: 1.03,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/trader_tracking',
                          arguments: _shipmentId,
                        ),
                        child: Container(
                          width: double.infinity, height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF009689), Color(0xFF00BBA7),
                                Color(0xFF00B8DB),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF00BBA7).withOpacity(0.25),
                              blurRadius: 9, offset: const Offset(0, 6))],
                          ),
                          alignment: Alignment.center,
                          child: const Text('Track Shipment',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Return to Home btn ──
                  FadeTransition(
                    opacity: _btn2Fade,
                    child: SlideTransition(
                      position: _btn2Slide,
                      child: _TapScaleButton(
                        hoverScale: 1.02,
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/trader_home', (_) => false),
                        child: Container(
                          width: double.infinity, height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1628).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 0.8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20),
                              const SizedBox(width: 8),
                              Text('Return to Home',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Shipment ID ──
                  FadeTransition(
                    opacity: _idFade,
                    child: Column(children: [
                      Text('Shipment ID',
                          style: TextStyle(
                              color: const Color(0xFFCBFBF1).withOpacity(0.4),
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_shipmentId,
                          style: TextStyle(
                              color: const Color(0xFFCBFBF1).withOpacity(0.5),
                              fontSize: 13,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoute() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D5BE),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.8),
              blurRadius: 8)],
          )),
        Container(
          width: 2, height: 44,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00D5BE), Color(0xFF00D3F2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Container(width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D3F2),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D3F2).withOpacity(0.8),
              blurRadius: 8)],
          )),
      ]),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pickup', style: TextStyle(
            color: const Color(0xFFCBFBF1).withOpacity(0.5), fontSize: 11)),
        Text(widget.pickup, style: const TextStyle(
            color: Color(0xFFF0FDF9), fontSize: 15,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Drop-off', style: TextStyle(
            color: const Color(0xFFCBFBF1).withOpacity(0.5), fontSize: 11)),
        Text(widget.dropoff, style: const TextStyle(
            color: Color(0xFFF0FDF9), fontSize: 15,
            fontWeight: FontWeight.w500)),
      ]),
    ]);
  }

  Widget _infoItem(String label, String value, {IconData? icon}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: const Color(0xFFCBFBF1).withOpacity(0.5), fontSize: 11)),
      const SizedBox(height: 4),
      Row(children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF00D5BE), size: 14),
          const SizedBox(width: 5),
        ],
        Text(value, style: const TextStyle(
            color: Color(0xFFF0FDF9), fontSize: 13,
            fontWeight: FontWeight.w500)),
      ]),
    ]);

  Widget _buildVehicleCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1628).withOpacity(0.5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF00D5BE).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00D5BE).withOpacity(0.3), width: 0.8),
        ),
        child: const Icon(Icons.local_shipping_outlined,
            color: Color(0xFF00D5BE), size: 22),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Swift Pickup', style: TextStyle(
              color: Color(0xFFF0FDF9), fontSize: 15,
              fontWeight: FontWeight.w600)),
          Text('Pickup Truck', style: TextStyle(
              color: Color(0xFFCBFBF1), fontSize: 13)),
        ],
      )),
      const Text('\$240', style: TextStyle(
          color: Color(0xFF00D5BE), fontSize: 17,
          fontWeight: FontWeight.w600)),
    ]),
  );
}

class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width  / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - 18, cy + 2)
      ..lineTo(cx - 4,  cy + 14)
      ..lineTo(cx + 18, cy - 12);

    final metric = path.computeMetrics().first;
    final extractPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}