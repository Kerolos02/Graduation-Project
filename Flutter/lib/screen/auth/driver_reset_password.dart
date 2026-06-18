import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/auth_service.dart'; // ✅

// ✅ FIX: بيستقبل resetToken بدل phone+otp
// (ResetPasswordDto: required ["newPassword", "resetToken"])
class DriverResetPassword extends StatefulWidget {
  final String resetToken;
  const DriverResetPassword({
    super.key,
    this.resetToken = '',
  });
  @override
  State<DriverResetPassword> createState() => _DriverResetPasswordState();
}

class _DriverResetPasswordState extends State<DriverResetPassword> {
  bool _showPassword1 = false;
  bool _showPassword2 = false;
  bool _loading = false;

  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ✅ FIX: بيبعت للباك POST /register/reset-password بـ resetToken + newPassword
  Future<void> _resetPassword() async {
    if (_newPasswordCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_newPasswordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_newPasswordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.resetPassword(
      resetToken: widget.resetToken,
      newPassword: _newPasswordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully!'),
          backgroundColor: Color(0xFF00D5BE),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
    final bgColor    = t.isDark ? const Color(0xFF192C3D) : const Color(0xFFF4F7FA);
    final cardColor  = t.isDark ? const Color(0xFF0D1E2E) : Colors.white;
    final textColor  = t.isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF1A2A3A);
    final hintColor  = t.isDark ? Colors.white.withOpacity(0.25) : const Color(0xFF9BAAB8);
    final mutedColor = t.isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF7A95AA);
    final reqColor   = t.isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF9BAAB8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 375,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text('Reset Password', style: TextStyle(color: t.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Container(width: 120, height: 0.8, color: t.border),
                    const SizedBox(height: 14),
                    Text('Create your new password below', style: TextStyle(color: mutedColor, fontSize: 14)),
                    const SizedBox(height: 24),

                    // ── Shield Icon ──
                    SizedBox(width: 160, height: 160,
                      child: Stack(alignment: Alignment.center, children: [
                        CustomPaint(size: const Size(140, 140), painter: _DashedCirclePainter()),
                        Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle,
                          color: const Color(0xFF00D5BE).withOpacity(0.04),
                          boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.35), blurRadius: 40, spreadRadius: 8)])),
                        Icon(Icons.shield_outlined, color: const Color(0xFF00D5BE).withOpacity(0.9), size: 90,
                          shadows: [Shadow(color: const Color(0xFF00D5BE).withOpacity(0.8), blurRadius: 20)]),
                        Padding(padding: const EdgeInsets.only(top: 6),
                          child: Icon(Icons.check, color: const Color(0xFF00D5BE).withOpacity(0.9), size: 28,
                            shadows: [Shadow(color: const Color(0xFF00D5BE).withOpacity(0.8), blurRadius: 15)])),
                      ])),
                    const SizedBox(height: 30),

                    _PassField(
                      label: 'New Password', hint: 'Enter new password',
                      obscure: !_showPassword1, controller: _newPasswordCtrl,
                      cardColor: cardColor, textColor: textColor,
                      hintColor: hintColor, mutedColor: mutedColor,
                      onToggle: () => setState(() => _showPassword1 = !_showPassword1)),
                    const SizedBox(height: 16),
                    _PassField(
                      label: 'Rewrite New Password', hint: 'Confirm new password',
                      obscure: !_showPassword2, controller: _confirmCtrl,
                      cardColor: cardColor, textColor: textColor,
                      hintColor: hintColor, mutedColor: mutedColor,
                      onToggle: () => setState(() => _showPassword2 = !_showPassword2)),
                    const SizedBox(height: 16),

                    // ── Requirements box ──
                    Container(width: 343,
                      padding: const EdgeInsets.fromLTRB(16.8, 16.8, 16.8, 16.8),
                      decoration: BoxDecoration(color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.border, width: 0.8)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline, color: reqColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Password must include:', style: TextStyle(color: reqColor, fontSize: 13)),
                          const SizedBox(height: 6),
                          _req('Minimum 8 characters', reqColor),
                          _req('At least 1 uppercase letter', reqColor),
                          _req('At least 1 number', reqColor),
                          _req('At least 1 special character (!@#\$%)', reqColor),
                        ])),
                      ])),
                    const SizedBox(height: 40),

                    Container(width: 343, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009689), Color(0xFF00BBA7), Color(0xFF00B8DB)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _req(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Text('• ', style: TextStyle(color: color, fontSize: 13)),
      Text(text, style: TextStyle(color: color, fontSize: 12.5)),
    ]));
}

class _PassField extends StatelessWidget {
  final String label, hint;
  final bool obscure;
  final TextEditingController controller;
  final Color cardColor, textColor, hintColor, mutedColor;
  final VoidCallback onToggle;
  const _PassField({
    required this.label, required this.hint, required this.obscure,
    required this.controller, required this.cardColor, required this.textColor,
    required this.hintColor, required this.mutedColor, required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(width: double.infinity, height: 52,
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00D5BE).withOpacity(0.4), width: 1.4),
          boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.06), blurRadius: 10, spreadRadius: 1)]),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: hintColor, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF00D5BE).withOpacity(0.7), size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF00D5BE), size: 20),
              onPressed: onToggle)))),
    ]);
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00D5BE).withOpacity(0.4)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const dashWidth = 6.0, dashSpace = 8.0;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.14159 * radius;
    final dashCount = circumference / (dashWidth + dashSpace);
    final anglePerDash = 2 * 3.14159 / dashCount;
    for (int i = 0; i < dashCount.floor(); i++) {
      final startAngle = i * anglePerDash;
      final endAngle = startAngle + (anglePerDash * dashWidth / (dashWidth + dashSpace));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, endAngle - startAngle, false, paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}