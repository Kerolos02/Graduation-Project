import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '/screen/driver/driver_otp_screen_v2.dart';
import '/screen/driver/driver_home_screen.dart';
import '/screen/trader/trader_home_screen.dart';
import '/screen/auth/select_role.dart';
import '/providers/theme_provider.dart';
import '/services/auth_service.dart'; // ✅ إضافة

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  bool _isDriver = true;

  final AuthService _authService = AuthService(); // ✅ إضافة

  late final AnimationController _pageCtrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final lastRole = prefs.getString('lastRole') ?? 'driver';
      if (mounted) setState(() => _isDriver = lastRole == 'driver');
    });
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _anims = List.generate(8, (i) {
      final start = (i * 0.09).clamp(0.0, 0.7);
      final end   = (start + 0.45).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _pageCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Widget _fade(int i, Widget child) {
    final a = _anims[i.clamp(0, _anims.length - 1)];
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) => Opacity(
        opacity: a.value,
        child: Transform.translate(
            offset: Offset(0, 22 * (1 - a.value)), child: child),
      ),
    );
  }

  // ✅ FIX: بنبعت email بدل phone عشان LoginDto في الباك بيطلب email
  Future<void> _handleLogin() async {
    // التحقق من الحقول
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _showError('من فضلك ادخل الإيميل والباسورد');
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      // حفظ بيانات اليوزر
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', _isDriver ? 'driver' : 'trader');
      await prefs.setString('lastRole', _isDriver ? 'driver' : 'trader');

      if (!mounted) return;

      // الانتقال للهوم
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) =>
                _isDriver ? const DriverHomeScreen() : const TraderHomeScreen()),
        (route) => false,
      );
    } else {
      // عرض رسالة الخطأ
      _showError(result['message'] ?? 'حدث خطأ، حاول مجدداً');
    }
  }

  // ✅ إضافة: عرض رسالة الخطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final isDark = t.isDark;

    return Scaffold(
      backgroundColor: t.loginBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height
                  - MediaQuery.of(context).padding.top
                  - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo ──
                _fade(0, Center(
                  child: Column(children: [
                    _TruckIcon(isDark: isDark),
                    const SizedBox(height: 16),
                    Text('TruckMate',
                        style: TextStyle(
                            color: t.textPrimary, fontSize: 23,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text('Smart Logistics App',
                        style: TextStyle(color: t.textMuted, fontSize: 13.5)),
                  ]),
                )),
                const SizedBox(height: 28),

                // ── Role Toggle ──
                _fade(1, Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(children: [
                    _roleTab('Driver', Icons.local_shipping_outlined, true, t),
                    _roleTab('Trader', Icons.store_outlined, false, t),
                  ]),
                )),
                const SizedBox(height: 28),

                // ── Email ──
                _fade(1, Text('Email',
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5,
                        fontWeight: FontWeight.w500))),
                const SizedBox(height: 9),
                _fade(2, _InputField(
                  controller: _emailCtrl,
                  hint: 'driver@truckmate.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  theme: t,
                )),
                const SizedBox(height: 20),

                // ── Password ──
                _fade(3, Text('Password',
                    style: TextStyle(color: t.textPrimary, fontSize: 13.5,
                        fontWeight: FontWeight.w500))),
                const SizedBox(height: 9),
                _fade(4, _InputField(
                  controller: _passwordCtrl,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  theme: t,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off_outlined
                               : Icons.visibility_outlined,
                      color: t.textMuted, size: 20),
                  ),
                )),

                // ── Forgot Password ──
                _fade(4, Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const DriverOtpScreenV2())),
                    child: Text('Forgot password?',
                        style: TextStyle(
                            color: AppTheme.primary, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                )),
                const SizedBox(height: 8),

                // ── Login Button ──
                _fade(5, _LoginButton(loading: _loading, onTap: _handleLogin)),
                const SizedBox(height: 20),

                // ── OR ──
                _fade(6, Row(children: [
                  Expanded(child: Container(height: 1, color: t.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ),
                  Expanded(child: Container(height: 1, color: t.border)),
                ])),
                const SizedBox(height: 20),

                // ── Create Account ──
                _fade(7, _CreateAccountButton(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectRole()),
                    (route) => false,
                  ),
                  theme: t,
                )),
                const SizedBox(height: 20),

                // ── Theme Toggle ──
                _fade(7, Center(
                  child: GestureDetector(
                    onTap: () => context.read<ThemeProvider>().toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.fieldBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isDark ? Icons.light_mode_outlined
                                 : Icons.dark_mode_outlined,
                          color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(isDark ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                                color: t.textMuted, fontSize: 13)),
                      ]),
                    ),
                  ),
                )),
                const SizedBox(height: 16),

                _fade(7, Center(
                  child: Text('© 2025 TruckMate',
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
                )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, bool isDriver, AppTheme t) {
    final active = isDriver ? _isDriver : !_isDriver;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isDriver = isDriver),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: active ? Colors.white : t.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : t.textMuted,
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ── Truck Icon ──
class _TruckIcon extends StatefulWidget {
  final bool isDark;
  const _TruckIcon({required this.isDark});
  @override
  State<_TruckIcon> createState() => _TruckIconState();
}

class _TruckIconState extends State<_TruckIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(widget.isDark ? 0.1 : 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.local_shipping_outlined,
            color: AppTheme.primary, size: 36),
      ),
    );
  }
}

// ── Input Field ──
class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final AppTheme theme;
  const _InputField({
    required this.controller, required this.hint,
    required this.icon, required this.theme,
    this.obscure = false, this.keyboardType, this.suffixIcon,
  });
  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: t.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? AppTheme.primary.withOpacity(0.5) : t.border,
          width: 1.4),
        boxShadow: _focused
            ? [BoxShadow(
                color: AppTheme.primary.withOpacity(0.07),
                blurRadius: 10, spreadRadius: 2)]
            : [],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          style: TextStyle(color: t.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: t.textMuted, fontSize: 13.5),
            prefixIcon: Icon(widget.icon,
                color: _focused ? AppTheme.primary : t.textMuted, size: 20),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ── Login Button ──
class _LoginButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _LoginButton({required this.loading, required this.onTap});
  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF009EA3), AppTheme.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Login',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ── Create Account Button ──
class _CreateAccountButton extends StatefulWidget {
  final VoidCallback onTap;
  final AppTheme theme;
  const _CreateAccountButton({required this.onTap, required this.theme});
  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.theme.border, width: 1.5),
          ),
          child: Center(
            child: Text('Create Account',
                style: TextStyle(
                    color: widget.theme.textPrimary, fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}