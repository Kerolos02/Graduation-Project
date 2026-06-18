import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/auth_service.dart'; // ← للـ logout endpoint

// ══════════════════════════════════════════════════════════════════
//  DRIVER STATE SCREENS — animations مطابقة لـ React Native تماماً
//  lib/screen/driver/driver_state_screens.dart
//
//  BACKEND INTEGRATION:
//  • Empty / Error / Loading → states تتعرض من الـ parent screen
//    بناءً على نتيجة الـ API — مش بتعمل calls بنفسها
//  • Logout Dialog → POST /api/auth/logout  (Authorized)
//    بيعمل الـ call الحقيقي وبعدين يروح لـ /login
// ══════════════════════════════════════════════════════════════════

// ─── Colors ──────────────────────────────────────────────────────
const Color _kTeal  = Color(0xFF00D5BE);
const Color _kTeal2 = Color(0xFF00BBA7);
const Color _kRed   = Color(0xFFD32F2F);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kBg    = Color(0xFF0F2334);
const Color _kCard  = Color(0xFF0A1628);

const LinearGradient _kGrad = LinearGradient(
  colors: [_kTeal, _kTeal2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ─── Gradient Button with shimmer sweep ──────────────────────────
class _GradButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_GradButton> createState() => _GradButtonState();
}

class _GradButtonState extends State<_GradButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _kGrad,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: _kTeal.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: _shimmerX,
            builder: (_, __) => Transform.translate(
              offset: Offset(_shimmerX.value, 0),
              child: Container(
                width: 120, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0),
                  ]),
                ),
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _SpinningIcon(icon: widget.icon),
            const SizedBox(width: 8),
            Text(widget.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ]),
        ]),
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  const _SpinningIcon({required this.icon});
  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _ctrl,
    child: Icon(widget.icon, color: Colors.white, size: 20),
  );
}

// ── Floating Background Blobs ──
class _FloatingBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Alignment alignment;
  final Offset animateOffset;
  final Duration duration;
  final Duration delay;
  const _FloatingBlob({
    required this.color, required this.size, required this.alignment,
    required this.animateOffset, required this.duration, this.delay = Duration.zero,
  });
  @override
  State<_FloatingBlob> createState() => _FloatingBlobState();
}

class _FloatingBlobState extends State<_FloatingBlob> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _offset;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _offset = Tween<Offset>(begin: Offset.zero, end: widget.animateOffset)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Align(
    alignment: widget.alignment,
    child: AnimatedBuilder(
      animation: _offset,
      builder: (_, child) => Transform.translate(
        offset: Offset(_offset.value.dx * widget.size, _offset.value.dy * widget.size),
        child: child,
      ),
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.05)),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.05), blurRadius: 80, spreadRadius: 40)],
        ),
      ),
    ),
  );
}

// ── Pulse Ring ──
class _PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final double targetScale;
  final Duration delay;
  final Duration duration;
  const _PulseRing({
    required this.size, required this.color, required this.targetScale,
    this.delay = Duration.zero, this.duration = const Duration(milliseconds: 2000),
  });
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale   = Tween<double>(begin: 1.0, end: widget.targetScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.4, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.repeat(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Transform.scale(
      scale: _scale.value,
      child: Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color, width: 2)),
        ),
      ),
    ),
  );
}

// ── Bouncing + Rotating Icon ──
class _BouncingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BouncingIcon({required this.icon, required this.color});
  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _rotate;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _rotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0),  weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, child) => Transform.scale(
      scale: _scale.value,
      child: Transform.rotate(angle: _rotate.value * 3.14159 / 180, child: child),
    ),
    child: Icon(widget.icon, color: widget.color, size: 40),
  );
}

// ── Badge Spring Pop ──
class _BadgePop extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _BadgePop({required this.child, this.delay = Duration.zero});
  @override
  State<_BadgePop> createState() => _BadgePopState();
}

class _BadgePopState extends State<_BadgePop> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

// ── Shake Icon ──
class _ShakeIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _ShakeIcon({required this.icon, required this.color});
  @override
  State<_ShakeIcon> createState() => _ShakeIconState();
}

class _ShakeIconState extends State<_ShakeIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotate;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _rotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0),  weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0),  weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _rotate,
    builder: (_, child) => Transform.rotate(angle: _rotate.value * 3.14159 / 180, child: child),
    child: Icon(widget.icon, color: widget.color, size: 48),
  );
}

// ── Pulsing Dot ──
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity, _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale   = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Transform.scale(
      scale: _scale.value,
      child: Opacity(opacity: _opacity.value,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color))),
    ),
  );
}

// ── Spring Entry ──
class _SpringEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset slideFrom;
  const _SpringEntry({required this.child, this.delay = Duration.zero, this.slideFrom = Offset.zero});
  @override
  State<_SpringEntry> createState() => _SpringEntryState();
}

class _SpringEntryState extends State<_SpringEntry> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.slideFrom, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: ScaleTransition(scale: _scale, child: widget.child)),
  );
}

// ── Fade Slide Entry ──
class _FadeSlideEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeSlideEntry({required this.child, this.delay = Duration.zero});
  @override
  State<_FadeSlideEntry> createState() => _FadeSlideEntryState();
}

class _FadeSlideEntryState extends State<_FadeSlideEntry> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade, child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ══════════════════════════════════════════════════════════════════
//  1. REQUESTS LIST EMPTY
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListEmptyScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  const DriverRequestsListEmptyScreen({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        const Positioned.fill(child: IgnorePointer(child: Stack(children: [
          _FloatingBlob(color: _kTeal,  size: 256, alignment: Alignment(0.8, -0.6),
              animateOffset: Offset(0.12, -0.08), duration: Duration(milliseconds: 8000)),
          _FloatingBlob(color: _kAmber, size: 192, alignment: Alignment(-0.8, 0.7),
              animateOffset: Offset(-0.1, 0.15),  duration: Duration(milliseconds: 10000),
              delay: Duration(milliseconds: 1000)),
        ]))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            _SpringEntry(delay: const Duration(milliseconds: 200),
              child: SizedBox(width: 96, height: 96,
                child: Stack(alignment: Alignment.center, children: [
                  const _PulseRing(size: 96, color: _kTeal, targetScale: 1.6, duration: Duration(milliseconds: 2000)),
                  const _PulseRing(size: 96, color: _kTeal, targetScale: 1.3, delay: Duration(milliseconds: 400), duration: Duration(milliseconds: 2000)),
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [_kTeal.withOpacity(0.15), _kTeal.withOpacity(0.08)]),
                      border: Border.all(color: _kTeal.withOpacity(0.3), width: 1.5),
                    ),
                    child: const _BouncingIcon(icon: Icons.inbox_outlined, color: _kTeal),
                  ),
                  Positioned(bottom: -2, right: -2,
                    child: _BadgePop(delay: const Duration(milliseconds: 300),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF34C759).withOpacity(0.2),
                          border: Border.all(color: const Color(0xFF34C759), width: 2),
                        ),
                        child: const Icon(Icons.wifi_tethering, color: Color(0xFF34C759), size: 14),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideEntry(delay: const Duration(milliseconds: 300),
              child: const Text('No Requests Available', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            _FadeSlideEntry(delay: const Duration(milliseconds: 400),
              child: Text('Stay online to receive new shipment requests', textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.6), fontSize: 15, height: 1.5))),
            const SizedBox(height: 32),
            _FadeSlideEntry(delay: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.6), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kTeal.withOpacity(0.15), width: 1),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF34C759).withOpacity(0.15)),
                      child: const Icon(Icons.wifi_tethering, color: Color(0xFF34C759), size: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("You're Online & Ready",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('New shipment requests will appear here automatically',
                        style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.6), fontSize: 12, height: 1.4)),
                  ])),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            _FadeSlideEntry(delay: const Duration(milliseconds: 600),
              child: _GradButton(
                label: 'Refresh', icon: Icons.refresh_rounded,
                onTap: onRefresh ?? () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  2. REQUESTS LIST ERROR
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const DriverRequestsListErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        Positioned.fill(child: IgnorePointer(child: Stack(children: [
          _FloatingBlob(color: const Color(0xFF8E8E93), size: 256, alignment: const Alignment(0.8, -0.6),
              animateOffset: const Offset(0.12, -0.08), duration: const Duration(milliseconds: 8000)),
          _FloatingBlob(color: _kRed, size: 192, alignment: const Alignment(-0.8, 0.7),
              animateOffset: const Offset(-0.1, 0.15), duration: const Duration(milliseconds: 10000),
              delay: const Duration(milliseconds: 1000)),
        ]))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            _SpringEntry(delay: const Duration(milliseconds: 200),
              child: SizedBox(width: 96, height: 96,
                child: Stack(alignment: Alignment.center, children: [
                  const _PulseRing(size: 96, color: _kRed, targetScale: 1.4, duration: Duration(milliseconds: 2000)),
                  const _PulseRing(size: 96, color: _kRed, targetScale: 1.4, delay: Duration(milliseconds: 500), duration: Duration(milliseconds: 2000)),
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [_kRed.withOpacity(0.20), const Color(0xFF8E8E93).withOpacity(0.15)]),
                      border: Border.all(color: _kRed.withOpacity(0.3), width: 1.5),
                    ),
                    child: const _ShakeIcon(icon: Icons.error_outline_rounded, color: _kRed),
                  ),
                  Positioned(bottom: -2, right: -2,
                    child: _BadgePop(delay: const Duration(milliseconds: 600),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8E8E93).withOpacity(0.2),
                          border: Border.all(color: const Color(0xFF8E8E93), width: 2),
                        ),
                        child: const Icon(Icons.wifi_off_rounded, color: Color(0xFF8E8E93), size: 16),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideEntry(delay: const Duration(milliseconds: 300),
              child: const Text('Failed to Load Requests', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            _FadeSlideEntry(delay: const Duration(milliseconds: 400),
              child: Text('Please check your connection and try again', textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.6), fontSize: 15, height: 1.5))),
            const SizedBox(height: 32),
            _FadeSlideEntry(delay: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.6), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8E8E93).withOpacity(0.2), width: 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Troubleshooting:',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...['Check your internet connection', 'Ensure you have a stable network signal', 'Try again in a few moments']
                      .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 6),
                          child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kRed))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.6), fontSize: 13, height: 1.4))),
                    ]),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideEntry(delay: const Duration(milliseconds: 600),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const _PulseDot(color: _kRed),
                const SizedBox(width: 8),
                Text('Connection error', style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.5), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            _FadeSlideEntry(delay: const Duration(milliseconds: 700),
              child: _GradButton(
                label: 'Retry', icon: Icons.refresh_rounded,
                onTap: onRetry ?? () => Navigator.pushReplacementNamed(context, '/driver_requests'),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  3. REQUESTS LIST LOADING
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListLoadingScreen extends StatefulWidget {
  const DriverRequestsListLoadingScreen({super.key});
  @override
  State<DriverRequestsListLoadingScreen> createState() => _RequestsListLoadingState();
}

class _RequestsListLoadingState extends State<DriverRequestsListLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  Widget _sk(double h, double w, {double r = 8}) => Container(
    width: w == -1 ? double.infinity : w,
    height: h,
    decoration: BoxDecoration(color: _kTeal.withOpacity(0.10), borderRadius: BorderRadius.circular(r)),
  );

  Widget _skCard(int index) {
    return _FadeSlideEntry(
      delay: Duration(milliseconds: 400 + index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_kCard.withOpacity(0.8), const Color(0xFF0F2334).withOpacity(0.6)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kTeal.withOpacity(0.15), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          AnimatedBuilder(
            animation: _shimmerX,
            builder: (_, __) {
              final delay = index * 0.2;
              final raw = (_shimmerX.value / 600 + delay) % 1.0;
              final x = (raw * 600) - 300;
              return Transform.translate(
                offset: Offset(x, 0),
                child: Container(width: 120, height: 200,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [
                      Colors.transparent, _kTeal.withOpacity(0.08), Colors.transparent,
                    ]))),
              );
            },
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 40, color: _kAmber.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _kTeal.withOpacity(0.2))),
                    const SizedBox(height: 4),
                    Container(width: 2, height: 24, color: _kTeal.withOpacity(0.15)),
                    const SizedBox(height: 4),
                    Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: _kAmber.withOpacity(0.2))),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sk(12, 64, r: 6), const SizedBox(height: 4),
                    _sk(16, -1, r: 6), const SizedBox(height: 16),
                    _sk(12, 64, r: 6), const SizedBox(height: 4),
                    _sk(16, -1, r: 6),
                  ])),
                ]),
                const SizedBox(height: 16),
                Row(children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _kTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sk(10, 48, r: 4), const SizedBox(height: 4), _sk(14, -1, r: 4),
                    ]),
                  ),
                ))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Container(height: 40, decoration: BoxDecoration(color: _kTeal.withOpacity(0.10), borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 40, decoration: BoxDecoration(color: _kTeal.withOpacity(0.20), borderRadius: BorderRadius.circular(8)))),
                ]),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        const Positioned.fill(child: IgnorePointer(child: Stack(children: [
          _FloatingBlob(color: _kTeal,  size: 256, alignment: Alignment(0.8, -0.6),
              animateOffset: Offset(0.12, -0.08), duration: Duration(milliseconds: 8000)),
          _FloatingBlob(color: _kAmber, size: 192, alignment: Alignment(-0.6, 0.5),
              animateOffset: Offset(-0.1, 0.15), duration: Duration(milliseconds: 10000),
              delay: Duration(milliseconds: 1000)),
        ]))),
        SafeArea(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _FadeSlideEntry(delay: Duration.zero,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sk(28, 100, r: 8), const SizedBox(height: 8), _sk(16, 192, r: 6),
              ]),
            ),
            const SizedBox(height: 20),
            _FadeSlideEntry(delay: const Duration(milliseconds: 200),
              child: Row(children: [
                Expanded(child: Container(height: 44, decoration: BoxDecoration(gradient: _kGrad, borderRadius: BorderRadius.circular(12)))),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 44, decoration: BoxDecoration(color: _kTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)))),
              ]),
            ),
            const SizedBox(height: 20),
            _FadeSlideEntry(delay: const Duration(milliseconds: 300), child: _LoadingText()),
            const SizedBox(height: 8),
            ...[0, 1, 2].map((i) => _skCard(i)),
            const SizedBox(height: 16),
            _FadeSlideEntry(delay: const Duration(milliseconds: 600),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _LoadingDot(delay: i * 200))),
            ),
            const SizedBox(height: 32),
          ],
        )),
      ]),
    );
  }
}

class _LoadingText extends StatefulWidget {
  @override
  State<_LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<_LoadingText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
    child: Center(child: Text('Loading requests...',
        style: TextStyle(color: const Color(0xFFCBFBF1).withOpacity(0.6), fontSize: 13))),
  );
}

class _LoadingDot extends StatefulWidget {
  final int delay;
  const _LoadingDot({required this.delay});
  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scale   = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.repeat(reverse: true); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(scale: _scale.value,
        child: Opacity(opacity: _opacity.value,
          child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kTeal)))),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  aliases للـ screens القديمة
// ══════════════════════════════════════════════════════════════════
class DriverEarningsEmptyScreen  extends StatelessWidget {
  const DriverEarningsEmptyScreen({super.key});
  @override Widget build(BuildContext context) => DriverRequestsListEmptyScreen(onRefresh: () => Navigator.pop(context));
}
class DriverEarningsErrorScreen  extends StatelessWidget {
  const DriverEarningsErrorScreen({super.key});
  @override Widget build(BuildContext context) => DriverRequestsListErrorScreen(onRetry: () => Navigator.pushReplacementNamed(context, '/driver_earnings'));
}
class DriverEarningsLoadingScreen extends StatelessWidget {
  const DriverEarningsLoadingScreen({super.key});
  @override Widget build(BuildContext context) => const DriverRequestsListLoadingScreen();
}
class DriverAlertsEmptyScreen  extends StatelessWidget {
  const DriverAlertsEmptyScreen({super.key});
  @override Widget build(BuildContext context) => DriverRequestsListEmptyScreen(onRefresh: () => Navigator.pop(context));
}
class DriverAlertsErrorScreen  extends StatelessWidget {
  const DriverAlertsErrorScreen({super.key});
  @override Widget build(BuildContext context) => DriverRequestsListErrorScreen(onRetry: () => Navigator.pushReplacementNamed(context, '/driver_notifications'));
}
class DriverAlertsLoadingScreen extends StatelessWidget {
  const DriverAlertsLoadingScreen({super.key});
  @override Widget build(BuildContext context) => const DriverRequestsListLoadingScreen();
}

// ══════════════════════════════════════════════════════════════════
//  LOGOUT DIALOG — POST /api/auth/logout  (Authorized)
// ══════════════════════════════════════════════════════════════════
const Color _kRedLight = Color(0xFFEF4444);

class DriverLogoutDialog extends StatefulWidget {
  const DriverLogoutDialog({super.key});

  /// استخدم الـ method دي عشان تفتح الـ dialog
  /// بيرجع true لو المستخدم اتلوق أوت فعلاً
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const DriverLogoutDialog(),
  );

  @override
  State<DriverLogoutDialog> createState() => _DriverLogoutDialogState();
}

class _DriverLogoutDialogState extends State<DriverLogoutDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  // ── State للـ loading أثناء الـ API call ──
  bool _isLoggingOut = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ══════════════════════════════════════════════════════
  //  LOGOUT — POST /api/auth/logout
  //  بيعمل الـ API call وبعدين يمسح التوكن ويروح لـ /login
  // ══════════════════════════════════════════════════════
  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // POST /api/auth/logout  — الـ AuthService بيضيف الـ JWT تلقائياً
      await _authService.logout();
    } catch (_) {
      // حتى لو الـ API فشل، بنكمل اللوجاوت locally
    }

    if (!mounted) return;

    // إغلاق الـ dialog وبعدين نروح لـ login
    Navigator.of(context).pop(true);

    // مسح كل الـ routes والروحة لـ /login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final d    = context.watch<ThemeProvider>().isDark;
    final kCard = d ? const Color(0xFF162535) : Colors.white;
    final kDeep = d ? const Color(0xFF1C2F42) : const Color(0xFFF0F5FA);
    final kText = d ? Colors.white : const Color(0xFF0D1B2A);
    final kSub  = d ? Colors.white60 : Colors.black45;
    final kBdr  = d ? Colors.white12 : const Color(0xFFE0E8F0);

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBdr),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d ? const Color(0xFF2A0A0A) : const Color(0xFFFEEEEE),
                  boxShadow: [BoxShadow(color: _kRedLight.withOpacity(0.2), blurRadius: 24, spreadRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kRedLight, width: 2.5)),
                  alignment: Alignment.center,
                  child: const Text('!', style: TextStyle(color: _kRedLight, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Logout', style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Are you sure you want to log out?',
                  textAlign: TextAlign.center, style: TextStyle(color: kSub, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kDeep, borderRadius: BorderRadius.circular(14)),
                child: Text("You'll need to sign in again to access your account",
                    textAlign: TextAlign.center, style: TextStyle(color: kSub, fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 20),
              Row(children: [
                // Cancel
                Expanded(child: GestureDetector(
                  onTap: _isLoggingOut ? null : () => Navigator.pop(context, false),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _kTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kTeal.withOpacity(0.4)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.close, color: _kTeal, size: 16),
                      SizedBox(width: 6),
                      Text('Cancel', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                  ),
                )),
                const SizedBox(width: 12),
                // Logout — بيعمل API call
                Expanded(child: GestureDetector(
                  onTap: _isLoggingOut ? null : _handleLogout,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _kRedLight, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _kRedLight.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    // لو بيعمل API call بيعرض loading indicator
                    child: _isLoggingOut
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}