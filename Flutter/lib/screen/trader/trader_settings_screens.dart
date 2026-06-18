import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TraderAdvancedSettingsScreen + TraderNotifPreferencesScreen
//  Animations ported 1:1 from DriverAdvancedSettingsScreen:
//  • Page entry:       fade + slide y(0.04→0) easeOut 400ms
//  • Profile card:     elasticOut scale 0.93→1, delay 150ms
//  • Section cards:    stagger fade+slide y(0.3→0) delay 200+i*100ms
//  • Delete button:    last section stagger entry
//  • Save button:      elasticOut scale + shimmer sweep 2s loop
//  • whileTap scale:   _PressScale 0.92 on every tappable
//  • _AnimatedDialog:  easeOutBack scale 0.85→1 + fade on dialog
//  • Spring curve:     physics-based spring same as driver
// ══════════════════════════════════════════════════════════════════════════════

// ── Spring curve ──────────────────────────────────────────────────────────────
class _SpringCurve extends Curve {
  final double stiffness, damping, mass;
  const _SpringCurve(
      {required this.stiffness, required this.damping, required this.mass});

  @override
  double transformInternal(double t) {
    final omega0 = math.sqrt(stiffness / mass);
    final zeta   = damping / (2 * math.sqrt(stiffness * mass));
    if (zeta < 1) {
      final omegaD = omega0 * math.sqrt(1 - zeta * zeta);
      return 1 -
          math.exp(-zeta * omega0 * t) *
              (math.cos(omegaD * t) +
                  (zeta * omega0 / omegaD) * math.sin(omegaD * t));
    }
    return 1 - math.exp(-omega0 * t) * (1 + omega0 * t);
  }
}

// ── Press scale (same as driver _PressScale) ──────────────────────────────────
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _PressScale(
      {required this.child, required this.onTap, this.scale = 0.92});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _anim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _anim, child: widget.child),
      );
}

// ── Animated dialog (same as driver) ─────────────────────────────────────────
class _AnimatedDialog extends StatefulWidget {
  final Color kCard, kText, kMuted;
  final String title, content, confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  const _AnimatedDialog({
    required this.kCard, required this.kText, required this.kMuted,
    required this.title, required this.content,
    required this.confirmLabel, required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<_AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<_AnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: AlertDialog(
            backgroundColor: widget.kCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(widget.title,
                style: TextStyle(
                    color: widget.kText, fontWeight: FontWeight.bold)),
            content: Text(widget.content,
                style: TextStyle(color: widget.kMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: widget.kMuted))),
              TextButton(
                onPressed: widget.onConfirm,
                child: Text(widget.confirmLabel,
                    style: TextStyle(
                        color: widget.confirmColor,
                        fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  TraderAdvancedSettingsScreen
// ══════════════════════════════════════════════════════════════════════════════
class TraderAdvancedSettingsScreen extends StatefulWidget {
  const TraderAdvancedSettingsScreen({super.key});

  @override
  State<TraderAdvancedSettingsScreen> createState() =>
      _TraderAdvancedSettingsScreenState();
}

class _TraderAdvancedSettingsScreenState
    extends State<TraderAdvancedSettingsScreen> with TickerProviderStateMixin {

  late AnimationController _pageCtrl;
  late AnimationController _cardCtrl;
  final List<AnimationController> _sectionCtrls  = [];
  final List<Animation<double>>   _sectionFades  = [];
  final List<Animation<Offset>>   _sectionSlides = [];

  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();

    // ✅ تحميل بيانات البروفايل من الباك إند
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraderProvider>().loadProfile();
    });

    // Page fade+slide (same as driver AdvancedSettings)
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    // Profile card elasticOut scale (same as driver)
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardScale = Tween<double>(begin: 0.93, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _cardCtrl.forward(); });

    // 4 sections stagger (same as driver)
    for (int i = 0; i < 4; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400));
      _sectionCtrls.add(c);
      _sectionFades.add(
          CurvedAnimation(parent: c, curve: Curves.easeOut));
      _sectionSlides.add(
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 200 + i * 100),
          () { if (mounted) c.forward(); });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _cardCtrl.dispose();
    for (final c in _sectionCtrls) c.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    final fade  = i < _sectionFades.length  ? _sectionFades[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _sectionSlides.length ? _sectionSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final trader   = context.watch<TraderProvider>();
    final name     = trader.fullName.isNotEmpty ? trader.fullName : 'Trader';
    final initials = trader.initials;

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00D5BE);
    const kRed    = Color(0xFFFF476D);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Header ──
                Row(children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: kTeal, size: 16)),
                  ),
                  const SizedBox(width: 14),
                  Text('Advanced Settings',
                      style: TextStyle(
                          color: kText, fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 24),

                // ── Profile card: elasticOut scale ──
                ScaleTransition(
                  scale: _cardScale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorder),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: Colors.black.withOpacity(0.04),
                              blurRadius: 10, offset: const Offset(0, 4))
                        ]),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kTeal, width: 2),
                          color: isDark
                              ? const Color(0xFF1A3550)
                              : const Color(0xFFE8F5F4),
                        ),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: kTeal, fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name,
                            style: TextStyle(
                                color: kText, fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: kTeal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kTeal.withOpacity(0.3))),
                          child: const Text('Trader',
                              style: TextStyle(
                                  color: kTeal, fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 0: Account Security ──
                _animated(0, _section('ACCOUNT SECURITY', [
                  _SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      isDark: isDark, kCard: kCard, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
                      onTap: () => _showChangePasswordDialog(
                          context, isDark, kCard, kText, kMuted, kBorder)),
                  _SettingsRow(
                      icon: Icons.mail_outline_rounded,
                      title: 'Update Email / Phone',
                      subtitle: 'Manage your contact information',
                      isDark: isDark, kCard: kCard, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
                      onTap: () => _showUpdateContactDialog(
                          context, isDark, kCard, kText, kMuted, kBorder),
                      isLast: true),
                ], isDark, kCard, kBorder, kMuted)),

                // ── Section 1: Preferences ──
                _animated(1, _section('PREFERENCES', [
                  _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Preferences',
                      subtitle: 'Control how and when you receive notifications',
                      isDark: isDark, kCard: kCard, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const TraderNotifPreferencesScreen())),
                      isLast: true),
                ], isDark, kCard, kBorder, kMuted)),

                // ── Section 2: Privacy & Legal ──
                _animated(2, _section('PRIVACY & LEGAL', [
                  _SettingsRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Manage privacy and data permissions',
                      isDark: isDark, kCard: kCard, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
                      onTap: () {}),
                  _SettingsRow(
                      icon: Icons.description_outlined,
                      title: 'Terms & Policies',
                      subtitle: 'View terms, privacy policy, and agreements',
                      isDark: isDark, kCard: kCard, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
                      onTap: () {}, isLast: true),
                ], isDark, kCard, kBorder, kMuted)),

                // ── Section 3: Delete account ──
                _animated(3, _PressScale(
                  onTap: () => _showDeleteAccountDialog(
                      context, isDark, kCard, kText, kMuted, kBorder),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kRed.withOpacity(0.3))),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: kRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: kRed, size: 20)),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delete Account',
                              style: TextStyle(
                                  color: kRed, fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Permanently remove your account and data',
                              style: TextStyle(color: kRed, fontSize: 12)),
                        ],
                      )),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: kRed, size: 14),
                    ]),
                  ),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> items, bool isDark,
      Color kCard, Color kBorder, Color kMuted) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              color: kMuted, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Container(
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.03),
                    blurRadius: 8, offset: const Offset(0, 2))
              ]),
          child: Column(children: items)),
      const SizedBox(height: 24),
    ]);
  }

  // ══════════════════════════════════════
  //  CHANGE PASSWORD DIALOG
  //  PATCH /api/trader/settings/change-password
  // ══════════════════════════════════════
  void _showChangePasswordDialog(BuildContext context, bool isDark,
      Color kCard, Color kText, Color kMuted, Color kBorder) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSaving = false;
    const kTeal = Color(0xFF00D5BE);
    const kRed  = Color(0xFFFF476D);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Password',
              style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: kMuted),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: kMuted)),
            ),
            TextButton(
              onPressed: isSaving ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                setStateDialog(() => isSaving = true);
                final ok = await context.read<TraderProvider>().changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                  confirmNewPassword: confirmCtrl.text,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Password changed successfully'
                      : (context.read<TraderProvider>().error ?? 'Failed to change password')),
                  backgroundColor: ok ? kTeal : kRed,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                  : const Text('Save', style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  //  UPDATE EMAIL / PHONE DIALOG
  //  PATCH /api/trader/settings/update-contact
  // ══════════════════════════════════════
  void _showUpdateContactDialog(BuildContext context, bool isDark,
      Color kCard, Color kText, Color kMuted, Color kBorder) {
    final trader = context.read<TraderProvider>();
    final emailCtrl = TextEditingController(text: trader.email);
    final phoneCtrl = TextEditingController(text: trader.phoneNumber);
    bool isSaving = false;
    const kTeal = Color(0xFF00D5BE);
    const kRed  = Color(0xFFFF476D);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Update Contact Info',
              style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: kMuted)),
            ),
            TextButton(
              onPressed: isSaving ? null : () async {
                setStateDialog(() => isSaving = true);
                final ok = await context.read<TraderProvider>().updateContact(
                  email: emailCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Contact info updated successfully'
                      : (context.read<TraderProvider>().error ?? 'Failed to update contact info')),
                  backgroundColor: ok ? kTeal : kRed,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                  : const Text('Save', style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  //  DELETE ACCOUNT DIALOG
  //  DELETE /api/trader/settings/account
  // ══════════════════════════════════════
  void _showDeleteAccountDialog(BuildContext context, bool isDark,
      Color kCard, Color kText, Color kMuted, Color kBorder) {
    final passwordCtrl = TextEditingController();
    final confirmCtrl  = TextEditingController();
    bool isSaving = false;
    const kRed = Color(0xFFFF476D);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Account',
              style: const TextStyle(color: kRed, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Are you sure? This action cannot be undone.',
                style: TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                labelStyle: TextStyle(color: kMuted),
                border: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: kMuted)),
            ),
            TextButton(
              onPressed: isSaving ? null : () async {
                setStateDialog(() => isSaving = true);
                final ok = await context.read<TraderProvider>().deleteAccount(
                  password: passwordCtrl.text,
                  confirmationPhrase: confirmCtrl.text,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Account scheduled for deletion'),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                  // ✅ تسجيل خروج المستخدم بعد جدولة الحذف
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.remove('role');
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.read<TraderProvider>().error ?? 'Failed to delete account'),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kRed))
                  : const Text('Delete', style: TextStyle(color: kRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TraderNotifPreferencesScreen — مربوطة بالباك إند
//  GET/PATCH /api/trader/settings/notifications
// ══════════════════════════════════════════════════════════════════════════════
class TraderNotifPreferencesScreen extends StatefulWidget {
  const TraderNotifPreferencesScreen({super.key});

  @override
  State<TraderNotifPreferencesScreen> createState() =>
      _TraderNotifPreferencesScreenState();
}

class _TraderNotifPreferencesScreenState
    extends State<TraderNotifPreferencesScreen> with TickerProviderStateMixin {

  // ── 13 toggle مطابقين لأسماء حقول TraderNotificationPreferencesResponseDto ──
  bool _shipmentCreatedConfirmation = true;
  bool _shipmentAssignedToDriver    = true;
  bool _shipmentPickedUp            = true;
  bool _shipmentInTransit           = true;
  bool _shipmentDelivered           = true;
  bool _shipmentDelayed             = true;
  bool _shipmentCancelled           = true;

  bool _invoiceGenerated  = true;
  bool _paymentConfirmed  = true;
  bool _paymentFailed     = true;

  bool _pushNotificationsEnabled  = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled   = false;

  bool _isLoading = true;
  bool _isSaving  = false;

  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  final List<AnimationController> _sectionCtrls  = [];
  final List<Animation<double>>   _sectionFades  = [];
  final List<Animation<Offset>>   _sectionSlides = [];

  late AnimationController _saveBtnCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _saveFade, _saveScale, _shimmerX;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    // 3 sections stagger
    final delays = [100, 250, 400];
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 450));
      _sectionCtrls.add(c);
      _sectionFades.add(
          CurvedAnimation(parent: c, curve: Curves.easeOut));
      _sectionSlides.add(
          Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: delays[i]),
          () { if (mounted) c.forward(); });
    }

    _saveBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _saveFade  = CurvedAnimation(parent: _saveBtnCtrl, curve: Curves.easeOut);
    _saveScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _saveBtnCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 600),
        () { if (mounted) _saveBtnCtrl.forward(); });

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(_shimmerCtrl);

    // ✅ تحميل الإعدادات من الباك إند
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _sectionCtrls) c.dispose();
    _saveBtnCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  LOAD FROM BACKEND
  // ══════════════════════════════════════
  Future<void> _loadPreferences() async {
    final provider = context.read<TraderProvider>();
    await provider.loadNotificationSettings();
    final data = provider.notificationSettings;

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _shipmentCreatedConfirmation = data['shipmentCreatedConfirmation'] ?? true;
        _shipmentAssignedToDriver    = data['shipmentAssignedToDriver'] ?? true;
        _shipmentPickedUp            = data['shipmentPickedUp'] ?? true;
        _shipmentInTransit           = data['shipmentInTransit'] ?? true;
        _shipmentDelivered           = data['shipmentDelivered'] ?? true;
        _shipmentDelayed             = data['shipmentDelayed'] ?? true;
        _shipmentCancelled           = data['shipmentCancelled'] ?? true;

        _invoiceGenerated = data['invoiceGenerated'] ?? true;
        _paymentConfirmed = data['paymentConfirmed'] ?? true;
        _paymentFailed    = data['paymentFailed'] ?? true;

        _pushNotificationsEnabled  = data['pushNotificationsEnabled'] ?? true;
        _emailNotificationsEnabled = data['emailNotificationsEnabled'] ?? true;
        _smsNotificationsEnabled   = data['smsNotificationsEnabled'] ?? false;

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error!),
          backgroundColor: const Color(0xFFFF476D),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ══════════════════════════════════════
  //  SAVE TO BACKEND
  // ══════════════════════════════════════
  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    final settings = {
      'shipmentCreatedConfirmation': _shipmentCreatedConfirmation,
      'shipmentAssignedToDriver':    _shipmentAssignedToDriver,
      'shipmentPickedUp':            _shipmentPickedUp,
      'shipmentInTransit':           _shipmentInTransit,
      'shipmentDelivered':           _shipmentDelivered,
      'shipmentDelayed':             _shipmentDelayed,
      'shipmentCancelled':           _shipmentCancelled,
      'invoiceGenerated': _invoiceGenerated,
      'paymentConfirmed': _paymentConfirmed,
      'paymentFailed':    _paymentFailed,
      'pushNotificationsEnabled':  _pushNotificationsEnabled,
      'emailNotificationsEnabled': _emailNotificationsEnabled,
      'smsNotificationsEnabled':   _smsNotificationsEnabled,
    };

    final ok = await context.read<TraderProvider>().saveNotificationSettings(settings);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Preferences saved!'),
        backgroundColor: const Color(0xFF00D5BE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    } else {
      final err = context.read<TraderProvider>().error ?? 'Failed to save preferences';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: const Color(0xFFFF476D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Widget _animated(int i, Widget child) {
    final fade  = i < _sectionFades.length  ? _sectionFades[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _sectionSlides.length ? _sectionSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final trader = context.watch<TraderProvider>();
    final name   = trader.fullName.isNotEmpty ? trader.fullName : 'Trader';
    final initials = trader.initials;

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00D5BE);

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: Column(children: [

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: kTeal, size: 16)),
                  ),
                  const SizedBox(width: 14),
                  Text('Notification Preferences',
                      style: TextStyle(
                          color: kText, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
              ),

              if (_isLoading)
                Expanded(child: Center(
                    child: const CircularProgressIndicator(color: kTeal)))
              else
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder)),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kTeal.withOpacity(0.15),
                            border: Border.all(color: kTeal, width: 1.5)),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: kTeal, fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name,
                            style: TextStyle(
                                color: kText, fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: kTeal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: kTeal.withOpacity(0.3))),
                          child: const Text('Trader',
                              style: TextStyle(
                                  color: kTeal, fontSize: 11)),
                        ),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 22),

                  // SHIPMENT UPDATES (7)
                  _animated(0, _prefSection('SHIPMENT UPDATES', [
                    _prefRow(Icons.check_circle_outline, 'Shipment Created Confirmation',
                        _shipmentCreatedConfirmation, (v) => setState(() => _shipmentCreatedConfirmation = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.person_outline, 'Shipment Assigned To Driver',
                        _shipmentAssignedToDriver, (v) => setState(() => _shipmentAssignedToDriver = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.inventory_2_outlined, 'Shipment Picked Up',
                        _shipmentPickedUp, (v) => setState(() => _shipmentPickedUp = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.local_shipping_outlined, 'Shipment In Transit',
                        _shipmentInTransit, (v) => setState(() => _shipmentInTransit = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.done_all_rounded, 'Shipment Delivered',
                        _shipmentDelivered, (v) => setState(() => _shipmentDelivered = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.schedule_rounded, 'Shipment Delayed',
                        _shipmentDelayed, (v) => setState(() => _shipmentDelayed = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.cancel_outlined, 'Shipment Cancelled',
                        _shipmentCancelled, (v) => setState(() => _shipmentCancelled = v),
                        isDark, kCard, kText, kBorder, kTeal, isLast: true),
                  ], isDark, kCard, kBorder, kMuted)),

                  // BILLING & PAYMENTS (3)
                  _animated(1, _prefSection('BILLING & PAYMENTS', [
                    _prefRow(Icons.description_outlined, 'Invoice Generated',
                        _invoiceGenerated, (v) => setState(() => _invoiceGenerated = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.check_circle_outline, 'Payment Confirmed',
                        _paymentConfirmed, (v) => setState(() => _paymentConfirmed = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.error_outline_rounded, 'Payment Failed',
                        _paymentFailed, (v) => setState(() => _paymentFailed = v),
                        isDark, kCard, kText, kBorder, kTeal, isLast: true),
                  ], isDark, kCard, kBorder, kMuted)),

                  // DELIVERY CHANNELS (3)
                  _animated(2, _prefSection('DELIVERY CHANNELS', [
                    _prefRow(Icons.notifications_none_rounded, 'Push Notifications',
                        _pushNotificationsEnabled, (v) => setState(() => _pushNotificationsEnabled = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.mail_outline_rounded, 'Email Notifications',
                        _emailNotificationsEnabled, (v) => setState(() => _emailNotificationsEnabled = v),
                        isDark, kCard, kText, kBorder, kTeal),
                    _prefRow(Icons.sms_outlined, 'SMS Notifications',
                        _smsNotificationsEnabled, (v) => setState(() => _smsNotificationsEnabled = v),
                        isDark, kCard, kText, kBorder, kTeal, isLast: true),
                  ], isDark, kCard, kBorder, kMuted)),
                ]),
              )),
            ]),
          ),
        ),
      ),

      // ── Save button ──
      bottomNavigationBar: _isLoading ? null : ScaleTransition(
        scale: _saveScale,
        child: FadeTransition(
          opacity: _saveFade,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA),
              border: Border(top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE2EAF0))),
            ),
            child: _PressScale(
              onTap: _isSaving ? () {} : _savePreferences,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF009EA3), Color(0xFF00D5BE)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF00D5BE).withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedBuilder(
                      animation: _shimmerX,
                      builder: (_, __) => Positioned(
                        left: _shimmerX.value - 40, top: 0, bottom: 0,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),
                    _isSaving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Preferences',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _prefSection(String title, List<Widget> items, bool isDark,
      Color kCard, Color kBorder, Color kMuted) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              color: kMuted, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Container(
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder)),
          child: Column(children: items)),
      const SizedBox(height: 22),
    ]);
  }

  Widget _prefRow(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged, bool isDark, Color kCard,
      Color kText, Color kBorder, Color kTeal,
      {bool isLast = false}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: kTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kTeal, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(title,
              style: TextStyle(
                  color: kText, fontSize: 13,
                  fontWeight: FontWeight.w500))),
          Switch(
            value: value, onChanged: onChanged,
            activeColor: kTeal,
            activeTrackColor: kTeal.withOpacity(0.3),
            inactiveThumbColor: isDark ? Colors.grey[600] : Colors.grey[400],
            inactiveTrackColor: isDark
                ? const Color(0xFF1A3550) : Colors.grey[200],
          ),
        ]),
      ),
      if (!isLast) Divider(height: 1, color: kBorder, indent: 62),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Shared: _SettingsRow
// ══════════════════════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isLast, isDark;
  final Color kCard, kText, kMuted, kBorder, kTeal;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon, required this.title, required this.subtitle,
    required this.isDark, required this.kCard, required this.kText,
    required this.kMuted, required this.kBorder, required this.kTeal,
    this.isLast = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    _PressScale(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: kTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kTeal, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: kText, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, color: kMuted, size: 14),
        ]),
      ),
    ),
    if (!isLast) Divider(height: 1, color: kBorder, indent: 70),
  ]);
}