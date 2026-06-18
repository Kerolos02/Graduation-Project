import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import '/screen/auth/driver_reset_password.dart';
import '/services/auth_service.dart';

// ✅ FIX: شيلنا OtpFlowStep بالكامل — خطوة واحدة بس
class DriverOtpScreen extends StatefulWidget {
  final String email; // ✅ FIX: email بدل phone
  const DriverOtpScreen({
    super.key,
    this.email = '',
  });

  @override
  State<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends State<DriverOtpScreen>
    with TickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _secondsLeft = 46;
  Timer? _timer;
  bool _loading = false;
  final AuthService _authService = AuthService();

  // ── Animations ──
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _rotateCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _entranceCtrl;

  late final List<Animation<double>> _fadeSeries;
  late final List<Animation<Offset>> _slideSeries;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    final intervals = [
      const Interval(0.0, 0.45),
      const Interval(0.1, 0.55),
      const Interval(0.2, 0.65),
      const Interval(0.3, 0.75),
      const Interval(0.4, 0.85),
      const Interval(0.5, 0.90),
      const Interval(0.6, 1.0),
    ];

    _fadeSeries = intervals
        .map((iv) => CurvedAnimation(
            parent: _entranceCtrl,
            curve: Interval(iv.begin, iv.end, curve: Curves.easeOut)))
        .toList();

    _slideSeries = _fadeSeries
        .map((a) => Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(a))
        .toList();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _dotsCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
  }

  void _onBackspaceEmpty(int index) {
    if (index == 0) return;
    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index - 1].text.length),
    );
  }

  // ✅ FIX: verify-reset-otp بـ email+otp، واستخراج resetToken من الـ response
  // ثم الانتقال مباشرة لـ DriverResetPassword (خطوة واحدة، مش اتنين)
  Future<void> _verifyAndContinue() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code.')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.verifyResetOtp(
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      // ── استخراج resetToken من الـ response (بأماكن محتملة مختلفة) ──
      final data = result['data'];
      final resetToken = data?['data']?['resetToken']
          ?? data?['resetToken']
          ?? data?['data']?['token']
          ?? data?['token']
          ?? '';

      if (resetToken.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verification failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverResetPassword(
            resetToken: resetToken.toString(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Something went wrong.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ✅ FIX: resend بـ email
  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    final result = await _authService.forgotPassword(email: widget.email);
    if (!mounted) return;
    if (result['success']) {
      setState(() => _secondsLeft = 46);
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Something went wrong.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _stagger(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeSeries[index],
      child: SlideTransition(position: _slideSeries[index], child: child),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
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
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ..._buildCornerDots(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ── Animated icons row ──
                      _stagger(
                        0,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(0, -4 * (_pulseAnim.value - 0.88) / 0.12),
                                child: const Icon(Icons.lock_outline,
                                    color: Color(0xFFE6A817), size: 44),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 78, height: 78,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _rotateCtrl,
                                    builder: (_, __) => Transform.rotate(
                                      angle: _rotateCtrl.value * 2 * pi,
                                      child: Container(
                                        width: 78, height: 78,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF00D5BE).withOpacity(0.25),
                                            width: 1,
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
                                        width: 72, height: 72,
                                        decoration: BoxDecoration(
                                          color: t.isDark ? const Color(0xFF0D2035) : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00D5BE)
                                                  .withOpacity(0.15 + 0.15 * _pulseAnim.value),
                                              blurRadius: 18, spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.shield,
                                            color: Color(0xFF00D5BE), size: 58),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Icon(Icons.check, color: Colors.white, size: 22),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(0, 4 * (_pulseAnim.value - 0.88) / 0.12),
                                child: const Icon(Icons.vpn_key_outlined,
                                    color: Color(0xFF00D5BE), size: 38),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      _stagger(1, Text('Reset Password',
                          style: TextStyle(color: t.textPrimary, fontSize: 26,
                              fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                      const SizedBox(height: 6),
                      _stagger(1, Container(
                        width: 75, height: 1,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D5BE).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),

                      const SizedBox(height: 12),

                      // ✅ FIX: نص واحد بس (مش step 1/2)
                      _stagger(2, Text(
                        'Enter the 6-digit verification code sent to your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      )),

                      const SizedBox(height: 10),

                      // ✅ FIX: بيعرض الإيميل (الأيقونة متطابقة دلوقتي)
                      _stagger(2, Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D5BE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00D5BE).withOpacity(0.3), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline_rounded,
                                color: Color(0xFF00D5BE), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              widget.email.isNotEmpty ? widget.email : '***',
                              style: const TextStyle(color: Color(0xFF00D5BE), fontSize: 12),
                            ),
                          ],
                        ),
                      )),

                      const SizedBox(height: 24),

                      // OTP Boxes
                      _stagger(3, Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) => _OtpDigitBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (v) => _onChanged(i, v),
                          onBackspaceWhenEmpty: () => _onBackspaceEmpty(i),
                          enterDelay: Duration(milliseconds: 400 + i * 60),
                        )),
                      )),

                      const SizedBox(height: 20),

                      // Timer
                      _stagger(4, AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8904).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF8904)
                                  .withOpacity(0.3 + 0.1 * (_pulseAnim.value - 0.88) / 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFFFF8904).withOpacity(
                                  0.1 + 0.12 * (_pulseAnim.value - 0.88) / 0.12),
                              blurRadius: 14, spreadRadius: 1,
                            )],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFFFF8904), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '0:' + (_secondsLeft < 10 ? '0$_secondsLeft' : '$_secondsLeft'),
                                style: const TextStyle(
                                    color: Color(0xFFFF8904), fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 16),

                      // Security hint box
                      _stagger(4, Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D5BE).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.2), width: 0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFF00D5BE), size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.6),
                                children: const [
                                  TextSpan(text: 'This is a temporary verification code '),
                                  TextSpan(text: 'Never share it with anyone',
                                      style: TextStyle(color: Color(0xFF00D5BE), fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' for your security.'),
                                ],
                              ),
                            )),
                          ],
                        ),
                      )),

                      const SizedBox(height: 20),

                      // ✅ FIX: نص الزرار ثابت (مش Final)
                      _stagger(5, _loading
                          ? const CircularProgressIndicator(color: Color(0xFF00D5BE))
                          : _PressableButton(
                              label: 'Verify Code',
                              onTap: _verifyAndContinue,
                            )),

                      const SizedBox(height: 12),

                      // Resend button
                      _stagger(6, SizedBox(
                        width: double.infinity, height: 50,
                        child: OutlinedButton(
                          onPressed: _secondsLeft == 0 ? _resend : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: t.border, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_secondsLeft > 0) ...[
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: t.textMuted),
                                ),
                                const SizedBox(width: 8),
                                Text('Resend available in ${_secondsLeft}s',
                                    style: TextStyle(color: t.textMuted, fontSize: 13)),
                              ] else
                                const Text('Resend OTP',
                                    style: TextStyle(color: Color(0xFF00D5BE),
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 20),

                      _stagger(6, Text(
                        '© 2025 TruckMate Smart Logistics. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10),
                      )),

                      const SizedBox(height: 8),
                    ],
                  ),
                ],
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
                  boxShadow: [BoxShadow(color: color.withOpacity(opacity * 0.5), blurRadius: 5)],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}

// ── Pressable gradient button ──
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
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF009689), Color(0xFF00BBA7), Color(0xFF00B4D8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.3),
              blurRadius: 14, offset: const Offset(0, 4),
            )],
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ── Animated OTP digit box ──
class _OtpDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceWhenEmpty;
  final Duration enterDelay;

  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspaceWhenEmpty,
    this.enterDelay = Duration.zero,
  });

  @override
  State<_OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<_OtpDigitBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _enterScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut),
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    Future.delayed(widget.enterDelay, () { if (mounted) _enterCtrl.forward(); });
  }

  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return FadeTransition(
      opacity: _enterFade,
      child: ScaleTransition(
        scale: _enterScale,
        child: SizedBox(
          width: 46,
          height: 58,
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  widget.controller.text.isEmpty) {
                widget.onBackspaceWhenEmpty();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedBuilder(
              animation: widget.focusNode,
              builder: (_, __) {
                final isFocused = widget.focusNode.hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0xFF0F1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF00D5BE)
                          : const Color(0xFF00D5BE).withOpacity(0.2),
                      width: isFocused ? 2 : 1.5,
                    ),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF00D5BE).withOpacity(isFocused ? 0.35 : 0.1),
                      blurRadius: isFocused ? 16 : 6,
                      spreadRadius: isFocused ? 2 : 0,
                    )],
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: widget.onChanged,
                    style: TextStyle(
                      color: t.isDark ? Colors.white : const Color(0xFF1A2A3A),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    cursorColor: Color(0xFF00D5BE),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}