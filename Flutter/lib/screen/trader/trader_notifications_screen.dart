import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

enum NotifState { withData, empty, loading, error }

class _SpringCurve extends Curve {
  final double stiffness, damping, mass;
  const _SpringCurve({required this.stiffness, required this.damping, required this.mass});
  @override
  double transformInternal(double t) {
    final omega0 = math.sqrt(stiffness / mass);
    final zeta = damping / (2 * math.sqrt(stiffness * mass));
    if (zeta < 1) {
      final omegaD = omega0 * math.sqrt(1 - zeta * zeta);
      return 1 - math.exp(-zeta * omega0 * t) *
          (math.cos(omegaD * t) + (zeta * omega0 / omegaD) * math.sin(omegaD * t));
    }
    return 1 - math.exp(-omega0 * t) * (1 + omega0 * t);
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const _PressScale({required this.child, this.onTap, this.scale = 0.92});
  @override State<_PressScale> createState() => _PressScaleState();
}
class _PressScaleState extends State<_PressScale> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _anim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _anim, child: widget.child),
  );
}

class _ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const _ShimmerBox({required this.width, required this.height, this.radius = 8});
  @override State<_ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF00D5BE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

enum _NotifType { action, update, info }

class _Notif {
  final String id, title, message, time;
  final _NotifType type;
  final bool isRead;
  final String? actionLabel, actionScreen;
  const _Notif({
    required this.id, required this.type, required this.title,
    required this.message, required this.time,
    this.isRead = false, this.actionLabel, this.actionScreen,
  });
  _Notif copyWith({bool? isRead}) => _Notif(
    id: id, type: type, title: title, message: message, time: time,
    isRead: isRead ?? this.isRead, actionLabel: actionLabel, actionScreen: actionScreen,
  );
}

class _NotifColors {
  final Color dot, bg, border, badge, text;
  const _NotifColors({required this.dot, required this.bg, required this.border,
      required this.badge, required this.text});
}

_NotifColors _colorsFor(_NotifType type) {
  switch (type) {
    case _NotifType.action:
      return const _NotifColors(
        dot: Color(0xFFFF8904), bg: Color(0x4DFF8904),
        border: Color(0xFFFF8904), badge: Color(0x1AFF8904), text: Color(0xFFFF8904),
      );
    case _NotifType.update:
      return const _NotifColors(
        dot: Color(0xFF3B82F6), bg: Color(0x4D3B82F6),
        border: Color(0xFF3B82F6), badge: Color(0x1A3B82F6), text: Color(0xFF3B82F6),
      );
    case _NotifType.info:
      return const _NotifColors(
        dot: Color(0xFF10B981), bg: Color(0x4D10B981),
        border: Color(0xFF10B981), badge: Color(0x1A10B981), text: Color(0xFF10B981),
      );
  }
}

final _kInitialNotifs = [
  const _Notif(
    id: '1', type: _NotifType.action,
    title: 'Driver accepted shipment',
    message: 'Driver Ahmed has accepted your shipment #SH-4521 from Cairo to Alexandria',
    time: '2h ago', isRead: false,
    actionLabel: 'Track Shipment', actionScreen: '/map',
  ),
  const _Notif(
    id: '2', type: _NotifType.update,
    title: 'Shipment in transit',
    message: 'Your shipment #SH-4520 is on the way to the destination',
    time: '5h ago', isRead: false,
    actionLabel: 'View Details', actionScreen: '/shipment-details',
  ),
  const _Notif(
    id: '3', type: _NotifType.info,
    title: 'Payment received',
    message: 'Payment of \$285 has been processed for shipment #SH-4519',
    time: '1d ago', isRead: true,
  ),
  const _Notif(
    id: '4', type: _NotifType.update,
    title: 'Shipment delivered',
    message: 'Your shipment #SH-4518 has been successfully delivered',
    time: '2d ago', isRead: true,
    actionLabel: 'Rate Driver', actionScreen: '/rate-driver',
  ),
];

class TraderNotificationsScreen extends StatefulWidget {
  final NotifState state;
  const TraderNotificationsScreen({super.key, this.state = NotifState.withData});
  @override State<TraderNotificationsScreen> createState() => _TraderNotificationsScreenState();
}

class _TraderNotificationsScreenState extends State<TraderNotificationsScreen>
    with TickerProviderStateMixin {

  List<_Notif> _notifs = List.from(_kInitialNotifs);

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardScale;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _todayLabelCtrl;
  late Animation<double> _todayLabelFade;
  late AnimationController _earlierLabelCtrl;
  late Animation<double> _earlierLabelFade;
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;
  late AnimationController _markAllCtrl;
  late Animation<double> _markAllScale;
  final List<AnimationController> _cardCtrls = [];
  final List<Animation<double>> _cardFades = [];
  final List<Animation<Offset>> _cardSlides = [];
  final List<AnimationController> _dotCtrls = [];
  final List<Animation<double>> _dotScales = [];
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late AnimationController _progressCtrl1;
  late Animation<double> _progressAnim1;
  late AnimationController _progressCtrl2;
  late Animation<double> _progressAnim2;
  late AnimationController _wobbleCtrl;
  late Animation<double> _wobbleAngle;

  static const int _kTotal = 4, _kDelayItems = 300, _kStagger = 120;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl,
            curve: const _SpringCurve(stiffness: 180, damping: 20, mass: 1)));
    _cardScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _cardCtrl.forward(); });

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const _SpringCurve(stiffness: 120, damping: 18, mass: 0.5)));
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _headerCtrl.forward(); });

    _badgeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _badgeCtrl.forward(); });

    _markAllCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _markAllScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _markAllCtrl,
            curve: const _SpringCurve(stiffness: 200, damping: 15, mass: 1)));
    Future.delayed(const Duration(milliseconds: 450), () { if (mounted) _markAllCtrl.forward(); });

    _todayLabelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _todayLabelFade = CurvedAnimation(parent: _todayLabelCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 250), () { if (mounted) _todayLabelCtrl.forward(); });

    _earlierLabelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _earlierLabelFade = CurvedAnimation(parent: _earlierLabelCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 700), () { if (mounted) _earlierLabelCtrl.forward(); });

    for (int i = 0; i < _kTotal; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
      _cardCtrls.add(c);
      _cardFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _cardSlides.add(Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: c,
              curve: const _SpringCurve(stiffness: 120, damping: 18, mass: 0.8))));
      Future.delayed(Duration(milliseconds: _kDelayItems + i * _kStagger),
          () { if (mounted) c.forward(); });
    }

    for (int i = 0; i < _kTotal; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      _dotCtrls.add(c);
      _dotScales.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: c,
              curve: const _SpringCurve(stiffness: 200, damping: 15, mass: 1.0))));
      Future.delayed(Duration(milliseconds: _kDelayItems + i * _kStagger + 200),
          () { if (mounted) c.forward(); });
    }

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.6), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _progressCtrl1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _progressAnim1 = Tween<double>(begin: 0.0, end: 0.47).animate(
        CurvedAnimation(parent: _progressCtrl1, curve: const Cubic(0.4, 0.0, 0.2, 1.0)));
    Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _progressCtrl1.forward(); });

    _progressCtrl2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _progressAnim2 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _progressCtrl2, curve: const Cubic(0.4, 0.0, 0.2, 1.0)));
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _progressCtrl2.forward(); });

    _wobbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _wobbleAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0 * math.pi / 180), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 5.0 * math.pi / 180, end: -5.0 * math.pi / 180), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -5.0 * math.pi / 180, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _cardCtrl.dispose();
    _headerCtrl.dispose();
    _badgeCtrl.dispose();
    _markAllCtrl.dispose();
    _todayLabelCtrl.dispose();
    _earlierLabelCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    for (final c in _dotCtrls) c.dispose();
    _pulseCtrl.dispose();
    _progressCtrl1.dispose();
    _progressCtrl2.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  void _markAllRead() => setState(() {
    _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList();
  });

  void _handleTap(_Notif notif) {
    setState(() {
      _notifs = _notifs.map((n) => n.id == notif.id ? n.copyWith(isRead: true) : n).toList();
    });
    if (notif.actionScreen != null) Navigator.pushNamed(context, notif.actionScreen!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFEFF6F5);
    final kCard   = isDark ? const Color(0xFF0F1C2E) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF0A1628);
    final kMuted  = isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    final kDeep   = isDark ? const Color(0xFF0A1520) : const Color(0xFFF0F7F6);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _PressScale(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF00D5BE),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                          position: _headerSlide,
                          // ✅ العنوان اتغير لـ "Alerts"
                          child: Text(
                            'Alerts',
                            style: TextStyle(
                              color: kText,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _buildBody(
                      isDark: isDark,
                      kCard: kCard,
                      kText: kText,
                      kMuted: kMuted,
                      kBorder: kBorder,
                      kDeep: kDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isDark, required Color kCard, required Color kText,
      required Color kMuted, required Color kBorder, required Color kDeep}) {
    switch (widget.state) {
      case NotifState.loading:
        return _buildLoading(kCard: kCard, kBorder: kBorder);
      case NotifState.empty:
        return _buildEmpty(kCard: kCard, kText: kText, kBorder: kBorder);
      case NotifState.error:
        return _buildError(kCard: kCard, kText: kText, kBorder: kBorder);
      case NotifState.withData:
        return _buildWithData(isDark: isDark, kCard: kCard, kText: kText,
            kMuted: kMuted, kBorder: kBorder, kDeep: kDeep);
    }
  }

  Widget _buildLoading({required Color kCard, required Color kBorder}) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBorder),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: 160, height: 26, radius: 8),
                const SizedBox(height: 8),
                const _ShimmerBox(width: 100, height: 14, radius: 6),
                const SizedBox(height: 28),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShimmerBox(width: 24, height: 24, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBox(width: double.infinity, height: 80, radius: 14),
                            const SizedBox(height: 8),
                            _ShimmerBox(width: 120, height: 12, radius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty({required Color kCard, required Color kText, required Color kBorder}) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBorder),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  // ✅ "Alerts"
                  child: Text('Alerts',
                      style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 48),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D5BE).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Color(0xFF00D5BE), size: 38),
                ),
                const SizedBox(height: 20),
                Text('No Alerts Yet',
                    style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text("You're all caught up!\nNew alerts will appear here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kText.withOpacity(0.45), fontSize: 14, height: 1.6)),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError({required Color kCard, required Color kText, required Color kBorder}) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBorder),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  // ✅ "Alerts"
                  child: Text('Alerts',
                      style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 48),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 38),
                ),
                const SizedBox(height: 20),
                Text('Unable to Load Alerts',
                    style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('There was an error loading your alerts.\nPlease try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kText.withOpacity(0.45), fontSize: 14, height: 1.6)),
                const SizedBox(height: 28),
                _PressScale(
                  onTap: () => setState(() {}),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D5BE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithData({required bool isDark, required Color kCard, required Color kText,
      required Color kMuted, required Color kBorder, required Color kDeep}) {
    final unreadCount = _notifs.where((n) => !n.isRead).length;
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBorder),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _headerFade,
                            // ✅ "Alerts"
                            child: Text('Alerts',
                                style: TextStyle(color: kText, fontSize: 24, fontWeight: FontWeight.w700)),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            ScaleTransition(
                              scale: _badgeScale,
                              child: Text('$unreadCount unread',
                                  style: TextStyle(color: kText.withOpacity(0.5), fontSize: 14)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      ScaleTransition(
                        scale: _markAllScale,
                        child: _PressScale(
                          onTap: _markAllRead,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D5BE).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.done_all_rounded, color: Color(0xFF00D5BE), size: 16),
                                SizedBox(width: 6),
                                Text('Mark all read',
                                    style: TextStyle(color: Color(0xFF00D5BE),
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _todayLabelFade,
                  child: Text('Today',
                      style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                ..._notifs.asMap().entries.where((e) => e.key < 2).map((e) =>
                    _buildNotifItem(index: e.key, notif: e.value, isLast: e.key == 1,
                        isDark: isDark, kCard: kCard, kDeep: kDeep, kText: kText, kMuted: kMuted)),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _earlierLabelFade,
                  child: Text('Earlier',
                      style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                ..._notifs.asMap().entries.where((e) => e.key >= 2).map((e) =>
                    _buildNotifItem(index: e.key, notif: e.value, isLast: e.key == _notifs.length - 1,
                        isDark: isDark, kCard: kCard, kDeep: kDeep, kText: kText, kMuted: kMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required int index,
    required _Notif notif,
    required bool isLast,
    required bool isDark,
    required Color kCard,
    required Color kDeep,
    required Color kText,
    required Color kMuted,
  }) {
    final colors = _colorsFor(notif.type);
    final cardFade = index < _cardFades.length ? _cardFades[index] : const AlwaysStoppedAnimation(1.0);
    final cardSlide = index < _cardSlides.length ? _cardSlides[index] : const AlwaysStoppedAnimation(Offset.zero);
    final dotScale = index < _dotScales.length ? _dotScales[index] : const AlwaysStoppedAnimation(1.0);
    final isRunning = notif.type == _NotifType.action;
    final hasProgress = notif.type == _NotifType.action || notif.type == _NotifType.update;
    final progressAnim = index == 0 ? _progressAnim1 : _progressAnim2;
    final isFilled = notif.type == _NotifType.action;

    return IntrinsicHeight(
      child: Opacity(
        opacity: notif.isRead ? 0.6 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  ScaleTransition(
                    scale: dotScale,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isRunning)
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseScale.value,
                                child: Opacity(
                                  opacity: _pulseOpacity.value,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.dot.withOpacity(0.6),
                                      boxShadow: [BoxShadow(
                                        color: colors.dot.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bg,
                              border: Border.all(color: colors.border, width: 1.6),
                            ),
                            child: Center(
                              child: isRunning
                                  ? AnimatedBuilder(
                                      animation: _pulseCtrl,
                                      builder: (_, child) => Transform.scale(
                                        scale: _pulseScale.value * 0.9,
                                        child: child,
                                      ),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.dot,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.dot,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFF00D5BE).withOpacity(0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeTransition(
                opacity: cardFade,
                child: SlideTransition(
                  position: cardSlide,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.time,
                            style: TextStyle(color: kMuted.withOpacity(0.7), fontSize: 11)),
                        const SizedBox(height: 6),
                        _PressScale(
                          onTap: () => _handleTap(notif),
                          child: Container(
                            decoration: BoxDecoration(
                              color: kDeep,
                              borderRadius: BorderRadius.circular(18),
                              border: isDark
                                  ? Border.all(color: const Color(0xFF00D5BE).withOpacity(0.1), width: 0.8)
                                  : Border.all(color: colors.dot.withOpacity(0.15)),
                              boxShadow: isDark ? [] : [
                                BoxShadow(color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors.badge.withOpacity(isDark ? 0.15 : 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: isDark
                                              ? Border.all(color: colors.dot.withOpacity(0.4), width: 0.8)
                                              : null,
                                        ),
                                        child: Text(
                                          notif.type == _NotifType.action
                                              ? 'Action Required'
                                              : notif.type == _NotifType.update
                                                  ? 'Update'
                                                  : 'Info',
                                          style: TextStyle(
                                              color: colors.text, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (hasProgress && index < 2) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(99),
                                            child: AnimatedBuilder(
                                              animation: progressAnim,
                                              builder: (_, __) => LinearProgressIndicator(
                                                value: progressAnim.value,
                                                minHeight: 4,
                                                backgroundColor: Colors.white.withOpacity(0.1),
                                                valueColor: AlwaysStoppedAnimation(colors.dot),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedBuilder(
                                          animation: progressAnim,
                                          builder: (_, __) => Text(
                                            '${(progressAnim.value * 100).round()}%',
                                            style: TextStyle(
                                                color: colors.dot, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: kCard,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      isRunning
                                          ? AnimatedBuilder(
                                              animation: _wobbleAngle,
                                              builder: (_, child) => Transform.rotate(
                                                angle: _wobbleAngle.value,
                                                child: child,
                                              ),
                                              child: _iconBox(notif, colors, isDark),
                                            )
                                          : _iconBox(notif, colors, isDark),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(notif.title,
                                                style: TextStyle(color: kText, fontSize: 14,
                                                    fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(notif.message,
                                                style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white.withOpacity(0.55)
                                                        : const Color(0xFF6B8096),
                                                    fontSize: 12, height: 1.5)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (notif.actionLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    child: isFilled
                                        ? _PressScale(
                                            onTap: () => _handleTap(notif),
                                            child: Container(
                                              width: double.infinity,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: colors.dot,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(notif.actionLabel!,
                                                  style: const TextStyle(color: Colors.white,
                                                      fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                          )
                                        : Align(
                                            alignment: Alignment.centerLeft,
                                            child: _PressScale(
                                              onTap: () => _handleTap(notif),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 14, vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: colors.dot.withOpacity(isDark ? 0.12 : 0.10),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: colors.dot.withOpacity(isDark ? 0.3 : 0.4),
                                                      width: 0.8),
                                                ),
                                                child: Text(notif.actionLabel!,
                                                    style: TextStyle(color: colors.dot,
                                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                              ),
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(_Notif notif, _NotifColors colors, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.dot.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_iconFor(notif.type), color: colors.dot, size: 20),
    );
  }

  IconData _iconFor(_NotifType type) {
    switch (type) {
      case _NotifType.action: return Icons.check_circle_outline_rounded;
      case _NotifType.update: return Icons.inventory_2_outlined;
      case _NotifType.info:   return Icons.attach_money_rounded;
    }
  }
}