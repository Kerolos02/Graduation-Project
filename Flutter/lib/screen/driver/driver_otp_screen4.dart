import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import '/screen/common/review_confirm_screen.dart';
import '/services/auth_service.dart';

class DriverOtpScreen4 extends StatefulWidget {
  final String fullName;
  final String phone;
  final String email;
  final String nationalId;
  final String licenseNumber;
  final String licenseType;
  final String plateNumber;
  final String truckType;
  final String capacity;
  final String password;
  final String licenseImageBase64;

  const DriverOtpScreen4({
    super.key,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.nationalId = '',
    this.licenseNumber = '',
    this.licenseType = '',
    this.plateNumber = '',
    this.truckType = '',
    this.capacity = '',
    this.password = '',
    this.licenseImageBase64 = '',
  });

  @override
  State<DriverOtpScreen4> createState() => _DriverOtpScreen4State();
}

class _DriverOtpScreen4State extends State<DriverOtpScreen4>
    with TickerProviderStateMixin {

  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  bool _isSubmitting = false;
  String _otpJwtToken = ''; // ← JWT token من send-otp (لو الباك بيرجعه)

  final AuthService _authService = AuthService();

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
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _rotateCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 14),
    )..repeat();

    _dotsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    )..forward();

    // ── بعت الـ OTP لما الشاشة تفتح ──
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());

    final intervals = [
      const Interval(0.0, 0.45),
      const Interval(0.15, 0.60),
      const Interval(0.28, 0.72),
      const Interval(0.40, 0.85),
      const Interval(0.55, 1.0),
    ];
    _fadeSeries = intervals.map((iv) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(iv.begin, iv.end, curve: Curves.easeOut))).toList();
    _slideSeries = _fadeSeries.map((a) => Tween<Offset>(
        begin: const Offset(0, 0.2), end: Offset.zero).animate(a)).toList();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _dotsCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length == 6) _submitOtp();
  }

  // ── send-otp ──
  Future<void> _sendOtp() async {
    final result = await _authService.sendOtp(
      phone: widget.phone,
      email: widget.email,
    );
    print('📧 send-otp response: $result');
    if (result['success']) {
      final data = result['data'];
      // جرب كل الأماكن المحتملة للـ token (لو الباك بيرجع otpToken)
      final token = data?['data']?['token']
          ?? data?['data']?['otpToken']
          ?? data?['data']?['jwt']
          ?? data?['token']
          ?? data?['otpToken']
          ?? data?['jwt']
          ?? '';
      if (token.isNotEmpty && mounted) {
        final String tokenStr = token.toString();
        setState(() => _otpJwtToken = tokenStr);
        final int previewLen = tokenStr.length < 20 ? tokenStr.length : 20;
        print('✅ JWT token saved: ${tokenStr.substring(0, previewLen)}...');
      }
    }
  }

  Future<void> _submitOtp() async {
    if (_isSubmitting) return;
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // ── Step 1: verify-otp ──
    final verifyResult = await _authService.verifyOtp(
      email: widget.email,
      otp: enteredOtp,
      otpToken: _otpJwtToken,
    );

    if (!mounted) { _isSubmitting = false; return; }

    if (!verifyResult['success']) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(verifyResult['message'] ?? 'Invalid OTP'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    // ── Step 2: جيب الـ verificationToken من رد verify-otp ──
    final responseData = verifyResult['data'];
    final token = responseData?['data']?['verificationToken']
        ?? responseData?['verificationToken']
        ?? responseData?['token']
        ?? '';

    if (token.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verification failed. Please try again.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    // ── Step 3: register
    // otpVerificationCode هي required جوه driver object نفسه
    // (مش top-level) — اتظبطت في AuthService.register
    final result = await _authService.register(
      name:                widget.fullName,
      phone:               widget.phone,
      email:               widget.email,
      password:            widget.password,
      verificationToken:   token,
      otpVerificationCode: enteredOtp,
      nationalId:          widget.nationalId,
      licenseNumber:       widget.licenseNumber,
      licenseType:         widget.licenseType,
      plateNumber:         widget.plateNumber,
      truckType:           widget.truckType,
      capacity:            widget.capacity,
      licenseImageBase64:  widget.licenseImageBase64,
    );

    if (!mounted) { _isSubmitting = false; return; }

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', 'driver');
      await prefs.setString('lastRole', 'driver');
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReviewConfirmScreen(
          fullName:      widget.fullName,
          phone:         widget.phone,
          email:         widget.email,
          nationalId:    widget.nationalId,
          licenseNumber: widget.licenseNumber,
          licenseType:   widget.licenseType,
          plateNumber:   widget.plateNumber,
          truckType:     widget.truckType,
          capacity:      widget.capacity,
        ),
      )).then((_) => _isSubmitting = false);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Registration failed'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
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
      backgroundColor: t.isDark ? const Color(0xFF0F2334) : const Color(0xFFF9FBFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(children: [
                  const Spacer(flex: 1),

                  _stagger(0, SizedBox(
                    width: 130, height: 130,
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(animation: _rotateCtrl, builder: (_, __) => Transform.rotate(
                        angle: _rotateCtrl.value * 2 * pi,
                        child: Container(width: 185, height: 185, decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.15), width: 1))),
                      )),
                      AnimatedBuilder(animation: _rotateCtrl, builder: (_, __) => Transform.rotate(
                        angle: -_rotateCtrl.value * 2 * pi * 0.65,
                        child: Container(width: 150, height: 150, decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF8904).withOpacity(0.12), width: 1))),
                      )),
                      AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(width: 132, height: 132, decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D1E2E),
                          border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.35), width: 1.5),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF00D5BE).withOpacity(0.1 + 0.12 * _pulseAnim.value),
                            blurRadius: 26, spreadRadius: 4)])),
                      )),
                      AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Icon(
                        Icons.shield, color: const Color(0xFF00D5BE), size: 68,
                        shadows: [Shadow(
                          color: const Color(0xFF00D5BE).withOpacity(0.3 + 0.25 * _pulseAnim.value),
                          blurRadius: 20)],
                      )),
                      const Padding(padding: EdgeInsets.only(top: 8),
                          child: Icon(Icons.lock, color: Colors.white, size: 22)),
                      ..._buildFloatingDots(),
                    ]),
                  )),

                  const Spacer(flex: 2),

                  Center(child: Container(
                    width: 326,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                    decoration: BoxDecoration(
                      color: t.isDark ? const Color(0xFF192C3D) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF00D3F2).withOpacity(0.25), width: 0.8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3),
                            blurRadius: 50, spreadRadius: -12, offset: const Offset(0, 25)),
                        BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.12),
                            blurRadius: 20, spreadRadius: 1),
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      _stagger(1, Text('OTP Verification', style: TextStyle(
                        color: t.textPrimary, fontSize: 22,
                        fontWeight: FontWeight.w700, letterSpacing: 0.3))),
                      const SizedBox(height: 10),
                      _stagger(1, RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13.5),
                          children: [
                            const TextSpan(text: 'Enter OTP sent to\n'),
                            TextSpan(
                              text: widget.email.isNotEmpty ? widget.email : 'your email',
                              style: const TextStyle(color: Color(0xFF00D5BE), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      _stagger(1, const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.mail_outline_rounded, color: Color(0xFF00D5BE), size: 13),
                        SizedBox(width: 5),
                        Text('Check your email inbox',
                            style: TextStyle(color: Color(0xFF00D5BE), fontSize: 12)),
                      ])),
                      const SizedBox(height: 24),

                      _stagger(2, Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _AnimatedOtpBox(
                            controller: _otpControllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onOtpChanged(i, v),
                            onBackspaceWhenEmpty: () {
                              if (i > 0) _focusNodes[i - 1].requestFocus();
                            },
                            enterDelay: Duration(milliseconds: 300 + i * 70),
                          ),
                        )),
                      )),
                      const SizedBox(height: 24),

                      _stagger(3, _isSubmitting
                          ? const CircularProgressIndicator(color: Color(0xFF00D5BE))
                          : _PressableButton(label: 'Verify', onTap: _submitOtp)),

                      const SizedBox(height: 20),

                      _stagger(4, Column(children: [
                        Text("Don't receive the OTP?",
                            style: TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 13)),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () async {
                            await _authService.sendOtp(phone: widget.phone, email: widget.email);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OTP resent to your email.')));
                            }
                          },
                          child: const Text('RESEND OTP', style: TextStyle(
                            color: Color(0xFF00D5BE), fontSize: 13.5,
                            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ),
                      ])),
                    ]),
                  )),

                  const Spacer(flex: 1),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingDots() {
    final positions = [
      {'top': 42.0, 'left': 22.0}, {'top': 26.0, 'left': 42.0},
      {'top': 42.0, 'right': 22.0}, {'top': 26.0, 'right': 42.0},
      {'bottom': 42.0, 'left': 26.0}, {'bottom': 26.0, 'left': 46.0},
      {'bottom': 42.0, 'right': 26.0}, {'bottom': 26.0, 'right': 46.0},
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
            final t = (_dotsCtrl.value + i * 0.13) % 1.0;
            final opacity = 0.28 + 0.6 * sin(t * pi);
            final scale = 0.75 + 0.45 * sin(t * pi);
            return Transform.scale(scale: scale,
              child: Container(width: 6, height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(
                    color: color.withOpacity(opacity * 0.55), blurRadius: 5)])));
          },
        ),
      );
    }).toList();
  }
}

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
          child: Text(widget.label, style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

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
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;
  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
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
                width: 38, height: 55,
                decoration: BoxDecoration(
                  color: t.isDark ? const Color(0xFF0A1828) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused ? const Color(0xFF00D5BE) : const Color(0xFF00D5BE).withOpacity(0.45),
                    width: isFocused ? 2 : 1.5),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF00D5BE).withOpacity(isFocused ? 0.35 : 0.12),
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
                      fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '', border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    cursorColor: const Color(0xFF00D5BE),
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