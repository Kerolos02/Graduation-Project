import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/theme_provider.dart';
import '/screen/driver/license_details_screen.dart';
import '/services/auth_service.dart'; // ✅ إضافة

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _bgCtrl;
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl    = TextEditingController();
  bool _loading    = false; // ✅ إضافة

  final AuthService _authService = AuthService(); // ✅ إضافة

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
  }

  // ✅ الفنكشن دي اتغيرت بس
  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // بعت الـ OTP للموبايل
    final result = await _authService.sendOtp(
  phone: _phoneCtrl.text.trim(),
  email: _emailCtrl.text.trim(),
);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      context.read<UserProvider>().update(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nationalId: _idCtrl.text.trim(),
      );

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => LicenseDetailsScreen(
          fullName: _nameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          nationalId: _idCtrl.text,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'حدث خطأ، حاول مجدداً'),
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
      backgroundColor: t.regBg,
      body: Stack(children: [
        // ── animated background (dark only) ──
        if (t.isDark) ...[
          Positioned.fill(child: AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
                painter: _BgPainter(_bgCtrl.value)),
          )),
          Positioned.fill(child: Container(
              color: const Color(0xFF001A2C).withOpacity(0.75))),
        ],

        SafeArea(child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.isDark
                    ? Colors.white.withOpacity(0.01)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(45),
                border: t.isDark ? Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1.2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(theme: t),
                    ),
                    const SizedBox(height: 15),
                    Text('Create Account',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold,
                            color: t.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Driver Registration',
                        style: TextStyle(fontSize: 16, color: t.textMuted)),
                    const SizedBox(height: 40),
                    PersonalStepper(theme: t),
                    const SizedBox(height: 40),

                    // ── Form card ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 25),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: t.border),
                        boxShadow: t.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text('Personal Information',
                              style: TextStyle(
                                  fontSize: 18, color: t.textPrimary,
                                  fontWeight: FontWeight.bold))),
                          const SizedBox(height: 30),
                          RegInputField(
                            label: 'Full Name', hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            controller: _nameCtrl,
                            keyboardType: TextInputType.name,
                            theme: t,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter name' : null,
                          ),
                          RegInputField(
                            label: 'Phone', hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            theme: t,
                            validator: (v) => (v?.length != 11)
                                ? 'Must be 11 digits' : null,
                          ),
                          RegInputField(
                            label: 'Email', hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            theme: t,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Invalid email' : null,
                          ),
                          RegInputField(
                            label: 'National ID', hint: 'Enter national ID',
                            icon: Icons.badge_outlined,
                            controller: _idCtrl,
                            keyboardType: TextInputType.number,
                            theme: t,
                            validator: (v) => (v?.length != 14)
                                ? 'Must be 14 digits' : null,
                          ),
                          const SizedBox(height: 15),
                          // ✅ الزرار بقى بيشيل loading
                          _NextButton(
                            theme: t,
                            loading: _loading,
                            onTap: _onNext,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('© 2025 TruckMate',
                        style: TextStyle(color: t.textMuted, fontSize: 14)),
                    const SizedBox(height: 10),
                  ]),
                ),
              ),
            ),
          ),
        )),
      ]),
    );
  }
}

// ── Background painter (dark only) ──
class _BgPainter extends CustomPainter {
  final double p;
  _BgPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF00D1D1).withOpacity(0.25);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(
      size.width*0.5 + math.sin(p*2*math.pi)*100,
      size.height*0.2 + math.cos(p*2*math.pi)*50), 200, paint);
    paint.color = const Color(0xFF009EA3).withOpacity(0.2);
    canvas.drawCircle(Offset(
      size.width*0.2 + math.cos(p*2*math.pi)*80,
      size.height*0.8 + math.sin(p*2*math.pi)*100), 250, paint);
  }
  @override bool shouldRepaint(_) => true;
}

// ── Back Button ──
class _BackButton extends StatelessWidget {
  final AppTheme theme;
  const _BackButton({required this.theme});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: theme.isDark
              ? const Color(0xFF132D3E).withOpacity(0.6)
              : theme.fieldBg,
          shape: BoxShape.circle,
          border: Border.all(color: theme.border),
          boxShadow: theme.cardShadow,
        ),
        child: Icon(Icons.arrow_back,
            color: AppTheme.primary, size: 22),
      ),
    );
  }
}

// ── Stepper ──
class PersonalStepper extends StatelessWidget {
  final AppTheme theme;
  const PersonalStepper({super.key, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _step(Icons.person, true),
      _line(),
      _step(Icons.badge_outlined, false),
      _line(),
      _step(Icons.local_shipping, false),
    ]);
  }
  Widget _step(IconData icon, bool active) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? Colors.transparent : theme.fieldBg,
      border: Border.all(
        color: active ? AppTheme.primary : Colors.transparent,
        width: 1.5)),
    child: Icon(icon,
        color: active ? AppTheme.primary : theme.textMuted, size: 26));
  Widget _line() => Container(
      width: 45, height: 1.2, color: AppTheme.primary.withOpacity(0.2));
}

// ── Input Field ──
class RegInputField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final AppTheme theme;
  const RegInputField({
    super.key, required this.label, required this.hint,
    required this.icon, required this.controller,
    required this.theme, this.keyboardType, this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
            color: theme.textPrimary, fontSize: 15,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: theme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
            filled: true,
            fillColor: theme.fieldBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppTheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent)),
          ),
        ),
      ]),
    );
  }
}

// ── Next Button ✅ بقى بيشيل loading ──
class _NextButton extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onTap;
  final bool loading;
  const _NextButton({required this.theme, required this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF009EA3), AppTheme.primary]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
          child: loading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('Next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Colors.white)),
        ),
      ),
    );
  }
}

// ── Legacy exports ──
class CustomGlowBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CustomGlowBackButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: t.isDark
              ? const Color(0xFF132D3E).withOpacity(0.6)
              : t.fieldBg,
          shape: BoxShape.circle,
          border: Border.all(color: t.border),
          boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 15)],
        ),
        child: const Icon(Icons.arrow_back, color: AppTheme.primary, size: 22),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const CustomInputField({
    super.key, required this.label, required this.hint,
    required this.icon, required this.controller,
    this.keyboardType, this.validator,
  });
  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return RegInputField(
      label: label, hint: hint, icon: icon,
      controller: controller, keyboardType: keyboardType,
      validator: validator, theme: t,
    );
  }
}