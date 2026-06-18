// ════════════════════════════════════════════════════════════
//  driver_otp_screen7.dart  — Verification Successful
//  مفيش API هنا — الـ screen دي confirmation فقط
//  بعد reset password ناجح → Continue → /login
// ════════════════════════════════════════════════════════════
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/auth/login_screen.dart';

class DriverOTPScreen7 extends StatefulWidget {
  const DriverOTPScreen7({super.key});

  @override
  State<DriverOTPScreen7> createState() => _DriverOTPScreen7State();
}

class _DriverOTPScreen7State extends State<DriverOTPScreen7>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _checkCtrl;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _checkDraw;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _rotateGlow;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();

    _cardFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.05, 0.5, curve: Curves.elasticOut)));

    _titleFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.35, 0.7, curve: Curves.easeOut)));

    _subFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.45, 0.78, curve: Curves.easeOut));
    _subSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.45, 0.78, curve: Curves.easeOut)));

    _btnFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkDraw = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _checkCtrl.forward();
    });

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _rotateGlow = Tween<double>(begin: 0, end: 1).animate(_rotateCtrl);

    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    _rotateCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.isDark ? const Color(0xFF0A1628) : const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 23),
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  width: 335, height: 635,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0xFF192C3D) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: const Color(0xFF00D5BE).withOpacity(0.2), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF14B8A6).withOpacity(0.08),
                          blurRadius: 32, offset: const Offset(0, 8)),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 60, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: Stack(children: [
                    ..._buildCornerDots(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Success Icon ──
                        ScaleTransition(
                          scale: _iconScale,
                          child: SizedBox(
                            width: 110, height: 110,
                            child: Stack(alignment: Alignment.center, children: [
                              AnimatedBuilder(
                                animation: _rotateCtrl,
                                builder: (_, __) => Transform.rotate(
                                  angle: _rotateGlow.value * 2 * pi,
                                  child: Container(
                                    width: 110, height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF00D5BE).withOpacity(0.2),
                                          width: 1),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _rotateCtrl,
                                builder: (_, __) => Transform.rotate(
                                  angle: -_rotateGlow.value * 2 * pi * 0.6,
                                  child: Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFFF8904).withOpacity(0.12),
                                          width: 1),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, __) => Transform.scale(
                                  scale: _pulseAnim.value,
                                  child: Container(
                                    width: 78, height: 78,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: t.isDark ? const Color(0xFF0D2035) : Colors.white,
                                      border: Border.all(
                                          color: const Color(0xFF00D5BE).withOpacity(0.5),
                                          width: 1.2),
                                      boxShadow: [BoxShadow(
                                        color: const Color(0xFF00D5BE).withOpacity(
                                            0.15 + 0.2 * (_pulseAnim.value - 0.9) / 0.2),
                                        blurRadius: 22, spreadRadius: 3,
                                      )],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _checkDraw,
                                builder: (_, __) => Opacity(
                                  opacity: _checkDraw.value,
                                  child: Transform.scale(
                                    scale: 0.6 + 0.4 * _checkDraw.value,
                                    child: const Icon(Icons.check_circle_outline,
                                        color: Color(0xFF00D5BE), size: 42),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 40),

                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              'Verification Successful',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: t.textPrimary, fontSize: 24,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.3),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        FadeTransition(
                          opacity: _subFade,
                          child: SlideTransition(
                            position: _subSlide,
                            child: Text(
                              'Your new password has been confirmed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: t.textMuted, fontSize: 13.5, height: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 55),

                        // Continue → Login
                        FadeTransition(
                          opacity: _btnFade,
                          child: SlideTransition(
                            position: _btnSlide,
                            child: _PressableButton(
                              label: 'Continue',
                              onTap: _goToLogin,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Back to Login
                        FadeTransition(
                          opacity: _btnFade,
                          child: SlideTransition(
                            position: _btnSlide,
                            child: _SecondaryButton(
                              label: 'Back to Login',
                              onTap: _goToLogin,
                            ),
                          ),
                        ),
                      ],
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

  List<Widget> _buildCornerDots() {
    final positions = [
      {'top': 0.0, 'left': 0.0},
      {'top': 0.0, 'left': 14.0},
      {'top': 0.0, 'right': 0.0},
      {'top': 0.0, 'right': 14.0},
      {'bottom': 0.0, 'left': 0.0},
      {'bottom': 0.0, 'left': 14.0},
      {'bottom': 0.0, 'right': 0.0},
      {'bottom': 0.0, 'right': 14.0},
    ];
    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      final color = i % 3 == 0 ? const Color(0xFFFF8904) : const Color(0xFF00D5BE);
      return Positioned(
        top: pos['top'], bottom: pos['bottom'],
        left: pos['left'], right: pos['right'],
        child: AnimatedBuilder(
          animation: _dotsCtrl,
          builder: (_, __) {
            final t = (_dotsCtrl.value + i * 0.15) % 1.0;
            final opacity = 0.25 + 0.55 * sin(t * pi);
            final scale = 0.7 + 0.5 * sin(t * pi);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(opacity * 0.5), blurRadius: 5)],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}

// ── Primary button ──
class _PressableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PressableButton({required this.label, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF17D4B4), Color(0xFF0E8FD4)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.3),
              blurRadius: 14, offset: const Offset(0, 5),
            )],
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ── Secondary button ──
class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 15)),
        ),
      ),
    );
  }
}