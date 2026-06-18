import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screen/trader/TraderBusiness_Details_Screen.dart';

class TraderRegistrationScreen extends StatefulWidget {
  const TraderRegistrationScreen({super.key});
  @override
  State<TraderRegistrationScreen> createState() => _TraderRegistrationScreenState();
}

class _TraderRegistrationScreenState extends State<TraderRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _bgCtrl;

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _idCtrl      = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _idCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.regBg,
      body: Stack(
        children: [
          // animated bg - dark only
          if (t.isDark) Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(painter: _BgPainter(_bgCtrl.value)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Back button ──
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 45, height: 45,
                            decoration: BoxDecoration(
                              color: t.fieldBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.border),
                              boxShadow: t.cardShadow,
                            ),
                            child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text('Create Account',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Trader Registration',
                          style: TextStyle(fontSize: 16, color: t.textMuted)),
                      const SizedBox(height: 40),

                      // ── Stepper ──
                      _buildStepper(0, t),
                      const SizedBox(height: 40),

                      // ── Form card ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                          boxShadow: t.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Text('Personal Information',
                                style: TextStyle(fontSize: 18, color: t.textPrimary,
                                    fontWeight: FontWeight.bold))),
                            const SizedBox(height: 30),
                            _buildField(label: 'Full Name', hint: 'Enter your full name',
                                icon: Icons.person_outline, ctrl: _nameCtrl, t: t,
                                type: TextInputType.name,
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                            _buildField(label: 'Phone', hint: 'Enter your phone number',
                                icon: Icons.phone_outlined, ctrl: _phoneCtrl, t: t,
                                type: TextInputType.phone,
                                validator: (v) => (v?.length != 11) ? 'Must be 11 digits' : null),
                            _buildField(label: 'Email', hint: 'Enter your email',
                                icon: Icons.email_outlined, ctrl: _emailCtrl, t: t,
                                type: TextInputType.emailAddress,
                                validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null),
                            _buildField(label: 'National ID', hint: 'Enter national ID',
                                icon: Icons.badge_outlined, ctrl: _idCtrl, t: t,
                                type: TextInputType.number,
                                validator: (v) => (v?.length != 14) ? 'Must be 14 digits' : null),
                            _buildPassField(label: 'Password', hint: 'Enter password',
                                ctrl: _passCtrl, t: t, obscure: _obscurePass,
                                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
                            _buildPassField(label: 'Confirm Password', hint: 'Re-enter password',
                                ctrl: _confirmCtrl, t: t, obscure: _obscureConfirm,
                                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                validator: (v) => (v != _passCtrl.text) ? 'Passwords do not match' : null),
                            const SizedBox(height: 10),
                            _buildNextBtn(context, t),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('© 2025 TruckMate',
                          style: TextStyle(color: t.textMuted, fontSize: 14)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stepper ──
  Widget _buildStepper(int step, AppTheme t) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _stepDot(Icons.person_outline, step >= 0, t),
      _stepLine(step >= 1, t),
      _stepDot(Icons.store_outlined, step >= 1, t),
      _stepLine(step >= 2, t),
      _stepDot(Icons.check_circle_outline, step >= 2, t),
    ],
  );

  Widget _stepDot(IconData icon, bool active, AppTheme t) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppTheme.primaryLight.withOpacity(t.isDark ? 0.1 : 0.3) : t.fieldBg,
      border: Border.all(
        color: active ? AppTheme.primary : t.border, width: 1.5),
      boxShadow: active ? [BoxShadow(
          color: AppTheme.primary.withOpacity(0.25),
          blurRadius: 10, spreadRadius: 1)] : null,
    ),
    child: Icon(icon, color: active ? AppTheme.primary : t.textMuted, size: 24),
  );

  Widget _stepLine(bool active, AppTheme t) => Container(
    width: 45, height: 1.5,
    color: active ? AppTheme.primary : t.border,
  );

  // ── Text Field ──
  Widget _buildField({
    required String label, required String hint, required IconData icon,
    required TextEditingController ctrl, required AppTheme t,
    TextInputType? type, String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: t.textPrimary, fontSize: 14,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl, keyboardType: type, validator: validator,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          filled: true, fillColor: t.fieldBg,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        ),
      ),
    ]),
  );

  // ── Password Field ──
  Widget _buildPassField({
    required String label, required String hint,
    required TextEditingController ctrl, required AppTheme t,
    required bool obscure, required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: t.textPrimary, fontSize: 14,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl, obscureText: obscure, validator: validator,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: t.textMuted, size: 20),
          ),
          filled: true, fillColor: t.fieldBg,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        ),
      ),
    ]),
  );

  // ── Next Button ──
  Widget _buildNextBtn(BuildContext context, AppTheme t) => SizedBox(
    width: double.infinity, height: 55,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF009EA3), AppTheme.primary],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final prefs = await SharedPreferences.getInstance();
            final registered = prefs.getStringList('registeredEmails') ?? [];
            final email = _emailCtrl.text.trim().toLowerCase();
            final isDriver = registered.any((e) => e == '${email}:driver');
            if (isDriver) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('This email is already registered as a Driver!'),
                backgroundColor: Colors.redAccent));
              return;
            }
            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TraderBusinessDetailsScreen(
                fullName: _nameCtrl.text, phone: _phoneCtrl.text,
                email: _emailCtrl.text, nationalId: _idCtrl.text,
                password: _passCtrl.text,
              )));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Next',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ),
  );
}

// ── Background Painter (dark only) ──
class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    p.color = AppTheme.primary.withOpacity(0.2);
    canvas.drawCircle(Offset(
        size.width * 0.5 + math.sin(progress * 2 * math.pi) * 100,
        size.height * 0.2 + math.cos(progress * 2 * math.pi) * 50), 200, p);
    p.color = const Color(0xFF009EA3).withOpacity(0.15);
    canvas.drawCircle(Offset(
        size.width * 0.2 + math.cos(progress * 2 * math.pi) * 80,
        size.height * 0.8 + math.sin(progress * 2 * math.pi) * 100), 250, p);
  }
  @override bool shouldRepaint(_BgPainter o) => o.progress != progress;
}