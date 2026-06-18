// ════════════════════════════════════════════════════════════
//  trip_assigned_screen.dart  — with animations
//  ✅ بيانات حقيقية من الـ provider
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/screen/driver/trip_active_screen.dart';

// ─── Floating blobs ────────────────────────────────────────
class _FloatingBlobs extends StatefulWidget {
  const _FloatingBlobs();
  @override
  State<_FloatingBlobs> createState() => _FloatingBlobsState();
}

class _FloatingBlobsState extends State<_FloatingBlobs>
    with TickerProviderStateMixin {
  late AnimationController _tealCtrl, _amberCtrl;
  late Animation<Offset> _tealAnim, _amberAnim;

  @override
  void initState() {
    super.initState();
    _tealCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _tealAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(30, -20))
        .animate(CurvedAnimation(parent: _tealCtrl, curve: Curves.easeInOut));

    _amberCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _amberAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-20, 30))
        .animate(CurvedAnimation(parent: _amberCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _tealCtrl.dispose(); _amberCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(
        animation: _tealAnim,
        builder: (_, __) => Positioned(
          top: 80 + _tealAnim.value.dy, right: 40 + _tealAnim.value.dx,
          child: Container(width: 256, height: 256,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF00D5BE).withOpacity(0.05))),
        ),
      ),
      AnimatedBuilder(
        animation: _amberAnim,
        builder: (_, __) => Positioned(
          top: 160 + _amberAnim.value.dy, left: 40 + _amberAnim.value.dx,
          child: Container(width: 192, height: 192,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withOpacity(0.05))),
        ),
      ),
    ]);
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _PressScale({required this.child, required this.onTap, this.scale = 0.97});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _anim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _anim, child: widget.child),
  );
}

class _ShimmerStartBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _ShimmerStartBtn({required this.onTap});

  @override
  State<_ShimmerStartBtn> createState() => _ShimmerStartBtnState();
}

class _ShimmerStartBtnState extends State<_ShimmerStartBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _x;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
    _x = Tween<double>(begin: -300, end: 300)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: widget.onTap,
      scale: 0.98,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00D5BE), Color(0xFF00B4A0)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: _x,
            builder: (_, __) => Transform.translate(
              offset: Offset(_x.value, 0),
              child: Container(
                width: 100,
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
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Start Trip', style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TRIP ASSIGNED SCREEN
// ══════════════════════════════════════════════════════════════
class TripAssignedScreen extends StatefulWidget {
  const TripAssignedScreen({super.key});

  @override
  State<TripAssignedScreen> createState() => _TripAssignedScreenState();
}

class _TripAssignedScreenState extends State<TripAssignedScreen>
    with TickerProviderStateMixin {

  late AnimationController _headerCtrl;
  late AnimationController _badgeCtrl;
  final List<AnimationController> _sectionCtrls  = [];
  final List<Animation<double>>   _sectionFades  = [];
  final List<Animation<Offset>>   _sectionSlides = [];

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..forward();

    _badgeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _badgeCtrl.forward(); });

    for (int i = 0; i < 4; i++) {
      final c = AnimationController(vsync: this,
          duration: const Duration(milliseconds: 450));
      _sectionCtrls.add(c);
      _sectionFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _sectionSlides.add(Tween<Offset>(
              begin: const Offset(0, 0.4), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 300 + i * 100),
          () { if (mounted) c.forward(); });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _badgeCtrl.dispose();
    for (final c in _sectionCtrls) c.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    final fade  = i < _sectionFades.length
        ? _sectionFades[i] : const AlwaysStoppedAnimation(1.0);
    final slide = i < _sectionSlides.length
        ? _sectionSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(opacity: fade,
        child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().theme.isDark;
    final user   = context.watch<UserProvider>();
    final driver = context.watch<DriverProvider>(); // ✅

    // ✅ بيانات حقيقية من الـ provider
    final displayName  = user.fullName.isNotEmpty ? user.fullName : 'Driver';
    final trip         = driver.activeTrip;
    final tripId       = trip?.id ?? 'SHP-0000';
    final pickup       = trip?.origin ?? 'Pickup Location';
    final dropoff      = trip?.destination ?? 'Drop-off Location';
    final cargoType    = trip?.goodsType ?? 'General Cargo';
    final traderName   = trip?.traderName ?? 'Trader';
    final isFragile    = trip?.isFragile ?? false;
    final weightTons   = trip?.weightTons ?? 0.0;
    final price        = trip?.price ?? 0.0;

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF7A8FA6);
    final kBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
    final kCyan   = const Color(0xFF00D5BE);
    final kAmber  = const Color(0xFFF59E0B);
    final kPillBg = isDark ? const Color(0xFF1E3040) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          const _FloatingBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, -0.5), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut)),
                      child: Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back', style: TextStyle(color: kMuted, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(displayName, style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Container(width: 60, height: 2, decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(2))),
                          ],
                        )),
                        _pill(kPillBg, Row(children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text('4.8', style: TextStyle(color: kText, fontSize: 13)),
                        ])),
                        const SizedBox(width: 8),
                        _pill(kPillBg, Row(children: [
                          Container(width: 8, height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: isDark ? Colors.white38 : Colors.black26)),
                          const SizedBox(width: 6),
                          Text('OFFLINE', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ])),
                        const SizedBox(width: 8),
                        Container(width: 38, height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E3040) : const Color(0xFFF0F4F8)),
                          child: Icon(Icons.person_outline, color: kMuted, size: 22)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Assigned badge ──
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: kCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kCyan.withOpacity(0.35)),
                      ),
                      child: Text('Assigned', style: TextStyle(color: kCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Trip Card ──
                  _animated(0, Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Trip Ready to Start', style: TextStyle(color: kCyan, fontSize: 15, fontWeight: FontWeight.w700)),
                          Text(tripId, style: TextStyle(color: kMuted, fontSize: 13)), // ✅ ID حقيقي
                        ]),
                      ),
                      const SizedBox(height: 20),
                      _divider(kBorder),

                      // ROUTE ✅ بيانات حقيقية
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ROUTE', style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Column(children: [
                              Container(width: 28, height: 28,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00D5BE)),
                                child: const Icon(Icons.circle, color: Colors.white, size: 10)),
                              Container(width: 2, height: 36, color: kCyan.withOpacity(0.3)),
                            ]),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Pickup Location', style: TextStyle(color: kMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(pickup, style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)), // ✅
                            ]),
                          ]),
                          const SizedBox(height: 4),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 28, height: 28,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kCyan, width: 2)),
                              child: const Icon(Icons.location_on, color: Color(0xFF00D5BE), size: 14)),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Drop-off Location', style: TextStyle(color: kMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(dropoff, style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)), // ✅
                            ]),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      _divider(kBorder),

                      // SCHEDULE
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('SCHEDULE', style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kCyan.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kCyan.withOpacity(0.2)),
                            ),
                            // ✅ وقت حقيقي من الباك
                            child: Text(
                              trip?.scheduledDate != null && trip!.scheduledDate.isNotEmpty
                                  ? '${trip.scheduledDate} ${trip.scheduledTime}'
                                  : 'Ready to start',
                              style: TextStyle(color: kCyan, fontSize: 14)),
                          ),
                        ]),
                      ),
                      _divider(kBorder),

                      // SHIPMENT INFO ✅ بيانات حقيقية
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('SHIPMENT INFORMATION', style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          _infoRow(kText, kMuted, 'Client', traderName), // ✅
                          const SizedBox(height: 12),
                          _infoRow(kText, kMuted, 'Cargo Type', cargoType), // ✅
                          const SizedBox(height: 12),
                          _infoRow(kText, kMuted, 'Weight', '${weightTons.toStringAsFixed(1)} tons'), // ✅
                          const SizedBox(height: 12),
                          _infoRow(kText, kMuted, 'Price', '${price.toStringAsFixed(0)} EGP'), // ✅
                          if (isFragile) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kAmber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kAmber.withOpacity(0.35)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.warning_amber_rounded, color: kAmber, size: 14),
                                const SizedBox(width: 6),
                                Text('Fragile', style: TextStyle(color: kAmber, fontSize: 13, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 20),

                  // ── Start Trip ✅ بيكلم الباك
                  _animated(1, _ShimmerStartBtn(
                    onTap: () async {
                      final success = await context.read<DriverProvider>().startTrip();
                      if (success && mounted) {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const TripActiveScreen()));
                      }
                    },
                  )),
                  const SizedBox(height: 12),

                  // ── View Full Details ──
                  _animated(2, _PressScale(
                    onTap: () {},
                    child: Container(
                      width: double.infinity, height: 54,
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text('View Full Details', style: TextStyle(color: kMuted, fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  )),

                  const SizedBox(height: 16),

                  // ── Footer note ──
                  _animated(3, Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: isDark ? Colors.white24 : Colors.black12)),
                    const SizedBox(width: 8),
                    Text('Offline – Not receiving new trips', style: TextStyle(color: kMuted, fontSize: 12)),
                  ])),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(Color bg, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: child,
  );

  Widget _divider(Color color) => Container(height: 1, color: color);

  Widget _infoRow(Color text, Color muted, String label, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: muted, fontSize: 14)),
        Text(value, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600)),
      ]);
}