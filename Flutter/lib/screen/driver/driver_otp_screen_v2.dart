import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screen/driver/driver_otp_screen.dart';
import '/screen/auth/select_role.dart';
import '/providers/theme_provider.dart';
import '/services/auth_service.dart'; // ✅

class DriverOtpScreenV2 extends StatefulWidget {
  const DriverOtpScreenV2({super.key});
  @override
  State<DriverOtpScreenV2> createState() => _DriverOtpScreenV2State();
}

class _DriverOtpScreenV2State extends State<DriverOtpScreenV2>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl, _rotateCtrl, _dotsCtrl, _entranceCtrl;
  late final Animation<double> _pulseAnim, _iconFade, _cardFade;
  late final Animation<Offset> _iconSlide, _cardSlide;

  // ✅ FIX: الباك بيطلب email (SendOtpRequestDto: required ["email"]) مش phone
  final _emailCtrl = TextEditingController();
  bool _loading = false; // ✅
  final AuthService _authService = AuthService(); // ✅

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _iconFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _iconSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _cardFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); // ✅
    _pulseCtrl.dispose(); _rotateCtrl.dispose();
    _dotsCtrl.dispose(); _entranceCtrl.dispose();
    super.dispose();
  }

  // ✅ FIX: بيبعت للباك POST /register/forgot-password بـ email
  Future<void> _generateOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.forgotPassword(email: email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DriverOtpScreen(
          email: email,
        ),
      ));
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: t.isDark ? const Color(0xFF0F2334) : const Color(0xFFF4F7FA),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: Column(children: [
              const Spacer(flex: 1),
              FadeTransition(opacity: _iconFade, child: SlideTransition(position: _iconSlide,
                child: SizedBox(width: 130, height: 130, child: Stack(alignment: Alignment.center, children: [
                  AnimatedBuilder(animation: _rotateCtrl, builder: (_, __) => Transform.rotate(angle: _rotateCtrl.value * 2 * pi,
                    child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.18), width: 1))))),
                  AnimatedBuilder(animation: _rotateCtrl, builder: (_, __) => Transform.rotate(angle: -_rotateCtrl.value * 2 * pi * 0.6,
                    child: Container(width: 105, height: 105, decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF8904).withOpacity(0.12), width: 1))))),
                  AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Transform.scale(scale: _pulseAnim.value,
                    child: Container(width: 132, height: 132, decoration: BoxDecoration(shape: BoxShape.circle,
                      color: t.isDark ? const Color(0xFF0D1E2E) : Colors.white,
                      border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.35), width: 1.5),
                      boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.1 + 0.12 * _pulseAnim.value), blurRadius: 28, spreadRadius: 4)])))),
                  const Icon(Icons.shield, color: Color(0xFF00D5BE), size: 46),
                  const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.lock, color: Colors.white, size: 22)),
                  ..._buildDots(),
                ])))),
              const Spacer(flex: 2),
              FadeTransition(opacity: _cardFade, child: SlideTransition(position: _cardSlide,
                child: Center(child: Container(
                  width: 319.5,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0xFF192C3D) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: t.isDark ? const Color(0xFF00D3F2).withOpacity(0.25) : t.border, width: 0.8),
                    boxShadow: t.cardShadow),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('OTP Verification', style: TextStyle(color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    RichText(textAlign: TextAlign.center, text: TextSpan(
                      style: TextStyle(color: t.textMuted, fontSize: 13.5, height: 1.6),
                      children: [
                        const TextSpan(text: 'We will send you an  '),
                        TextSpan(text: 'One Time Password', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold)),
                        const TextSpan(text: '\nto this email address'),
                      ])),
                    const SizedBox(height: 24),
                    Align(alignment: Alignment.centerLeft,
                      child: Text('Enter Email Address', style: TextStyle(color: t.textMuted, fontSize: 13.5))),
                    const SizedBox(height: 8),
                    // ✅ FIX: حقل Email بدل الموبايل
                    _ThemedTextField(theme: t, controller: _emailCtrl),
                    const SizedBox(height: 20),
                    // ✅ بقى بيكلم الباك
                    _AnimatedButton(
                      label: 'Generate OTP',
                      loading: _loading,
                      onTap: _generateOtp,
                    ),
                    const SizedBox(height: 18),
                    Column(children: [
                      Text("Don't Have An Account?", style: TextStyle(color: t.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SelectRole()), (r) => false),
                        child: const Text('Register', style: TextStyle(color: Color(0xFF00D5BE), fontSize: 14, fontWeight: FontWeight.w600))),
                    ]),
                  ]),
                )))),
              const Spacer(flex: 1),
            ])))),
        )),
    );
  }

  List<Widget> _buildDots() {
    final positions = [
      {'top': 36.0, 'left': 18.0}, {'top': 22.0, 'left': 36.0},
      {'top': 36.0, 'right': 18.0}, {'top': 22.0, 'right': 36.0},
      {'bottom': 36.0, 'left': 22.0}, {'bottom': 22.0, 'left': 40.0},
      {'bottom': 36.0, 'right': 22.0}, {'bottom': 22.0, 'right': 40.0},
    ];
    return positions.asMap().entries.map((e) {
      final i = e.key; final pos = e.value;
      final color = i % 3 == 0 ? const Color(0xFFFF8904) : const Color(0xFF00D5BE);
      return Positioned(top: pos['top'], bottom: pos['bottom'], left: pos['left'], right: pos['right'],
        child: AnimatedBuilder(animation: _dotsCtrl, builder: (_, __) {
          final t = (_dotsCtrl.value + i * 0.13) % 1.0;
          final opacity = 0.28 + 0.6 * sin(t * pi);
          return Transform.scale(scale: 0.75 + 0.45 * sin(t * pi),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(
              color: color.withOpacity(opacity), borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: color.withOpacity(opacity * 0.6), blurRadius: 5)])));
        }));
    }).toList();
  }
}

class _ThemedTextField extends StatefulWidget {
  final AppTheme theme;
  final TextEditingController controller; // ✅
  const _ThemedTextField({required this.theme, required this.controller});
  @override State<_ThemedTextField> createState() => _ThemedTextFieldState();
}
class _ThemedTextFieldState extends State<_ThemedTextField> {
  final _focus = FocusNode();
  bool _focused = false;
  @override void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override void dispose() { _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedContainer(duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
        boxShadow: _focused ? [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.25), blurRadius: 14, spreadRadius: 1)] : []),
      child: TextField(
        focusNode: _focus,
        controller: widget.controller, // ✅
        // ✅ FIX: keyboard type للإيميل
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: t.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'you@example.com',
          hintStyle: TextStyle(color: t.textMuted, fontSize: 15),
          prefixIcon: Icon(Icons.email_outlined, color: _focused ? const Color(0xFF00D5BE) : t.textMuted, size: 20),
          filled: true, fillColor: t.fieldBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00D5BE), width: 1.2)))));
  }
}

class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading; // ✅
  const _AnimatedButton({required this.label, required this.onTap, this.loading = false});
  @override State<_AnimatedButton> createState() => _AnimatedButtonState();
}
class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120)); _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => _ctrl.forward(),
      onTapUp: widget.loading ? null : (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(animation: _scale, builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF00D5BE).withOpacity(0.85), const Color(0xFF00D3F2).withOpacity(0.85)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 6))]),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))));
  }
}