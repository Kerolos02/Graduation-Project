import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/api_service.dart';

class DriverOTPScreen5 extends StatefulWidget {
  final String email;
  const DriverOTPScreen5({super.key, this.email = ''});

  @override
  State<DriverOTPScreen5> createState() => _DriverOTPScreen5State();
}

class _DriverOTPScreen5State extends State<DriverOTPScreen5>
    with TickerProviderStateMixin {
  static const int _initialSeconds = 30;
  int _secondsLeft = _initialSeconds;
  Timer? _timer;
  bool _isResending = false;
  bool get _canResend => _secondsLeft == 0 && !_isResending;

  // ── Animations ──
  late final AnimationController _entranceCtrl;
  late final AnimationController _rippleCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _rotateCtrl;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _warnFade;
  late final Animation<Offset> _warnSlide;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  late final Animation<double> _ripple1;
  late final Animation<double> _rippleOpacity1;
  late final Animation<double> _ripple2;
  late final Animation<double> _rippleOpacity2;

  late final Animation<double> _shake;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _cardFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.55, curve: Curves.elasticOut)));

    _titleFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.3, 0.75, curve: Curves.easeOut)));

    _warnFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut));
    _warnSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.45, 0.85, curve: Curves.easeOut)));

    _btnFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _ripple1 = Tween<double>(begin: 1.0, end: 1.6)
        .animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _rippleOpacity1 = Tween<double>(begin: 0.7, end: 0.0)
        .animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _ripple2 = Tween<double>(begin: 1.0, end: 1.6).animate(CurvedAnimation(
        parent: _rippleCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _rippleOpacity2 = Tween<double>(begin: 0.7, end: 0.0).animate(
        CurvedAnimation(
            parent: _rippleCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _triggerShake();
      Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (!mounted) return;
        _triggerShake();
      });
    });

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
  }

  void _triggerShake() {
    if (!mounted) return;
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        timer.cancel();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  // ── POST /register/send-otp ──
  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() => _isResending = true);

    try {
      await ApiService().post(
        '/register/send-otp',
        data: {'email': widget.email},
      );
      if (!mounted) return;
      // رجع للـ screen السابقة مع true = تم الإرسال
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to resend OTP. Please try again.'),
        backgroundColor: const Color(0xFFFF3B30),
        duration: const Duration(seconds: 3),
      ));
      setState(() {
        _isResending = false;
        _secondsLeft = _initialSeconds;
      });
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceCtrl.dispose();
    _rippleCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final bool waiting = _secondsLeft > 0;

    return Scaffold(
      backgroundColor: t.isDark ? const Color(0xFF0A1628) : const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  width: 335,
                  height: 635,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0xFF192C3D) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF00D5BE).withOpacity(0.2),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withOpacity(0.08),
                        blurRadius: 32, offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 60, offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Stack(children: [
                    ..._buildCornerDots(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Error Icon with ripple ──
                        ScaleTransition(
                          scale: _iconScale,
                          child: SizedBox(
                            width: 100, height: 100,
                            child: Stack(alignment: Alignment.center, children: [
                              AnimatedBuilder(
                                animation: _ripple1,
                                builder: (_, __) => Transform.scale(
                                  scale: _ripple1.value,
                                  child: Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF3B30)
                                            .withOpacity(_rippleOpacity1.value * 0.6),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _ripple2,
                                builder: (_, __) => Transform.scale(
                                  scale: _ripple2.value,
                                  child: Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF3B30)
                                            .withOpacity(_rippleOpacity2.value * 0.6),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, __) => Transform.scale(
                                  scale: _pulseAnim.value,
                                  child: Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF3B30).withOpacity(0.12),
                                      border: Border.all(
                                        color: const Color(0xFFFF3B30).withOpacity(
                                            0.5 + 0.2 * (_pulseAnim.value - 0.92) / 0.16),
                                        width: 1.5,
                                      ),
                                      boxShadow: [BoxShadow(
                                        color: const Color(0xFFFF3B30).withOpacity(
                                            0.15 + 0.15 * (_pulseAnim.value - 0.92) / 0.16),
                                        blurRadius: 20, spreadRadius: 3,
                                      )],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _shake,
                                builder: (_, __) => Transform.translate(
                                  offset: Offset(_shake.value, 0),
                                  child: const Icon(Icons.error_outline,
                                      color: Color(0xFFFF3B30), size: 32),
                                ),
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 28),

                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              'The OTP has expired',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: t.textPrimary, fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              widget.email.isNotEmpty
                                  ? 'Please resend a new code to ${widget.email}'
                                  : 'Please resend the verification code to try again',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: t.textMuted, fontSize: 14, height: 1.6),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Warning box
                        FadeTransition(
                          opacity: _warnFade,
                          child: SlideTransition(
                            position: _warnSlide,
                            child: Container(
                              width: 293.4,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFF3B30).withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, __) => Transform.scale(
                                      scale: 0.95 + 0.1 * (_pulseAnim.value - 0.92) / 0.16,
                                      child: const Icon(Icons.error_outline,
                                          color: Color(0xFFFF3B30), size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            color: t.textMuted, fontSize: 12.5, height: 1.6),
                                        children: const [
                                          TextSpan(text: 'Your verification code has '),
                                          TextSpan(
                                            text: 'timed out.',
                                            style: TextStyle(
                                                color: Color(0xFFFF3B30),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: '\nRequest a new code to continue.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Resend button
                        FadeTransition(
                          opacity: _btnFade,
                          child: SlideTransition(
                            position: _btnSlide,
                            child: _ResendButton(
                              canResend: _canResend,
                              isResending: _isResending,
                              onTap: _handleResend,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Back button
                        FadeTransition(
                          opacity: _btnFade,
                          child: SlideTransition(
                            position: _btnSlide,
                            child: Container(
                              width: 290.2, height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF00D5BE).withOpacity(0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Back',
                                    style: TextStyle(color: t.textMuted, fontSize: 15)),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Countdown
                        FadeTransition(
                          opacity: _btnFade,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: const Color(0xFF00D5BE).withOpacity(0.5),
                                  value: waiting ? null : 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                waiting
                                    ? 'Resend available in ${_secondsLeft}s'
                                    : 'Resend available',
                                style: TextStyle(color: t.textMuted, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        Container(width: double.infinity, height: 0.5, color: t.border),
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

// ── Resend button ──
class _ResendButton extends StatefulWidget {
  final bool canResend;
  final bool isResending;
  final VoidCallback onTap;
  const _ResendButton({required this.canResend, required this.isResending, required this.onTap});

  @override
  State<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<_ResendButton>
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
      onTapDown: (_) { if (widget.canResend) _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); if (widget.canResend) widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 290.2, height: 48.8,
          decoration: BoxDecoration(
            gradient: widget.canResend
                ? const LinearGradient(
                    colors: [Color(0xFF17D4B4), Color(0xFF0E8FD4)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight)
                : null,
            color: widget.canResend ? null : const Color(0xFF049286).withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF00D5BE).withOpacity(0.25), width: 0.8),
            boxShadow: widget.canResend
                ? [BoxShadow(
                    color: const Color(0xFF00D5BE).withOpacity(0.3),
                    blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.isResending
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: widget.canResend
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    fontSize: 16, fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}