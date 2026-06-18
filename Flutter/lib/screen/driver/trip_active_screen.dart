// ════════════════════════════════════════════════════════════
//  trip_active_screen.dart  — with animations
//  ✅ بيانات حقيقية من الـ provider
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/screen/driver/live_navigation_screen.dart';
import '/screen/driver/driver_home_screen.dart';

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
    _tealCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _tealAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(30, -20)).animate(CurvedAnimation(parent: _tealCtrl, curve: Curves.easeInOut));
    _amberCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _amberAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-20, 30)).animate(CurvedAnimation(parent: _amberCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _tealCtrl.dispose(); _amberCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(animation: _tealAnim, builder: (_, __) => Positioned(
        top: 80 + _tealAnim.value.dy, right: 40 + _tealAnim.value.dx,
        child: Container(width: 256, height: 256, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D5BE).withOpacity(0.05))))),
      AnimatedBuilder(animation: _amberAnim, builder: (_, __) => Positioned(
        top: 160 + _amberAnim.value.dy, left: 40 + _amberAnim.value.dx,
        child: Container(width: 192, height: 192, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF59E0B).withOpacity(0.05))))),
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

class _PressScaleState extends State<_PressScale> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _anim, child: widget.child));
}

class _ShimmerNavBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _ShimmerNavBtn({required this.onTap});
  @override
  State<_ShimmerNavBtn> createState() => _ShimmerNavBtnState();
}

class _ShimmerNavBtnState extends State<_ShimmerNavBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _x;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _x = Tween<double>(begin: -300, end: 300).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: widget.onTap, scale: 0.98,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00D5BE), Color(0xFF00B4A0)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(animation: _x, builder: (_, __) => Transform.translate(
            offset: Offset(_x.value, 0),
            child: Container(width: 100, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.2), Colors.transparent]))))),
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.navigation, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('View Live Navigation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TRIP ACTIVE SCREEN
// ══════════════════════════════════════════════════════════════
class TripActiveScreen extends StatefulWidget {
  const TripActiveScreen({super.key});
  @override
  State<TripActiveScreen> createState() => _TripActiveScreenState();
}

class _TripActiveScreenState extends State<TripActiveScreen>
    with TickerProviderStateMixin {

  late AnimationController _progressCtrl;
  late Animation<double>   _progressAnim;
  final double _progress = 0.65;

  late AnimationController _headerCtrl;
  late AnimationController _badgeCtrl;
  final List<AnimationController> _sectionCtrls  = [];
  final List<Animation<double>>   _sectionFades  = [];
  final List<Animation<Offset>>   _sectionSlides = [];

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0.0, end: _progress).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

    _badgeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _badgeCtrl.forward(); });

    for (int i = 0; i < 5; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
      _sectionCtrls.add(c);
      _sectionFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _sectionSlides.add(Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 350 + i * 100), () { if (mounted) c.forward(); });
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _headerCtrl.dispose();
    _badgeCtrl.dispose();
    for (final c in _sectionCtrls) c.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    final fade  = i < _sectionFades.length ? _sectionFades[i] : const AlwaysStoppedAnimation(1.0);
    final slide = i < _sectionSlides.length ? _sectionSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  void _showCompleteDialog(bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CompleteTripDialog(
        isDark: isDark,
        onConfirm: () async {
          // ✅ بيكلم الباك
          final success = await context.read<DriverProvider>().completeTrip();
          if (success && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().theme.isDark;
    final user   = context.watch<UserProvider>();
    final driver = context.watch<DriverProvider>(); // ✅

    // ✅ بيانات حقيقية من الـ provider
    final displayName = user.fullName.isNotEmpty ? user.fullName : 'Driver';
    final trip        = driver.activeTrip;
    final tripId      = trip?.id ?? 'SHP-0000';
    final origin      = trip?.origin ?? 'Pickup Location';
    final destination = trip?.destination ?? 'Drop-off Location';
    final cargoType   = trip?.goodsType ?? 'General Cargo';
    final isFragile   = trip?.isFragile ?? false;
    final weightTons  = trip?.weightTons ?? 0.0;

    final kBg      = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard    = isDark ? const Color(0xFF152232) : Colors.white;
    final kDeep    = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF0F4F8);
    final kText    = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted   = isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF7A8FA6);
    final kBorder  = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
    final kCyan    = const Color(0xFF00D5BE);
    final kAmber   = const Color(0xFFF59E0B);
    final kPillBg  = isDark ? const Color(0xFF1E3040) : const Color(0xFFF0F4F8);
    final progressBg = kCyan.withOpacity(0.12);

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
                      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Welcome back', style: TextStyle(color: kMuted, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(displayName, style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(width: 60, height: 2, decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(2))),
                        ])),
                        _pill(kPillBg, Row(children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text('4.8', style: TextStyle(color: kText, fontSize: 13)),
                        ])),
                        const SizedBox(width: 8),
                        _pill(kPillBg, Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white38 : Colors.black26)),
                          const SizedBox(width: 6),
                          Text('OFFLINE', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ])),
                        const SizedBox(width: 8),
                        Container(width: 38, height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF1E3040) : const Color(0xFFF0F4F8)),
                          child: Icon(Icons.person_outline, color: kMuted, size: 22)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── In Transit badge ──
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: kCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kCyan.withOpacity(0.35))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00D5BE))),
                        const SizedBox(width: 6),
                        Text('In Transit', style: TextStyle(color: kCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Trip Card ✅ بيانات حقيقية ──
                  _animated(0, Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Align(alignment: Alignment.centerRight,
                          child: Text(tripId, style: TextStyle(color: kMuted, fontSize: 13))), // ✅
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Column(children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: kAmber)),
                            Container(width: 2, height: 40, color: kCyan.withOpacity(0.3)),
                            Container(width: 12, height: 12,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kCyan, width: 2)),
                              child: Center(child: Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00D5BE))))),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('From', style: TextStyle(color: kMuted, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(origin, style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)), // ✅
                            const SizedBox(height: 16),
                            Text('To', style: TextStyle(color: kMuted, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(destination, style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600)), // ✅
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ETA + Progress
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: kDeep, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ETA', style: TextStyle(color: kMuted, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(trip?.estimatedTime ?? '-- min', style: TextStyle(color: kCyan, fontSize: 22, fontWeight: FontWeight.w800)), // ✅
                            ]))),
                          const SizedBox(width: 12),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: kDeep, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Progress', style: TextStyle(color: kMuted, fontSize: 12)),
                              const SizedBox(height: 6),
                              const Text('65%', style: TextStyle(color: Color(0xFF00D5BE), fontSize: 22, fontWeight: FontWeight.w800)),
                            ]))),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Progress bar ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _progressAnim.value,
                              minHeight: 7,
                              backgroundColor: progressBg,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D5BE)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  )),
                  const SizedBox(height: 16),

                  // ── View Live Navigation ──
                  _animated(1, _ShimmerNavBtn(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveNavigationScreen())),
                  )),
                  const SizedBox(height: 20),

                  // ── Shipment Details ✅ بيانات حقيقية ──
                  _animated(2, Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Shipment Details', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Cargo', style: TextStyle(color: kMuted, fontSize: 14)),
                        Text(cargoType, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)), // ✅
                      ]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Weight', style: TextStyle(color: kMuted, fontSize: 14)),
                        Text('${weightTons.toStringAsFixed(1)} tons', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)), // ✅
                      ]),
                      if (isFragile) ...[
                        const SizedBox(height: 14),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kAmber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kAmber.withOpacity(0.35))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.warning_amber_rounded, color: kAmber, size: 13),
                              const SizedBox(width: 5),
                              Text('FRAGILE', style: TextStyle(color: kAmber, fontSize: 11, fontWeight: FontWeight.w700)),
                            ])),
                        ]),
                      ],
                    ]),
                  )),
                  const SizedBox(height: 16),

                  // ── End Trip ✅ بيكلم الباك ──
                  _animated(3, _PressScale(
                    onTap: () => _showCompleteDialog(isDark),
                    child: Container(
                      width: double.infinity, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
                      alignment: Alignment.center,
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.flag_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('End Trip', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  )),

                  const SizedBox(height: 16),

                  _animated(4, Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white24 : Colors.black12)),
                    const SizedBox(width: 8),
                    Text('Offline – Not receiving new trips after completion', style: TextStyle(color: kMuted, fontSize: 12)),
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
}

// ══════════════════════════════════════════════════════
//  COMPLETE TRIP DIALOG
// ══════════════════════════════════════════════════════
class _CompleteTripDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool isDark;
  const _CompleteTripDialog({required this.onConfirm, required this.isDark});

  @override
  State<_CompleteTripDialog> createState() => _CompleteTripDialogState();
}

class _CompleteTripDialogState extends State<_CompleteTripDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final driver   = context.watch<DriverProvider>(); // ✅
    final kCard    = widget.isDark ? const Color(0xFF152232) : Colors.white;
    final kText    = widget.isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted   = widget.isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF7A8FA6);
    final kCancel  = widget.isDark ? const Color(0xFF1E3040) : const Color(0xFFF0F4F8);
    // ✅ بيعرض destination حقيقي
    final destination = driver.activeTrip?.destination ?? 'the destination';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 64, height: 64,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 34)),
              const SizedBox(height: 20),
              Text('Complete Trip?', style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'Confirm that you have successfully delivered the shipment to $destination.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              _ShimmerConfirmBtn(onTap: () {
                Navigator.pop(context);
                widget.onConfirm();
              }),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(color: kCancel, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text('Cancel', style: TextStyle(color: kMuted, fontSize: 15)))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ShimmerConfirmBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _ShimmerConfirmBtn({required this.onTap});
  @override
  State<_ShimmerConfirmBtn> createState() => _ShimmerConfirmBtnState();
}

class _ShimmerConfirmBtnState extends State<_ShimmerConfirmBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _x;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _x = Tween<double>(begin: -300, end: 300).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00D5BE), Color(0xFF00B4A0)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))]),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(animation: _x, builder: (_, __) => Transform.translate(
            offset: Offset(_x.value, 0),
            child: Container(width: 100, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.2), Colors.transparent]))))),
          const Text('Yes, Complete Trip', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}