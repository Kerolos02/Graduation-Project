// ✅ splash_screen.dart — FIXED
// المشكلة كانت: isLoggedIn بيفضل محفوظ في SharedPreferences حتى لو
// ماعملتش logout صريح، فبيودي للـ DriverHome مباشرة.
// الحل: لو مفيش role محفوظ أو الداتا ناقصة، نعمل reset للـ session.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'screen/auth/select_role.dart';
import 'screen/driver/driver_home_screen.dart';
import 'screen/trader/trader_home_screen.dart';

const Color kTruck = Color(0xFF3DA5FF);
const Color kMate  = Color(0xFF2DD4BF);
const Color kBg1   = Color(0xFF0F2334);
const Color kBg2   = Color(0xFF182C3C);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _drawCtrl;
  late Animation<double>   _drawVal;
  late AnimationController _cabinCtrl;
  late Animation<double>   _cabinVal;
  late AnimationController _roadLineCtrl;
  late Animation<double>   _roadLineScale;
  late Animation<double>   _roadLineOpacity;
  late AnimationController _wheelShowCtrl;
  late Animation<double>   _wheelShowVal;
  late AnimationController _wheelSpinCtrl;
  late AnimationController _speedCtrl;
  late Animation<double>   _speedVal;
  bool _showSparks = false;
  List<_SparkParticle> _sparks = [];
  late AnimationController _textCtrl;
  late Animation<double>   _textOpacity;
  late Animation<double>   _textY;
  late AnimationController _glowCtrl;
  late Animation<double>   _glowVal;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _drawCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _drawVal = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _drawCtrl, curve: Curves.easeInOut));

    _cabinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _cabinVal = Tween<double>(begin: 0.0, end: 1.0).animate(_cabinCtrl);

    _roadLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _roadLineScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _roadLineCtrl, curve: Curves.easeOut));
    _roadLineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _roadLineCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    _wheelShowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _wheelShowVal = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _wheelShowCtrl, curve: Curves.easeOut));

    _wheelSpinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _speedCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _speedVal = Tween<double>(begin: 0.0, end: 1.0).animate(_speedCtrl);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glowVal = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textY = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    _drawCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    _cabinCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _roadLineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _wheelShowCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _wheelSpinCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _speedCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _triggerSparks();
    await Future.delayed(const Duration(milliseconds: 200));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // ✅ FIX: نجيب الـ prefs ونتحقق من صحة الـ session
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn        = prefs.getBool('isLoggedIn') ?? false;
    final role              = prefs.getString('role') ?? '';
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    Widget next;

    // ✅ FIX: لو isLoggedIn لكن مفيش role محفوظ = session corrupted
    // نعمل reset ونودي للـ login
    if (isLoggedIn && role.isEmpty) {
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('role');
      next = const SelectRole();
    } else if (isLoggedIn && role == 'driver') {
      next = const DriverHomeScreen();
    } else if (isLoggedIn && role == 'trader') {
      next = const TraderHomeScreen();
    } else if (hasSeenOnboarding) {
      next = const SelectRole();
    } else {
      next = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => next,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _triggerSparks() {
    final rng = math.Random();
    setState(() {
      _showSparks = true;
      _sparks = List.generate(5, (i) => _SparkParticle(
        angle: i * math.pi / 2.5,
        distance: 20 + rng.nextDouble() * 10,
      ));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSparks = false);
    });
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
    _cabinCtrl.dispose();
    _roadLineCtrl.dispose();
    _wheelShowCtrl.dispose();
    _wheelSpinCtrl.dispose();
    _speedCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    const svgW = 280.0;
    const svgH = 160.0;
    final scale = (w * 0.78) / svgW;
    final truckW = svgW * scale;
    final truckH = svgH * scale;

    return Scaffold(
      body: Container(
        width: w, height: h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBg1, kBg2],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _drawCtrl, _cabinCtrl, _roadLineCtrl,
            _wheelShowCtrl, _wheelSpinCtrl,
            _speedCtrl, _glowCtrl, _textCtrl,
          ]),
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: h * 0.30,
                  left: (w - truckW) / 2,
                  child: SizedBox(
                    width: truckW,
                    height: truckH + 40 * scale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Road line
                        Positioned(
                          bottom: 30 * scale,
                          left: 0, right: 0,
                          child: Transform.scale(
                            scaleX: _roadLineScale.value,
                            child: Opacity(
                              opacity: _roadLineOpacity.value,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    kTruck.withOpacity(0.85),
                                    Colors.transparent,
                                  ]),
                                  boxShadow: [BoxShadow(
                                    color: kTruck.withOpacity(0.5 * _glowVal.value),
                                    blurRadius: 12, spreadRadius: 2,
                                  )],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Wheel glows
                        Positioned(
                          bottom: 20 * scale, left: 100 * scale - 16,
                          child: Opacity(
                            opacity: _wheelShowVal.value * _glowVal.value * 0.7,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  kMate.withOpacity(0.6), Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20 * scale, left: 200 * scale - 16,
                          child: Opacity(
                            opacity: _wheelShowVal.value * _glowVal.value * 0.7,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  kMate.withOpacity(0.6), Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                        ),
                        // Speed lines
                        Positioned(
                          top: truckH * 0.4, left: -10,
                          child: Opacity(
                            opacity: _speedVal.value > 0.7
                                ? (1.0 - _speedVal.value) * 3.3
                                : _speedVal.value / 0.7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(4, (i) {
                                final lineW = (60 - i * 10) * scale;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Transform.translate(
                                    offset: Offset(-30 * (1 - _speedVal.value), 0),
                                    child: Container(
                                      width: lineW, height: 1.5,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: LinearGradient(colors: [
                                          Colors.transparent,
                                          kMate.withOpacity(0.6),
                                        ]),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        // Truck SVG
                        Positioned(
                          top: 0, left: 0,
                          child: CustomPaint(
                            size: Size(truckW, truckH),
                            painter: _TruckSvgPainter(
                              drawProgress:  _drawVal.value,
                              cabinProgress: _cabinVal.value,
                              wheelShow:     _wheelShowVal.value,
                              wheelAngle:    _wheelSpinCtrl.value * 2 * math.pi,
                              glowOpacity:   _glowVal.value,
                              scale:         scale,
                            ),
                          ),
                        ),
                        // Sparks
                        if (_showSparks)
                          Positioned(
                            bottom: 22 * scale, left: 200 * scale,
                            child: _SparksWidget(sparks: _sparks, scale: scale),
                          ),
                      ],
                    ),
                  ),
                ),
                // TruckMate text
                Positioned(
                  top: h * 0.30 + truckH + 40 * scale + 20,
                  left: 0, right: 0,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _textY.value),
                      child: Column(children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'Truck',
                              style: TextStyle(fontSize: 48,
                                  fontWeight: FontWeight.w700, color: kTruck,
                                  letterSpacing: -0.5),
                            ),
                            TextSpan(
                              text: 'Mate',
                              style: TextStyle(fontSize: 48,
                                  fontWeight: FontWeight.w700, color: kMate,
                                  letterSpacing: -0.5),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        Text('Connect  ·  Match  ·  Move',
                          style: TextStyle(fontSize: 13,
                              color: Colors.white.withOpacity(0.32),
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w300),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════
// Truck Painter (نفس الكود الأصلي)
// ════════════════════════════════════
class _TruckSvgPainter extends CustomPainter {
  final double drawProgress, cabinProgress, wheelShow, wheelAngle, glowOpacity, scale;
  _TruckSvgPainter({
    required this.drawProgress, required this.cabinProgress,
    required this.wheelShow, required this.wheelAngle,
    required this.glowOpacity, required this.scale,
  });

  Offset p(double x, double y) => Offset(x * scale, y * scale);

  @override
  void paint(Canvas canvas, Size size) {
    final grad = const LinearGradient(colors: [kTruck, kMate]);
    final gradRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bodyPath = Path()
      ..moveTo(p(40,70).dx,   p(40,70).dy)
      ..lineTo(p(140,70).dx,  p(140,70).dy)
      ..lineTo(p(140,50).dx,  p(140,50).dy)
      ..lineTo(p(180,50).dx,  p(180,50).dy)
      ..lineTo(p(200,70).dx,  p(200,70).dy)
      ..lineTo(p(240,70).dx,  p(240,70).dy)
      ..lineTo(p(240,100).dx, p(240,100).dy)
      ..lineTo(p(220,100).dx, p(220,100).dy)
      ..lineTo(p(220,110).dx, p(220,110).dy)
      ..lineTo(p(200,110).dx, p(200,110).dy)
      ..lineTo(p(200,100).dx, p(200,100).dy)
      ..lineTo(p(120,100).dx, p(120,100).dy)
      ..lineTo(p(120,110).dx, p(120,110).dy)
      ..lineTo(p(100,110).dx, p(100,110).dy)
      ..lineTo(p(100,100).dx, p(100,100).dy)
      ..lineTo(p(40,100).dx,  p(40,100).dy)
      ..close();

    final bodyMetrics = bodyPath.computeMetrics().toList();
    final animatedBody = Path();
    for (final metric in bodyMetrics) {
      animatedBody.addPath(
          metric.extractPath(0, metric.length * drawProgress), Offset.zero);
    }

    canvas.drawPath(animatedBody, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = kTruck.withOpacity(glowOpacity * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    canvas.drawPath(animatedBody, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = grad.createShader(gradRect));

    if (cabinProgress > 0) {
      final cabinPath = Path()
        ..moveTo(p(155,70).dx, p(155,70).dy)
        ..lineTo(p(155,55).dx,
            p(155,70).dy - (p(155,70).dy - p(155,55).dy) * cabinProgress);
      canvas.drawPath(cabinPath, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * scale
        ..strokeCap = StrokeCap.round
        ..shader = grad.createShader(gradRect));
    }

    if (wheelShow > 0) {
      _drawWheel(canvas, gradRect, cx: 210, cy: 110, r: 12,
          show: wheelShow, angle: wheelAngle, scale: scale);
      _drawWheel(canvas, gradRect, cx: 110, cy: 110, r: 12,
          show: wheelShow, angle: wheelAngle, scale: scale);
    }
  }

  void _drawWheel(Canvas canvas, Rect gradRect, {
    required double cx, required double cy, required double r,
    required double show, required double angle, required double scale,
  }) {
    final center = p(cx, cy);
    final radius = r * scale;

    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = kMate.withOpacity(show * glowOpacity * 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowOpacity));

    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = kTruck.withOpacity(show));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..color = kMate.withOpacity(show)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, -7*scale), Offset(0, 7*scale), spokePaint);
    canvas.drawLine(Offset(-7*scale, 0), Offset(7*scale, 0), spokePaint);
    canvas.restore();

    canvas.drawCircle(center, 5*scale, Paint()
      ..style = PaintingStyle.fill
      ..color = kMate.withOpacity(show * 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4*glowOpacity));

    canvas.drawCircle(center, 3*scale, Paint()
      ..style = PaintingStyle.fill
      ..color = kMate.withOpacity(show));

    final dotP = Paint()..color = kMate.withOpacity(show * 0.75);
    final dotR = 1.5 * scale;
    canvas.drawCircle(Offset(center.dx + 7*scale, center.dy), dotR, dotP);
    canvas.drawCircle(Offset(center.dx - 7*scale, center.dy), dotR, dotP);
    canvas.drawCircle(Offset(center.dx, center.dy - 7*scale), dotR, dotP);
    canvas.drawCircle(Offset(center.dx, center.dy + 7*scale), dotR, dotP);
  }

  @override
  bool shouldRepaint(_TruckSvgPainter o) =>
      o.drawProgress != drawProgress || o.cabinProgress != cabinProgress ||
      o.wheelShow != wheelShow || o.wheelAngle != wheelAngle ||
      o.glowOpacity != glowOpacity;
}

class _SparkParticle {
  final double angle, distance;
  _SparkParticle({required this.angle, required this.distance});
}

class _SparksWidget extends StatefulWidget {
  final List<_SparkParticle> sparks;
  final double scale;
  const _SparksWidget({required this.sparks, required this.scale});
  @override
  State<_SparksWidget> createState() => _SparksWidgetState();
}

class _SparksWidgetState extends State<_SparksWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 60, height: 60,
        child: CustomPaint(
          painter: _SparksPainter(sparks: widget.sparks, progress: _anim.value),
        ),
      ),
    );
  }
}

class _SparksPainter extends CustomPainter {
  final List<_SparkParticle> sparks;
  final double progress;
  _SparksPainter({required this.sparks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = kMate.withOpacity((1.0 - progress) * 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final spark in sparks) {
      final dist = spark.distance * progress;
      final x = center.dx + math.cos(spark.angle) * dist;
      final y = center.dy + math.sin(spark.angle) * dist;
      final r = 3.0 * (1.0 - progress * 0.5);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SparksPainter o) => o.progress != progress;
}