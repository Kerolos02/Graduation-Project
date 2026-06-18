import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screen/trader/Trader_registration_screen.dart';
import '/screen/auth/Registration_Screen.dart';
import '/screen/auth/login_screen.dart';
import '/providers/theme_provider.dart';

class SelectRole extends StatefulWidget {
  const SelectRole({super.key});
  @override
  State<SelectRole> createState() => _SelectRoleState();
}

class _SelectRoleState extends State<SelectRole>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _anims = List.generate(6, (i) {
      final start = (i * 0.12).clamp(0.0, 0.7);
      final end   = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _fade(int i, Widget child) {
    final a = _anims[i.clamp(0, _anims.length - 1)];
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) => Opacity(
        opacity: a.value,
        child: Transform.translate(
            offset: Offset(0, 28 * (1 - a.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.selectBg,
      body: Stack(
        children: [
          _BreathingGlow(isDark: t.isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  _fade(0, Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Current Shipment Status',
                        style: TextStyle(
                            color: t.textMuted, fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(height: 16),

                  _fade(1, _MapCard(theme: t)),
                  const SizedBox(height: 20),

                  _fade(2, _AnimatedShipmentPath(theme: t)),
                  const SizedBox(height: 24),

                  _fade(3, Column(children: [
                    Text(
                      'Your Shipment Is\nOne Driver Away',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold,
                          color: t.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text('Connect. Match. Move.',
                        style: TextStyle(
                            color: t.textMuted, fontSize: 15,
                            letterSpacing: 0.4)),
                  ])),
                  const SizedBox(height: 36),

                  _fade(4, Column(children: [
                    _RoleButton(
                      text: 'Join as Driver', filled: true,
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegistrationScreen())),
                    ),
                    const SizedBox(height: 14),
                    _RoleButton(
                      text: 'Join as Trader', filled: false,
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const TraderRegistrationScreen())),
                      theme: t,
                    ),
                  ])),
                  const SizedBox(height: 20),

                  _fade(5, Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: TextStyle(color: t.textMuted)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: const Text('Log in',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breathing Glow ──
class _BreathingGlow extends StatefulWidget {
  final bool isDark;
  const _BreathingGlow({required this.isDark});
  @override
  State<_BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<_BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 0.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        bottom: -100,
        left: MediaQuery.of(context).size.width / 2 - 200,
        child: Opacity(
          opacity: _anim.value * (widget.isDark ? 1.0 : 0.4),
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primary.withOpacity(0.18),
                AppTheme.primary.withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Map Card ──
class _MapCard extends StatefulWidget {
  final AppTheme theme;
  const _MapCard({required this.theme});
  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.55).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        height: 190, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.primary.withOpacity(_anim.value), width: 1.5),
          color: t.mapCard,
          boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(_anim.value * 0.3),
            blurRadius: 20, spreadRadius: 1)],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          const Positioned.fill(child: _RotatingRings()),
          const Center(child: _FloatingPackage()),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.primary.withOpacity(0.07)
      ..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 30)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 30)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _RotatingRings extends StatefulWidget {
  const _RotatingRings();
  @override
  State<_RotatingRings> createState() => _RotatingRingsState();
}

class _RotatingRingsState extends State<_RotatingRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
          painter: _RingsPainter(_ctrl.value * 2 * pi)));
  }
}

class _RingsPainter extends CustomPainter {
  final double angle;
  _RingsPainter(this.angle);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final r in [45.0, 65.0, 80.0]) {
      p.color = AppTheme.primary.withOpacity(0.15);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle * (r / 80));
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.55), p);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_RingsPainter o) => o.angle != angle;
}

class _FloatingPackage extends StatefulWidget {
  const _FloatingPackage();
  @override
  State<_FloatingPackage> createState() => _FloatingPackageState();
}

class _FloatingPackageState extends State<_FloatingPackage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float, _glow;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withOpacity(0.12),
            boxShadow: [BoxShadow(
              color: AppTheme.primary.withOpacity(_glow.value * 0.5),
              blurRadius: 24, spreadRadius: 4)],
          ),
          child: Icon(Icons.inventory_2_outlined,
              color: AppTheme.primary.withOpacity(0.9), size: 34),
        ),
      ),
    );
  }
}

// ── Animated Shipment Path ──
class _AnimatedShipmentPath extends StatefulWidget {
  final AppTheme theme;
  const _AnimatedShipmentPath({required this.theme});
  @override
  State<_AnimatedShipmentPath> createState() => _AnimatedShipmentPathState();
}

class _AnimatedShipmentPathState extends State<_AnimatedShipmentPath>
    with TickerProviderStateMixin {
  late final AnimationController _pathCtrl, _truckCtrl, _glowCtrl;
  late final Animation<double> _pathAnim, _truckAnim, _glowAnim, _floatAnim;

  @override
  void initState() {
    super.initState();
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    _pathAnim = CurvedAnimation(parent: _pathCtrl, curve: Curves.easeOut);
    _truckCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _truckAnim = CurvedAnimation(parent: _truckCtrl, curve: Curves.linear);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pathCtrl.dispose(); _truckCtrl.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  Offset _pointOnCurve(double t) {
    const p0 = Offset(40, 90), p1 = Offset(120, 100),
          p2 = Offset(150, 20), p3 = Offset(260, 30);
    final u = 1 - t;
    return Offset(
      u*u*u*p0.dx + 3*u*u*t*p1.dx + 3*u*t*t*p2.dx + t*t*t*p3.dx,
      u*u*u*p0.dy + 3*u*u*t*p1.dy + 3*u*t*t*p2.dy + t*t*t*p3.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pathAnim, _truckAnim, _glowAnim]),
        builder: (_, __) {
          final truckPos = _pointOnCurve(_truckAnim.value);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: CustomPaint(
                painter: _CurvePainter(_pathAnim.value))),
            Positioned(left: 18, top: 72,
              child: Transform.translate(
                offset: Offset(0, _floatAnim.value * 0.6),
                child: Icon(Icons.inventory_2_outlined,
                    color: AppTheme.primary, size: 34))),
            Positioned(right: 18, top: 14,
              child: Transform.translate(
                offset: Offset(0, _floatAnim.value * -0.6),
                child: Icon(Icons.local_shipping,
                    color: AppTheme.primary, size: 38))),
            Positioned(
              left: truckPos.dx - 10, top: truckPos.dy - 10,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.primary,
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.7),
                    blurRadius: 14, spreadRadius: 2)]),
                child: const Icon(Icons.local_shipping,
                    color: Colors.white, size: 12))),
          ]);
        },
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final double progress;
  _CurvePainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 300;
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 ..strokeCap = StrokeCap.round;
    final fullPath = Path()
      ..moveTo(40 * scaleX, 90)
      ..cubicTo(120*scaleX, 100, 150*scaleX, 20, 260*scaleX, 30);
    final metrics = fullPath.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);
    bool drawing = true; double dist = 0;
    for (final m in drawn.computeMetrics()) {
      while (dist < m.length) {
        final len = drawing ? 8.0 : 6.0;
        if (drawing) canvas.drawPath(
            m.extractPath(dist, (dist+len).clamp(0, m.length)), paint);
        dist += len; drawing = !drawing;
      }
    }
  }
  @override bool shouldRepaint(_CurvePainter o) => o.progress != progress;
}

// ── Role Button ──
class _RoleButton extends StatefulWidget {
  final String text;
  final bool filled;
  final VoidCallback onPressed;
  final AppTheme? theme;
  const _RoleButton({
    required this.text, required this.filled,
    required this.onPressed, this.theme});
  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimCtrl;
  bool _pressed = false;
  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }
  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.filled ? _buildFilled() : _buildOutlined(),
      ),
    );
  }

  Widget _buildFilled() => AnimatedBuilder(
    animation: _shimCtrl,
    builder: (_, __) => Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [Color(0xFF009689), Color(0xFF00BBA7), AppTheme.primary]),
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(_pressed ? 0.5 : 0.3),
          blurRadius: 18, offset: const Offset(0, 6))]),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        Positioned.fill(child: Transform.translate(
          offset: Offset((_shimCtrl.value * 2 - 0.5) * 400, 0),
          child: Container(decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0)]))))),
        Center(child: Text(widget.text,
            style: const TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.bold))),
      ]),
    ),
  );

  Widget _buildOutlined() {
    final t = widget.theme;
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        border: Border.all(
          color: t != null
              ? (t.isDark ? AppTheme.primary.withOpacity(0.35) : t.border)
              : AppTheme.primary.withOpacity(0.35),
          width: 1.5)),
      child: Center(child: Text(widget.text,
          style: TextStyle(
            color: t?.textPrimary ?? Colors.white,
            fontSize: 17, fontWeight: FontWeight.w500))),
    );
  }
}