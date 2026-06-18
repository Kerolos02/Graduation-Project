import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TRADER THEME  — Light / Dark
// ══════════════════════════════════════════════════════════════════════════════
class TraderTheme {
  final bool isDark;
  const TraderTheme({required this.isDark});

  static const Color accent     = Color(0xFF00D5BE);
  static const Color accentSoft = Color(0xFF00B4A0);
  static const Color danger     = Color(0xFFFF476D);
  static const Color warning    = Color(0xFFF3B64C);

  Color get bg          => isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
  Color get surface     => isDark ? const Color(0xFF152232) : Colors.white;
  Color get surfaceSoft => isDark ? const Color(0xFF1A2B3C) : const Color(0xFFF0F4F8);
  Color get surfaceDeep => isDark ? const Color(0xFF0A1A28) : const Color(0xFFEAF0F6);
  Color get border      => isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
  Color get textPrimary => isDark ? Colors.white            : const Color(0xFF1A2A3A);
  Color get textMuted   => isDark ? const Color(0xFF6B8A9E) : const Color(0xFF7A93A8);
  Color get mapBg       => isDark ? const Color(0xFF0A2A45) : const Color(0xFFDEEFF8);

  List<BoxShadow> get cardShadow => isDark
      ? []
      : [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))];
}

TraderTheme traderTheme(BuildContext context) =>
    TraderTheme(isDark: context.watch<ThemeProvider>().isDark);

const Color traderBackground  = Color(0xFF0D1F2D);
const Color traderSurface     = Color(0xFF152232);
const Color traderSurfaceSoft = Color(0xFF1A2B3C);
const Color traderSurfaceDeep = Color(0xFF0A1A28);
const Color traderAccent      = Color(0xFF00D5BE);
const Color traderAccentSoft  = Color(0xFF00B4A0);
const Color traderTextMuted   = Color(0xFF6B8A9E);
const Color traderDanger      = Color(0x99773A59);

// ══════════════════════════════════════════════════════════════════════════════
//  TRADER PANEL
//  RN: itemVariants → opacity:0 y:20 → opacity:1 y:0
//      spring stiffness:100 damping:15
//  Usage: TraderPanel(animate: true, animDelay: Duration(ms: 200), ...)
// ══════════════════════════════════════════════════════════════════════════════
class TraderPanel extends StatefulWidget {
  const TraderPanel({
    super.key,
    required this.child,
    this.padding    = const EdgeInsets.all(14),
    this.radius     = 18.0,
    this.color,
    this.borderColor,
    this.animate    = false,
    this.animDelay  = Duration.zero,
  });

  final Widget   child;
  final EdgeInsets padding;
  final double   radius;
  final Color?   color;
  final Color?   borderColor;
  final bool     animate;
  final Duration animDelay;

  @override
  State<TraderPanel> createState() => _TraderPanelState();
}

class _TraderPanelState extends State<TraderPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    // spring stiffness:100 damping:15 → easeOut 450ms
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // y:20 → 0  (Offset fraction of widget height, ~0.08 ≈ 20px)
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.animate) {
      Future.delayed(widget.animDelay, () { if (mounted) _ctrl.forward(); });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);

    final box = Container(
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? t.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.borderColor ?? t.border),
        boxShadow: t.cardShadow,
      ),
      child: widget.child,
    );

    if (!widget.animate) return box;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: box),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN TOP BAR
//  RN: initial={{ opacity:0, x:-20 }} animate={{ opacity:1, x:0 }}
//      easeOut 500ms  (DriverHome header pattern)
// ══════════════════════════════════════════════════════════════════════════════
class ScreenTopBar extends StatefulWidget {
  const ScreenTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.animate   = true,
    this.animDelay = Duration.zero,
  });

  final String   title;
  final String   subtitle;
  final Widget?  leading;
  final Widget?  trailing;
  final bool     animate;
  final Duration animDelay;

  @override
  State<ScreenTopBar> createState() => _ScreenTopBarState();
}

class _ScreenTopBarState extends State<ScreenTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // x:-20 → 0
    _slide = Tween<Offset>(begin: const Offset(-0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.animate) {
      Future.delayed(widget.animDelay, () { if (mounted) _ctrl.forward(); });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);

    final row = Row(children: [
      if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 12)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(widget.subtitle,
              style: TextStyle(color: t.textMuted, fontSize: 12)),
        ]),
      ),
      if (widget.trailing != null) widget.trailing!,
    ]);

    if (!widget.animate) return row;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: row),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TRADER ICON BUTTON
//  RN: whileTap={{ scale:0.97 }}  whileHover={{ scale:1.05 }}
// ══════════════════════════════════════════════════════════════════════════════
class TraderIconButton extends StatefulWidget {
  const TraderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.foreground,
  });

  final IconData     icon;
  final VoidCallback? onTap;
  final Color?       background;
  final Color?       foreground;

  @override
  State<TraderIconButton> createState() => _TraderIconButtonState();
}

class _TraderIconButtonState extends State<TraderIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    // whileTap scale:0.97
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);

    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: widget.background ?? t.surfaceDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Icon(widget.icon,
              color: widget.foreground ?? t.textPrimary, size: 18),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS PILL
//  RN: pulsing dot → opacity[1,0.4,1] scale[1,1.2,1] 2s easeInOut infinite
//      (DriverHome StatusChip "In Transit" pattern)
//  Usage: StatusPill(label: 'In Transit', showPulsingDot: true)
// ══════════════════════════════════════════════════════════════════════════════
class StatusPill extends StatefulWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color          = traderAccent,
    this.background,
    this.showPulsingDot = false,
  });

  final String label;
  final Color  color;
  final Color? background;
  final bool   showPulsingDot;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _opacity;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    // 2s easeInOut infinite (reverse = ping-pong)
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.background ?? widget.color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.showPulsingDot) ...[
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: widget.color, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(widget.label,
            style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  METRIC MINI CARD
//  RN: initial={{ scale:0 }} animate spring stiffness:200
//      + counter: number animates 0 → value (DriverHome todayData pattern)
//  Usage: MetricMiniCard(icon:..., label:..., value:'385', numericValue: 385)
// ══════════════════════════════════════════════════════════════════════════════
class MetricMiniCard extends StatefulWidget {
  const MetricMiniCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.numericValue,
    this.animDelay = Duration.zero,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final int?     numericValue; // pass int → counter animates 0→value
  final Duration animDelay;

  @override
  State<MetricMiniCard> createState() => _MetricMiniCardState();
}

class _MetricMiniCardState extends State<MetricMiniCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _fade;
  Animation<int>?                _counter;

  @override
  void initState() {
    super.initState();
    // spring stiffness:200 → elasticOut 600ms
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    if (widget.numericValue != null) {
      _counter = IntTween(begin: 0, end: widget.numericValue!)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    }

    Future.delayed(widget.animDelay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);

    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surfaceDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.border),
            boxShadow: t.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: TraderTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: TraderTheme.accent, size: 16),
            ),
            const SizedBox(height: 12),
            Text(widget.label,
                style: TextStyle(color: t.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            // counter animation if numericValue provided
            _counter != null
                ? AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Text(
                      '${_counter!.value}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                : Text(widget.value,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}