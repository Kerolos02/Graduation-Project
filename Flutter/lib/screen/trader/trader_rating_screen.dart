import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TRADER RATING SCREENS — trader_rating_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

const Duration _kFast = Duration(milliseconds: 300);
const Duration _kMed = Duration(milliseconds: 500);
const Duration _kSlow = Duration(milliseconds: 700);

class _SpringCurve extends Curve {
  final double stiffness, damping, mass;
  const _SpringCurve({
    this.stiffness = 200,
    this.damping = 15,
    this.mass = 1,
  });

  @override
  double transformInternal(double t) {
    final omega0 = math.sqrt(stiffness / mass);
    final zeta = damping / (2 * math.sqrt(stiffness * mass));
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

class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
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
          widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(scale: _s, child: widget.child),
      );
}

class _StarWidget extends StatefulWidget {
  final int index;
  final bool filled;
  final VoidCallback onTap;
  final Animation<double> entryScale;
  final Animation<double> entryOpacity;
  final Animation<double> entryRotate;

  const _StarWidget({
    required this.index,
    required this.filled,
    required this.onTap,
    required this.entryScale,
    required this.entryOpacity,
    required this.entryRotate,
  });

  @override
  State<_StarWidget> createState() => _StarWidgetState();
}

class _StarWidgetState extends State<_StarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _tapScale = Tween<double>(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [widget.entryScale, widget.entryOpacity, widget.entryRotate]),
      builder: (_, child) => Opacity(
        opacity: widget.entryOpacity.value,
        child: Transform.scale(
          scale: widget.entryScale.value,
          child: Transform.rotate(
            angle: widget.entryRotate.value,
            child: child,
          ),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTapDown: (_) => _tapCtrl.forward(),
          onTapUp: (_) {
            _tapCtrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _tapCtrl.reverse(),
          child: ScaleTransition(
            scale: _tapScale,
            child: AnimatedScale(
              scale: _hovering ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedRotation(
                turns: _hovering ? 15 / 360 : 0,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    widget.filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.filled
                        ? const Color(0xFF00D5BE)
                        : const Color(0xFF00D5BE).withOpacity(0.3),
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REVIEW RATING SCREEN
//  ✅ بتاخد shipmentId عشان تبعته للـ WriteReviewScreen
// ══════════════════════════════════════════════════════════════════════════════
class RateDriverScreen extends StatefulWidget {
  final String driverName, driverInitials;
  final String
      shipmentId; // ✅ جديد — POST /api/trader/shipments/{id}/rate-driver

  const RateDriverScreen({
    super.key,
    this.driverName = 'Ahmed Hassan',
    this.driverInitials = 'AH',
    this.shipmentId = '', // ✅ جديد
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen>
    with TickerProviderStateMixin {
  int _stars = 0;
  bool _recommend = false;
  int _easeOfAccess = 0, _timing = 0, _communication = 0, _facilities = 0;

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _driverCtrl;
  late Animation<double> _driverFade;
  late Animation<Offset> _driverSlide;
  late Animation<double> _driverScale;

  late AnimationController _starsCardCtrl;
  late Animation<double> _starsCardFade;
  late Animation<Offset> _starsCardSlide;
  late Animation<double> _starsCardScale;

  late List<AnimationController> _starCtrls;
  late List<Animation<double>> _starScales;
  late List<Animation<double>> _starFades;
  late List<Animation<double>> _starRotates;

  late AnimationController _recommendCtrl;
  late Animation<double> _recommendFade;
  late Animation<Offset> _recommendSlide;

  late AnimationController _aspectsCtrl;
  late Animation<double> _aspectsFade;
  late Animation<Offset> _aspectsSlide;
  late Animation<double> _aspectsScale;

  late List<List<AnimationController>> _aspectCircleCtrls;

  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  static const _ratingTexts = [
    '',
    'Poor experience',
    'Could be better',
    'Good trip',
    'Great trip!',
    "Great 5 stars! Can't get any better than that!",
  ];

  bool get _canSubmit => _stars > 0;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _headerCtrl = AnimationController(vsync: this, duration: _kSlow);
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerCtrl.forward();
    });

    _driverCtrl = AnimationController(vsync: this, duration: _kSlow);
    _driverFade = CurvedAnimation(parent: _driverCtrl, curve: Curves.easeOut);
    _driverSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _driverCtrl, curve: _kEaseSpring));
    _driverScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _driverCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _driverCtrl.forward();
    });

    _starsCardCtrl = AnimationController(vsync: this, duration: _kSlow);
    _starsCardFade =
        CurvedAnimation(parent: _starsCardCtrl, curve: Curves.easeOut);
    _starsCardSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _starsCardCtrl, curve: _kEaseSpring));
    _starsCardScale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _starsCardCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starsCardCtrl.forward();
    });

    _starCtrls = List.generate(
        5,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 600)));
    _starScales = _starCtrls
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: c, curve: const _SpringCurve(stiffness: 200, damping: 15))))
        .toList();
    _starFades = _starCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _starRotates = _starCtrls
        .map((c) => Tween<double>(begin: -math.pi, end: 0.0).animate(
            CurvedAnimation(
                parent: c,
                curve: const _SpringCurve(stiffness: 200, damping: 15))))
        .toList();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 600 + i * 100), () {
        if (mounted) _starCtrls[i].forward();
      });
    }

    _recommendCtrl = AnimationController(vsync: this, duration: _kSlow);
    _recommendFade =
        CurvedAnimation(parent: _recommendCtrl, curve: Curves.easeOut);
    _recommendSlide =
        Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: _recommendCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _recommendCtrl.forward();
    });

    _aspectsCtrl = AnimationController(vsync: this, duration: _kSlow);
    _aspectsFade = CurvedAnimation(parent: _aspectsCtrl, curve: Curves.easeOut);
    _aspectsSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _aspectsCtrl, curve: _kEaseSpring));
    _aspectsScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _aspectsCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _aspectsCtrl.forward();
    });

    _aspectCircleCtrls = List.generate(
        4,
        (_) => List.generate(
            5,
            (_) => AnimationController(
                vsync: this, duration: const Duration(milliseconds: 200))));

    _btnCtrl = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _driverCtrl.dispose();
    _starsCardCtrl.dispose();
    _recommendCtrl.dispose();
    _aspectsCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _starCtrls) c.dispose();
    for (final row in _aspectCircleCtrls) for (final c in row) c.dispose();
    super.dispose();
  }

  void _onAspectTap(int aspectIdx, int val) {
    setState(() {
      if (aspectIdx == 0) _easeOfAccess = val;
      if (aspectIdx == 1) _timing = val;
      if (aspectIdx == 2) _communication = val;
      if (aspectIdx == 3) _facilities = val;
    });
    final c = _aspectCircleCtrls[aspectIdx][val - 1];
    c.forward(from: 0).then((_) => c.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final kBg = const Color(0xFF0A1A24);
    final kCard = const Color(0xFF0A1628);
    final kText = Colors.white;
    final kMuted = const Color(0xFFCBFBF1);
    final kTeal = const Color(0xFF00D5BE);
    final kBorder = kTeal.withOpacity(0.2);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SafeArea(
          child: Column(children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Row(children: [
                    _backBtn(context, kCard, kTeal, kBorder),
                    const Spacer(),
                    Text('Reviews and Ratings',
                        style: TextStyle(
                            color: kText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(children: [
                // ── Driver card ──
                FadeTransition(
                  opacity: _driverFade,
                  child: SlideTransition(
                    position: _driverSlide,
                    child: ScaleTransition(
                      scale: _driverScale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCard.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(children: [
                          Stack(children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration:const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:  LinearGradient(
                                  colors: [
                                    Color(0xFF009689),
                                    Color(0xFF00BBA7),
                                    Color(0xFF00B8DB)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF192C3D)),
                                  child: const Center(
                                    child: Text("م ن",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF009689),
                                      Color(0xFF00B8DB)
                                    ],
                                  ),
                                  border: Border.all(
                                      color: const Color(0xFF0A1A24), width: 2),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 14),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.driverName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Professional Driver',
                                    style: TextStyle(
                                        color: kMuted.withOpacity(0.5),
                                        fontSize: 14)),
                              ]),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stars card ──
                FadeTransition(
                  opacity: _starsCardFade,
                  child: SlideTransition(
                    position: _starsCardSlide,
                    child: ScaleTransition(
                      scale: _starsCardScale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCard.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(children: [
                          Text('How was the trip?',
                              style: TextStyle(
                                  color: kText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                5,
                                (i) => _StarWidget(
                                      index: i,
                                      filled: i < _stars,
                                      onTap: () =>
                                          setState(() => _stars = i + 1),
                                      entryScale: _starScales[i],
                                      entryOpacity: _starFades[i],
                                      entryRotate: _starRotates[i],
                                    )),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: _kFast,
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              _ratingTexts[_stars],
                              key: ValueKey(_stars),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: kMuted.withOpacity(0.4), fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _recommendFade,
                            child: SlideTransition(
                              position: _recommendSlide,
                              child: _Tap(
                                onTap: () =>
                                    setState(() => _recommend = !_recommend),
                                child: Row(children: [
                                  AnimatedContainer(
                                    duration: _kFast,
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: _recommend
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF009689),
                                                Color(0xFF00B8DB)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: _recommend
                                          ? null
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _recommend
                                            ? Colors.transparent
                                            : kTeal.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _recommend
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text('I recommend this driver',
                                      style: TextStyle(
                                          color: _recommend
                                              ? kText
                                              : kMuted.withOpacity(0.4),
                                          fontSize: 14)),
                                ]),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Aspects card ──
                FadeTransition(
                  opacity: _aspectsFade,
                  child: SlideTransition(
                    position: _aspectsSlide,
                    child: ScaleTransition(
                      scale: _aspectsScale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCard.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How would you rate the following aspects?',
                                style: TextStyle(
                                    color: kMuted.withOpacity(0.9),
                                    fontSize: 14)),
                            const SizedBox(height: 20),
                            _aspectRow(0, 'Ease of access', _easeOfAccess,
                                kText, kTeal, kMuted),
                            const SizedBox(height: 20),
                            _aspectRow(
                                1, 'Timing', _timing, kText, kTeal, kMuted),
                            const SizedBox(height: 20),
                            _aspectRow(2, 'Communication', _communication,
                                kText, kTeal, kMuted),
                            const SizedBox(height: 20),
                            _aspectRow(3, 'Facilities', _facilities, kText,
                                kTeal, kMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            )),

            // ── Continue button ──
            SlideTransition(
              position: _btnSlide,
              child: FadeTransition(
                opacity: _btnFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AnimatedOpacity(
                    opacity: _canSubmit ? 1.0 : 0.35,
                    duration: _kFast,
                    child: _Tap(
                      onTap: _canSubmit
                          // ✅ بيمرر shipmentId + rating + recommend للـ WriteReviewScreen
                          ? () => Navigator.push(
                              context,
                              _slideUpRoute(WriteReviewScreen(
                                shipmentId: widget.shipmentId,
                                rating: _stars,
                                recommend: _recommend,
                              )))
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _canSubmit
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF009689),
                                    Color(0xFF00BBA7),
                                    Color(0xFF00B8DB)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: _canSubmit
                              ? null
                              : const Color(0xFF00D5BE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: _canSubmit
                              ? null
                              : Border.all(
                                  color:
                                      const Color(0xFF00D5BE).withOpacity(0.2)),
                          boxShadow: _canSubmit
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF00D5BE)
                                          .withOpacity(0.25),
                                      blurRadius: 9,
                                      offset: const Offset(0, 6))
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text('Continue',
                            style: TextStyle(
                                color: _canSubmit
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _aspectRow(int idx, String label, int selected, Color kText,
      Color kTeal, Color kMuted) {
    const labels = ['Bad', 'So so', 'Good', 'Great', 'Amazing'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          final active = selected == i + 1;
          return _Tap(
            onTap: () => _onAspectTap(idx, i + 1),
            child: Column(children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.25).animate(
                    CurvedAnimation(
                        parent: _aspectCircleCtrls[idx][i],
                        curve: Curves.easeOutBack)),
                child: AnimatedContainer(
                  duration: _kFast,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: active
                        ? const LinearGradient(
                            colors: [Color(0xFF009689), Color(0xFF00B8DB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: active ? null : Colors.transparent,
                    border: Border.all(
                      color:
                          active ? Colors.transparent : kTeal.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                          color:
                              active ? Colors.white : kMuted.withOpacity(0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style:
                      TextStyle(color: kMuted.withOpacity(0.4), fontSize: 10)),
            ]),
          );
        }),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WRITE REVIEW SCREEN
//  ✅ بتاخد shipmentId + rating + recommend
//  ✅ Submit بيكلم POST /api/trader/shipments/{shipmentId}/rate-driver
// ══════════════════════════════════════════════════════════════════════════════
class WriteReviewScreen extends StatefulWidget {
  final String shipmentId; // ✅ جديد
  final int rating; // ✅ جديد — الـ stars من الـ screen اللي قبلها
  final bool recommend; // ✅ جديد

  const WriteReviewScreen({
    super.key,
    this.shipmentId = '',
    this.rating = 5,
    this.recommend = false,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen>
    with TickerProviderStateMixin {
  final _summaryCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _summaryFocus = FocusNode();
  final _reviewFocus = FocusNode();

  bool _isSaving = false; // ✅ جديد — loading state

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    _summaryFocus.addListener(() => setState(() {}));
    _reviewFocus.addListener(() => setState(() {}));

    _pageCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _headerCtrl = AnimationController(vsync: this, duration: _kSlow);
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerCtrl.forward();
    });

    _btnCtrl = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _reviewCtrl.dispose();
    _summaryFocus.dispose();
    _reviewFocus.dispose();
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  // ✅ POST /api/trader/shipments/{shipmentId}/rate-driver
  Future<void> _submitReview() async {
    if (_isSaving) return;

    // لو مفيش shipmentId → demo mode
    if (widget.shipmentId.isEmpty) {
      Navigator.push(context, _slideUpRoute(const ReviewSubmittedScreen()));
      return;
    }

    setState(() => _isSaving = true);

    final comment = _reviewCtrl.text.trim().isNotEmpty
        ? _reviewCtrl.text.trim()
        : _summaryCtrl.text.trim();

    final ok = await context.read<TraderProvider>().rateDriver(
          shipmentId: widget.shipmentId,
          rating: widget.rating,
          comment: comment.isNotEmpty ? comment : null,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.push(context, _slideUpRoute(const ReviewSubmittedScreen()));
    } else {
      // لو فشل، بنروح للـ submitted screen برضو وبنعرض error
      final err =
          context.read<TraderProvider>().error ?? 'Failed to submit review';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  BoxDecoration _rnCardDecoration(bool focused) => BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A3A), Color(0xFF0A1F2F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: focused
              ? const Color(0xFF00D5BE).withOpacity(0.5)
              : const Color(0xFF364153).withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 8)),
        ],
      );

  InputDecoration _fieldDecoration(String hint, bool focused) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0A1F2F),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: focused
                  ? const Color(0xFF00D5BE).withOpacity(0.5)
                  : const Color(0xFF364153).withOpacity(0.5),
              width: 0.8,
            )),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: const Color(0xFF364153).withOpacity(0.5), width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: const Color(0xFF00D5BE).withOpacity(0.5), width: 0.8)),
      );

  @override
  Widget build(BuildContext context) {
    const kBg = Color(0xFF0A1A24);
    const kTeal = Color(0xFF00D5BE);
    const kCard = Color(0xFF0A1628);
    const kText = Colors.white;
    const kMuted = Color(0xFFD1D5DC);
    const kGray = Color(0xFF6A7282);
    final kBorder = kTeal.withOpacity(0.2);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SafeArea(
          child: Column(children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Row(children: [
                    _backBtn(context, kCard, kTeal, kBorder),
                    const Spacer(),
                    const Text('Write Review',
                        style: TextStyle(
                            color: kText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ]),
                ),
              ),
            ),

            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(children: [
                // ── Summary card ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _rnCardDecoration(_summaryFocus.hasFocus),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Summarize your review',
                            style: TextStyle(color: kMuted, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _summaryCtrl,
                          focusNode: _summaryFocus,
                          style: const TextStyle(color: kText, fontSize: 14),
                          decoration: _fieldDecoration(
                              'Great experience!', _summaryFocus.hasFocus),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),

                // ── Review text card ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _rnCardDecoration(_reviewFocus.hasFocus),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Write your review',
                            style: TextStyle(color: kMuted, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewCtrl,
                          focusNode: _reviewFocus,
                          maxLines: 6,
                          style: const TextStyle(color: kText, fontSize: 14),
                          decoration: _fieldDecoration(
                              'Share details about your experience...',
                              _reviewFocus.hasFocus),
                        ),
                      ]),
                ),
                const SizedBox(height: 16),

                // ── Upload photos card ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _rnCardDecoration(false),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upload Photos',
                            style: TextStyle(color: kMuted, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Share photos from the trip (optional)',
                            style: TextStyle(color: kGray, fontSize: 14)),
                        const SizedBox(height: 14),
                        _Tap(
                          onTap: () {},
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1F2F),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF364153), width: 1.6),
                            ),
                            child: const Icon(Icons.upload_outlined,
                                color: Color(0xFF4A5565), size: 24),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: 32),

                // ── Submit button ──
                SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: _Tap(
                      // ✅ بيكلم الـ API
                      onTap: _isSaving ? null : _submitReview,
                      child: Container(
                        width: double.infinity, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF009689),
                              Color(0xFF00BBA7),
                              Color(0xFF00B8DB)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kTeal.withOpacity(0.25),
                              blurRadius: 9,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        // ✅ Loading indicator لو بيحفظ
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('Submit Review',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REVIEW SUBMITTED SCREEN  (unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class ReviewSubmittedScreen extends StatefulWidget {
  const ReviewSubmittedScreen({super.key});

  @override
  State<ReviewSubmittedScreen> createState() => _ReviewSubmittedScreenState();
}

class _ReviewSubmittedScreenState extends State<ReviewSubmittedScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _iconRotate;

  late AnimationController _glowCtrl;
  late Animation<double> _glowScale;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _iconCtrl = AnimationController(vsync: this, duration: _kSlow);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _iconCtrl,
        curve: const _SpringCurve(stiffness: 200, damping: 15)));
    _iconFade = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);
    _iconRotate = Tween<double>(begin: -math.pi, end: 0.0).animate(
        CurvedAnimation(
            parent: _iconCtrl,
            curve: const _SpringCurve(stiffness: 200, damping: 15)));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconCtrl.forward();
    });

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowScale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.4, end: 0.6)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _iconCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kBg = Color(0xFF0A1A24);
    const kCard = Color(0xFF0A1628);
    const kTeal = Color(0xFF00D5BE);
    const kText = Colors.white;
    const kMuted = Color(0xFFF0FDF9);
    final kBorder = kTeal.withOpacity(0.2);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: Listenable.merge([_iconCtrl, _glowCtrl]),
                builder: (_, __) => Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(alignment: Alignment.center, children: [
                      Transform.scale(
                        scale: _glowScale.value,
                        child: Opacity(
                          opacity: _glowOpacity.value,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [
                                Color(0xFF009689),
                                Color(0xFF00B8DB),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _iconFade.value,
                        child: Transform.scale(
                          scale: _iconScale.value,
                          child: Transform.rotate(
                            angle: _iconRotate.value,
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF009689),
                                    Color(0xFF00B8DB)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: kTeal.withOpacity(0.35),
                                      blurRadius: 30,
                                      spreadRadius: 4)
                                ],
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 52),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: kCard.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(children: [
                    const Text('Thank you for your\nreview!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: kText,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    Text(
                      'You help fellow travellers and\ntraders in discovering the best experiences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kMuted.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.6),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 140,
                child: Stack(alignment: Alignment.center, children: [
                  Transform.rotate(
                    angle: 24 * math.pi / 180,
                    child:
                        Opacity(opacity: 0.6, child: _decorCard(kCard, kTeal)),
                  ),
                  Transform.rotate(
                    angle: -12 * math.pi / 180,
                    child:
                        Opacity(opacity: 0.8, child: _decorCard(kCard, kTeal)),
                  ),
                  _decorCardFull(kCard, kTeal),
                ]),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _Tap(
                  onTap: () => Navigator.push(
                      context, _slideRightRoute(const ReviewsListScreen())),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF009689),
                          Color(0xFF00BBA7),
                          Color(0xFF00B8DB)
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: kTeal.withOpacity(0.25),
                            blurRadius: 9,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('View All Reviews',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _decorCard(Color kCard, Color kTeal) => Container(
        width: 112,
        height: 120,
        decoration: BoxDecoration(
          color: kCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTeal.withOpacity(0.2)),
        ),
      );

  Widget _decorCardFull(Color kCard, Color kTeal) => Container(
        width: 96,
        height: 112,
        decoration: BoxDecoration(
          color: kCard.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kTeal.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
              children: List.generate(
                  5,
                  (i) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF009689))))),
          const SizedBox(height: 10),
          Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFF009689).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 6),
          Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFF009689).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 6),
          Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFF009689).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3))),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  REVIEWS LIST SCREEN  (unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class ReviewsListScreen extends StatefulWidget {
  const ReviewsListScreen({super.key});

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen>
    with TickerProviderStateMixin {
  static const _reviews = [
    (
      time: 'Just now',
      title: 'Excellent service',
      body:
          'Very professional driver. Delivered everything on time and in perfect condition.',
      stars: 5,
      hasPhotos: true,
      isNew: true
    ),
    (
      time: '5 days ago',
      title: 'Good communication',
      body:
          'Driver kept me updated throughout the journey. Everything arrived safely.',
      stars: 4,
      hasPhotos: false,
      isNew: false
    ),
    (
      time: '1 week ago',
      title: 'Outstanding!',
      body: 'Best driver I have worked with. Very careful with the cargo.',
      stars: 5,
      hasPhotos: true,
      isNew: false
    ),
  ];

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _driverCtrl;
  late Animation<double> _driverScale, _driverFade;
  final List<AnimationController> _rowCtrls = [];
  final List<Animation<double>> _rowFades = [];
  final List<Animation<Offset>> _rowSlides = [];
  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _headerCtrl = AnimationController(vsync: this, duration: _kSlow);
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerCtrl.forward();
    });

    _driverCtrl = AnimationController(vsync: this, duration: _kMed);
    _driverScale = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _driverCtrl, curve: Curves.easeOutBack));
    _driverFade = CurvedAnimation(parent: _driverCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _driverCtrl.forward();
    });

    for (int i = 0; i < _reviews.length; i++) {
      final c = AnimationController(vsync: this, duration: _kMed);
      _rowCtrls.add(c);
      _rowFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _rowSlides.add(
          Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 350 + i * 80), () {
        if (mounted) c.forward();
      });
    }

    _btnCtrl = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _driverCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _rowCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kBg = isDark ? const Color(0xFF0A1A24) : const Color(0xFFF5F8FA);
    final kCard = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kCard2 = isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF8FAFB);
    final kText = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted = isDark ? const Color(0xFFCBFBF1) : const Color(0xFF8A9BB0);
    const kTeal = Color(0xFF00D5BE);
    final kBorder = isDark ? kTeal.withOpacity(0.15) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Row(children: [
                  _backBtn(context, kCard, kTeal, kBorder),
                  const SizedBox(width: 14),
                  Text('Reviews & Ratings',
                      style: TextStyle(
                          color: kText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              ScaleTransition(
                scale: _driverScale,
                child: FadeTransition(
                  opacity: _driverFade,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: isDark ? kCard2 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ]),
                    child: Column(children: [
                      Row(children: [
                        Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF8904),
                                      Color(0xFF9810FA)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                border: Border.all(color: kTeal, width: 2)),
                            child: const Center(
                                child: Text('TM',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 16),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Toka Mohamed',
                                  style: TextStyle(
                                      color: kText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text('Professional Driver',
                                  style:
                                      TextStyle(color: kMuted, fontSize: 13)),
                            ]),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? kCard.withOpacity(0.6)
                                  : const Color(0xFFF0F9F8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder)),
                          child: Row(children: [
                            const Icon(Icons.star_rounded,
                                color: kTeal, size: 24),
                            const SizedBox(width: 8),
                            Text('4.7',
                                style: TextStyle(
                                    color: kText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(
                                width: 1,
                                height: 20,
                                color: kTeal.withOpacity(0.3)),
                            const SizedBox(width: 12),
                            Text('3 reviews',
                                style: TextStyle(color: kMuted, fontSize: 14)),
                          ])),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(_reviews.length, (i) {
                final r = _reviews[i];
                return FadeTransition(
                  opacity: _rowFades[i],
                  child: SlideTransition(
                    position: _rowSlides[i],
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _reviewTile(
                          r.time,
                          r.title,
                          r.body,
                          r.stars,
                          r.hasPhotos,
                          r.isNew,
                          isDark,
                          kCard2,
                          kText,
                          kMuted,
                          kTeal,
                          kBorder),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: _Tap(
                    onTap: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF009689), Color(0xFF00D5BE)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    const Color(0xFF00D5BE).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ]),
                      alignment: Alignment.center,
                      child: const Text('Back to Home',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _reviewTile(
          String time,
          String title,
          String body,
          int stars,
          bool hasPhotos,
          bool isNew,
          bool isDark,
          Color kCard2,
          Color kText,
          Color kMuted,
          Color kTeal,
          Color kBorder) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? kCard2 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1C3449)
                          : const Color(0xFFE8F5F4)),
                  child: Center(
                      child: Text('T',
                          style: TextStyle(
                              color: isDark ? kMuted.withOpacity(0.6) : kTeal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Trader',
                        style: TextStyle(
                            color: kText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(time, style: TextStyle(color: kMuted, fontSize: 12)),
                  ])),
              if (isNew)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: kTeal, borderRadius: BorderRadius.circular(20)),
                    child: const Text('New',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)))
              else
                Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i < stars ? kTeal : kMuted.withOpacity(0.3),
                            size: 18))),
            ]),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: kText, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body,
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
            if (hasPhotos) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.camera_alt_outlined, color: kTeal, size: 16),
                const SizedBox(width: 6),
                Text('Photos attached',
                    style: TextStyle(color: kTeal, fontSize: 13)),
              ]),
            ],
          ]));
}

// ══════════════════════════════════════════════════════════════════════════════
//  ROUTE HELPERS
// ══════════════════════════════════════════════════════════════════════════════
Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: _kMed,
      reverseTransitionDuration: _kFast,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: _kEaseSpring)),
        child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child),
      ),
    );

Route<T> _slideRightRoute<T>(Widget child) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: _kMed,
      reverseTransitionDuration: _kFast,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: _kEaseSpring)),
        child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child),
      ),
    );

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED HELPER
// ══════════════════════════════════════════════════════════════════════════════
Widget _backBtn(
        BuildContext context, Color kCard, Color kTeal, Color kBorder) =>
    _Tap(
        onTap: () => Navigator.pop(context),
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: kCard.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: kBorder)),
            child: Icon(Icons.arrow_back, color: kTeal, size: 18)
        )
    );
