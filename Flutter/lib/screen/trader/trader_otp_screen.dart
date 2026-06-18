import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';
import '/services/auth_service.dart';

class TraderOtpScreen extends StatefulWidget {
  final String fullName, phone, email, nationalId, password, businessName, address;
  const TraderOtpScreen({
    super.key,
    this.fullName = '', this.phone = '', this.email = '',
    this.nationalId = '', this.password = '',
    this.businessName = '', this.address = '',
  });
  @override
  State<TraderOtpScreen> createState() => _TraderOtpScreenState();
}

class _TraderOtpScreenState extends State<TraderOtpScreen>
    with TickerProviderStateMixin {

  // ✅ 6 خانات زي الـ driver
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  bool _isSubmitting = false;
  bool _isResending  = false;
  String? _errorMsg;

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
    // ✅ 6 بدل 4
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes     = List.generate(6, (_) => FocusNode());

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 14))..repeat();

    _dotsCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

    _entranceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000))..forward();

    final intervals = [
      const Interval(0.0, 0.45), const Interval(0.15, 0.60),
      const Interval(0.28, 0.72), const Interval(0.40, 0.85),
      const Interval(0.55, 1.0),
    ];
    _fadeSeries = intervals.map((iv) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(iv.begin, iv.end, curve: Curves.easeOut))).toList();
    _slideSeries = _fadeSeries.map((a) =>
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(a)).toList();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _pulseCtrl.dispose(); _rotateCtrl.dispose();
    _dotsCtrl.dispose(); _entranceCtrl.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    // ✅ 5 بدل 3 عشان 6 boxes
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    final entered = _otpControllers.map((c) => c.text).join();
    // ✅ 6 بدل 4
    if (entered.length == 6) _submitOtp();
  }

  Future<void> _submitOtp() async {
    if (_isSubmitting) return;
    final otp = _otpControllers.map((c) => c.text).join();
    // ✅ 6 بدل 4
    if (otp.length != 6) {
      setState(() => _errorMsg = 'Please enter the 6-digit code');
      return;
    }

    setState(() { _isSubmitting = true; _errorMsg = null; });

    // ── Step 1: verify OTP ──
    final verifyResult = await AuthService().verifyOtp(
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;

    if (verifyResult['success'] != true) {
      setState(() {
        _isSubmitting = false;
        _errorMsg = verifyResult['message'] ?? 'Invalid OTP';
        for (final c in _otpControllers) c.clear();
        _focusNodes[0].requestFocus();
      });
      return;
    }

    // ── Step 2: register trader ──
    final verificationToken =
        verifyResult['data']?['verificationToken'] ??
        verifyResult['data']?['token'] ?? '';

    final registerResult = await AuthService().registerTrader(
      name:                widget.fullName,
      phone:               widget.phone,
      email:               widget.email,
      password:            widget.password,
      verificationToken:   verificationToken,
      otpVerificationCode: otp,
      nationalId:          widget.nationalId,
      businessName:        widget.businessName,
      address:             widget.address,
    );

    if (!mounted) return;

    if (registerResult['success'] == true) {
      context.read<UserProvider>().update(
        fullName:   widget.fullName,
        phone:      widget.phone,
        email:      widget.email,
        nationalId: widget.nationalId,
      );
      Navigator.pushNamedAndRemoveUntil(
          context, '/trader_home', (route) => false);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMsg = registerResult['message'] ?? 'Registration failed';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;
    setState(() { _isResending = true; _errorMsg = null; });

    final result = await AuthService().sendOtp(
      phone: widget.phone,
      email: widget.email,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      for (final c in _otpControllers) c.clear();
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('OTP resent successfully!'),
        backgroundColor: Color(0xFF00D5BE),
        duration: Duration(seconds: 2),
      ));
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Failed to resend OTP');
    }
  }

  Widget _stagger(int i, Widget child) => FadeTransition(
    opacity: _fadeSeries[i],
    child: SlideTransition(position: _slideSeries[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: t.isDark ? const Color(0xFF0F2334) : const Color(0xFFF4F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(children: [
                  const Spacer(flex: 1),

                  // ── Animated Shield ──
                  _stagger(0, SizedBox(
                    width: 130, height: 130,
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(
                        animation: _rotateCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: _rotateCtrl.value * 2 * pi,
                          child: Container(width: 185, height: 185,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00D5BE).withOpacity(0.15), width: 1))),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _rotateCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: -_rotateCtrl.value * 2 * pi * 0.65,
                          child: Container(width: 150, height: 150,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF8904).withOpacity(0.12), width: 1))),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(width: 132, height: 132,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              color: t.isDark ? const Color(0xFF0D1E2E) : const Color(0xFFFFFFFF),
                              border: Border.all(
                                color: const Color(0xFF00D5BE).withOpacity(0.35), width: 1.5),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF00D5BE)
                                    .withOpacity(0.1 + 0.12 * _pulseAnim.value),
                                blurRadius: 26, spreadRadius: 4)])),
                        ),
                      ),
                      const Icon(Icons.shield_outlined, color: Color(0xFF00D5BE), size: 52),
                      ..._buildDots(),
                    ]),
                  )),

                  const SizedBox(height: 32),

                  // ── Title ──
                  _stagger(1, Column(children: [
                    Text('OTP Verification',
                        style: TextStyle(color: t.textPrimary, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit code to\n${widget.email.isEmpty ? 'your email' : widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.textMuted, fontSize: 13.5),
                    ),
                  ])),

                  const SizedBox(height: 36),

                  // ✅ 6 OTP Boxes
                  _stagger(2, Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => _AnimatedOtpBox(
                        controller: _otpControllers[i],
                        focusNode: _focusNodes[i],
                        enterDelay: Duration(milliseconds: 60 * i),
                        onChanged: (v) => _onOtpChanged(i, v),
                        onBackspaceWhenEmpty: () {
                          if (i > 0) _focusNodes[i - 1].requestFocus();
                        },
                      )),
                    ),
                  )),

                  const SizedBox(height: 12),

                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_errorMsg!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),

                  const SizedBox(height: 20),

                  // ── Verify Button ──
                  _stagger(3, Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PressableButton(
                      label: 'Verify & Create Account',
                      isLoading: _isSubmitting,
                      onTap: _submitOtp,
                    ),
                  )),

                  const SizedBox(height: 16),

                  // ── Resend ──
                  _stagger(4, TextButton(
                    onPressed: _isResending ? null : _resendOtp,
                    child: _isResending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Color(0xFF00D5BE), strokeWidth: 2))
                        : const Text('Resend OTP',
                            style: TextStyle(color: Color(0xFF00D5BE),
                                fontSize: 14, fontWeight: FontWeight.w600)),
                  )),

                  const Spacer(flex: 2),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    final positions = [
      {'top': 42.0, 'left': 26.0}, {'top': 26.0, 'left': 46.0},
      {'top': 42.0, 'right': 26.0}, {'top': 26.0, 'right': 46.0},
      {'bottom': 42.0, 'left': 26.0}, {'bottom': 26.0, 'left': 46.0},
      {'bottom': 42.0, 'right': 26.0}, {'bottom': 26.0, 'right': 46.0},
    ];
    return positions.asMap().entries.map((entry) {
      final i = entry.key; final pos = entry.value;
      final color = i % 3 == 0 ? const Color(0xFFFF8904) : const Color(0xFF00D5BE);
      return Positioned(
        top: pos['top'], bottom: pos['bottom'],
        left: pos['left'], right: pos['right'],
        child: AnimatedBuilder(
          animation: _dotsCtrl,
          builder: (_, __) {
            final t = (_dotsCtrl.value + i * 0.13) % 1.0;
            final opacity = 0.28 + 0.6 * sin(t * pi);
            return Transform.scale(
              scale: 0.75 + 0.45 * sin(t * pi),
              child: Container(width: 6, height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(opacity * 0.55), blurRadius: 5)])));
          }),
      );
    }).toList();
  }
}

// ── Pressable Button ──
class _PressableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  const _PressableButton({required this.label, required this.onTap, this.isLoading = false});
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
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF00D5BE).withOpacity(0.85),
              const Color(0xFF00D3F2).withOpacity(0.85),
            ], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: const Color(0xFF00D5BE).withOpacity(0.3),
                blurRadius: 18, offset: const Offset(0, 6))]),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(widget.label,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ✅ OTP Box عرضه 46 زي الـ driver عشان 6 boxes تتناسب
class _AnimatedOtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceWhenEmpty;
  final Duration enterDelay;
  const _AnimatedOtpBox({
    required this.controller, required this.focusNode,
    required this.onChanged, required this.onBackspaceWhenEmpty,
    this.enterDelay = Duration.zero,
  });
  @override
  State<_AnimatedOtpBox> createState() => _AnimatedOtpBoxState();
}

class _AnimatedOtpBoxState extends State<_AnimatedOtpBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale, _enterFade;
  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 420));
    _enterScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut));
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
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (_, __, ___) => AnimatedBuilder(
            animation: widget.focusNode,
            builder: (_, __) {
              final isFocused = widget.focusNode.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // ✅ 46 عرض زي الـ driver
                width: 46, height: 58,
                decoration: BoxDecoration(
                  color: t.isDark ? const Color(0xFF0A1828) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? const Color(0xFF00D5BE)
                        : const Color(0xFF00D5BE).withOpacity(0.45),
                    width: isFocused ? 2 : 1.5),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF00D5BE)
                        .withOpacity(isFocused ? 0.35 : 0.12),
                    blurRadius: isFocused ? 16 : 6,
                    spreadRadius: isFocused ? 2 : 0)]),
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
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: widget.onChanged,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                        color: t.isDark ? Colors.white : const Color(0xFF1A2A3A),
                        fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '', border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      isCollapsed: false),
                    cursorColor: Color(0xFF00D5BE),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}