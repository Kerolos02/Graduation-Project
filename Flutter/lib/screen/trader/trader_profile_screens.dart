import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';
import '/providers/trader_provider.dart'; // ✅ إضافة
import '/services/auth_service.dart'; // ✅ إضافة
import '/screen/trader/payment_screens.dart';
import '/screen/trader/trader_wallet_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  TRADER PROFILE SCREENS — trader_profile_screens.dart
//  ✅ Dark/Light theme — كل الألوان بتتغير صح مع TraderTheme
//  ✅ Animations — محافظ عليها بالظبط من الجيتهاب
//  ✅ Payment Methods → PaymentMethodsListScreen
//  ✅ My Wallet → TraderWalletScreen
//  ✅ View All في Shipments → /trader_my_shipments
//  ✅ بيانات البروفايل من TraderProvider (GET /api/trader/settings/profile)
//  ✅ Logout الحقيقي عبر AuthService().logout()
// ═══════════════════════════════════════════════════════════════════════════

// ─── Theme helpers ─────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF00D5BE);
const Color _kRed     = Color(0xFFFF476D);

Color _kBg(bool d)     => d ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
Color _kCard(bool d)   => d ? const Color(0xFF152232) : Colors.white;
Color _kText(bool d)   => d ? Colors.white : const Color(0xFF1A2A3A);
Color _kMuted(bool d)  => d ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
Color _kBorder(bool d) => d ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
Color _kDeep(bool d)   => d ? const Color(0xFF0A1828) : const Color(0xFFF0F4F8);

// ══════════════════════════════════════════════════════════════════════════
//  _SpringCurve
// ══════════════════════════════════════════════════════════════════════════
class _SpringCurve extends Curve {
  final double stiffness, damping, mass;
  const _SpringCurve({
    required this.stiffness,
    required this.damping,
    required this.mass,
  });

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
    } else {
      return 1 - math.exp(-omega0 * t) * (1 + omega0 * t);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _PressScale
// ══════════════════════════════════════════════════════════════════════════
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _PressScale({required this.child, required this.onTap, this.scale = 0.97});

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
        onTapDown:   (_) => _ctrl.forward(),
        onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: ()  => _ctrl.reverse(),
        child: ScaleTransition(scale: _anim, child: widget.child),
      );
}

// ══════════════════════════════════════════════════════════════════════════
//  Animated Avatar Ring
// ══════════════════════════════════════════════════════════════════════════
class _AnimatedAvatarRing extends StatelessWidget {
  final String initials;
  final Animation<double> ringAngle;
  final bool isDark;

  const _AnimatedAvatarRing({
    required this.initials,
    required this.ringAngle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: Stack(alignment: Alignment.center, children: [
        // Rotating sweep gradient ring
        AnimatedBuilder(
          animation: ringAngle,
          builder: (_, __) => Transform.rotate(
            angle: ringAngle.value,
            child: Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  Color(0xFF009689),
                  Color(0xFF00BBA7),
                  Color(0xFF00B8DB),
                  Color(0xFF009689),
                ]),
              ),
            ),
          ),
        ),
        // Dark/light gap ring
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF192C3D) : Colors.white,
          ),
          child: Center(
            child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFE52EE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26),
              ),
            ),
          ),
        ),
        // Online badge
        Positioned(
          bottom: 2, right: 2,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? const Color(0xFF0D1F2D) : Colors.white,
                  width: 2),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TRADER PROFILE SCREEN  (ProfileMenuScreen)
// ══════════════════════════════════════════════════════════════════════════
class TraderProfileScreen extends StatefulWidget {
  const TraderProfileScreen({super.key});

  @override
  State<TraderProfileScreen> createState() => _TraderProfileScreenState();
}

class _TraderProfileScreenState extends State<TraderProfileScreen>
    with TickerProviderStateMixin {

  late AnimationController _pageCtrl;
  late AnimationController _avatarCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _headerCtrl;
  late AnimationController _statsCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _btnCtrl;
  final List<AnimationController> _itemCtrls = [];

  late Animation<double> _pageFade;
  late Animation<Offset>  _pageSlide;
  late Animation<double> _avatarScale;
  late Animation<double> _ringAngle;
  late Animation<double> _nameFade;
  late Animation<Offset>  _nameSlide;
  late Animation<double> _roleFade;
  late Animation<Offset>  _roleSlide;
  late Animation<double> _btnScale;

  final List<Animation<double>> _statsFade  = [];
  final List<Animation<Offset>>  _statsSlide = [];
  final List<Animation<double>> _itemFades  = [];
  final List<Animation<Offset>>  _itemSlides = [];

  late Animation<int> _totalCount;
  late Animation<int> _activeCount;
  late Animation<int> _completedCount;
  late Animation<int> _driversCount;

  static const int _optionCount = 9;

  @override
  void initState() {
    super.initState();

    // Page fade + slide
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550))..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    // Avatar elasticOut bounce
    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _avatarCtrl.forward(); });

    // Rotating ring
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))..repeat();
    _ringAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ringCtrl);

    // Header name/role staggered
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _nameFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _roleFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _roleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _headerCtrl.forward(); });

    // Stats row stagger
    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    for (int i = 0; i < 4; i++) {
      final start = i * 0.18;
      final end   = (start + 0.5).clamp(0.0, 1.0);
      _statsFade.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _statsCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _statsSlide.add(
          Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(CurvedAnimation(parent: _statsCtrl,
                  curve: Interval(start, end, curve: Curves.easeOut))));
    }
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _statsCtrl.forward(); });

    // Counter animation
    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _totalCount     = IntTween(begin: 0, end: 70).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _activeCount    = IntTween(begin: 0, end: 12).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _completedCount = IntTween(begin: 0, end: 50).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _driversCount   = IntTween(begin: 0, end: 45).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _counterCtrl.forward(); });

    // Back button elasticOut
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _btnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut));

    // Option rows stagger
    for (int i = 0; i < _optionCount; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350));
      _itemCtrls.add(c);
      _itemFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _itemSlides.add(
          Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 500 + i * 60),
          () { if (mounted) c.forward(); });
    }

    // ✅ جيب بيانات البروفايل من الباك
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraderProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _avatarCtrl.dispose();
    _ringCtrl.dispose();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _counterCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _itemCtrls) c.dispose();
    super.dispose();
  }

  Widget _animatedItem(int i, Widget child) {
    final fade  = i < _itemFades.length  ? _itemFades[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _itemSlides.length ? _itemSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final user     = context.watch<UserProvider>();
    final trader   = context.watch<TraderProvider>(); // ✅

    // ✅ بيانات من الباك (TraderProvider) مع fallback على UserProvider ثم القيم الثابتة
    final name = trader.fullName.isNotEmpty
        ? trader.fullName
        : (user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed');
    final email = trader.email.isNotEmpty
        ? trader.email
        : (user.email.isNotEmpty ? user.email : 'Trader@truckmate.com');
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'TM';

    final kBg     = _kBg(isDark);
    final kCard   = _kCard(isDark);
    final kText   = _kText(isDark);
    final kMuted  = _kMuted(isDark);
    final kBorder = _kBorder(isDark);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ScaleTransition(
          scale: _btnScale,
          child: _PressScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kCard,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kPrimary, size: 16),
            ),
          ),
        ),
        title: FadeTransition(
          opacity: _nameFade,
          child: Text('Profile',
              style: TextStyle(
                  color: kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: Stack(children: [
            // Background radial glow
            Positioned(
              top: 120, left: -8,
              child: Container(
                width: 369, height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  gradient: RadialGradient(colors: [
                    _kPrimary.withOpacity(isDark ? 0.07 : 0.04),
                    const Color(0xFF00D3F2).withOpacity(isDark ? 0.04 : 0.02),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            RefreshIndicator(
              color: _kPrimary,
              onRefresh: () => context.read<TraderProvider>().loadProfile(), // ✅
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                const SizedBox(height: 8),

                // Animated Avatar
                ScaleTransition(
                  scale: _avatarScale,
                  child: _AnimatedAvatarRing(
                      initials: initials,
                      ringAngle: _ringAngle,
                      isDark: isDark),
                ),
                const SizedBox(height: 12),

                // Name
                FadeTransition(
                  opacity: _nameFade,
                  child: SlideTransition(
                    position: _nameSlide,
                    child: Text(name,
                        style: TextStyle(
                            color: kText,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                FadeTransition(
                  opacity: _roleFade,
                  child: SlideTransition(
                    position: _roleSlide,
                    child: Text(email,
                        style: TextStyle(color: kMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 6),

                // Trader badge
                FadeTransition(
                  opacity: _roleFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kPrimary.withOpacity(0.3)),
                    ),
                    child: const Text('Trader',
                        style: TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row with counter
                AnimatedBuilder(
                  animation: _counterCtrl,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(0, Icons.inventory_2_outlined,
                            '5', 'Total Ships', kMuted, isDark),
                        _buildStatItem(1, Icons.access_time,
                            '2', 'Active', kMuted, isDark),
                        _buildStatItem(2, Icons.check_circle_outline,
                            '3', 'Completed', kMuted, isDark),
                        _buildStatItem(3, Icons.people_outline,
                            '5', 'Drivers', kMuted, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Menu items ──
                // 0: Your profile
                _animatedItem(0, _MenuItem(
                  icon: Icons.person_outline,
                  title: 'Your profile',
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/trader_details'),
                )),

                // ✅ FIX: Payment Methods → PaymentMethodsListScreen
                _animatedItem(1, _MenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentMethodsListScreen()),
                  ),
                )),

                // 2: Dark Mode toggle
                _animatedItem(2, _DarkModeItem(isDark: isDark)),

                // 3: Language
                _animatedItem(3, _MenuItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  isDark: isDark,
                  onTap: () {},
                )),

                // ✅ FIX: My Wallet → TraderWalletScreen
                _animatedItem(4, _MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'My Wallet',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TraderWalletScreen()),
                  ),
                )),

                // 5: Invite Friends
                _animatedItem(5, _MenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Invite Friends',
                  isDark: isDark,
                  onTap: () {},
                )),

                // 6: Settings
                _animatedItem(6, _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(
                      context, '/trader_advanced_settings'),
                )),

                // 7: Support
                _animatedItem(7, _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Support Setting',
                  isDark: isDark,
                  onTap: () {},
                )),

                // 8: Log out
                _animatedItem(8, _MenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  isDark: isDark,
                  isLogout: true,
                  onTap: () => _confirmLogout(context),
                )),

                const SizedBox(height: 30),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatItem(int i, IconData icon, String value, String label,
      Color kMuted, bool isDark) {
    final fade  = i < _statsFade.length  ? _statsFade[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _statsSlide.length ? _statsSlide[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _kPrimary.withOpacity(0.25)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Icon(icon, color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: kMuted, fontSize: 11)),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) {
        final isDark = context.read<ThemeProvider>().isDark;
        return _LogoutDialog(isDark: isDark);
      },
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(curved),
              child: child),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _MenuItem
// ══════════════════════════════════════════════════════════════════════════
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final bool isLogout;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final kCard   = _kCard(isDark);
    final kText   = _kText(isDark);
    final kMuted  = _kMuted(isDark);
    final kBorder = _kBorder(isDark);
    final color   = isLogout ? _kRed : _kPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: isDark ? [] : [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: isLogout ? _kRed : kText,
                      fontSize: 16)),
            ),
            Icon(Icons.chevron_right_rounded, color: kMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _DarkModeItem
// ══════════════════════════════════════════════════════════════════════════
class _DarkModeItem extends StatelessWidget {
  final bool isDark;
  const _DarkModeItem({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final kCard   = _kCard(isDark);
    final kText   = _kText(isDark);
    final kBorder = _kBorder(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: isDark ? [] : [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          const Icon(Icons.dark_mode_outlined, color: _kPrimary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Dark Mode',
                style: TextStyle(color: kText, fontSize: 16)),
          ),
          GestureDetector(
            onTap: () => context.read<ThemeProvider>().toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48, height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF009689), Color(0xFF00B8DB)])
                    : null,
                color: isDark ? null : Colors.grey.shade400,
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _LogoutDialog
// ══════════════════════════════════════════════════════════════════════════
class _LogoutDialog extends StatefulWidget {
  final bool isDark;
  const _LogoutDialog({required this.isDark});

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<double> _pulseOpacity;

  bool _loggingOut = false; // ✅

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));
    _iconRotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.06), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));
    _pulseOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 50),
    ]).animate(_iconCtrl);
  }

  @override
  void dispose() { _iconCtrl.dispose(); super.dispose(); }

  // ✅ Logout الحقيقي عبر AuthService
  Future<void> _handleLogout(BuildContext context) async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final result = await AuthService().logout();

    if (!context.mounted) return;

    // logout() بيشيل التوكن محلياً حتى لو فشل الـ request، فدايماً نكمل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('role');

    if (!context.mounted) return;
    Navigator.pop(context); // اقفل الـ dialog
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);

    if (result['success'] != true) {
      // لو فيه رسالة خطأ من الباك، اعرضيها (الـ logout المحلي حصل بالفعل)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Logged out locally'),
        backgroundColor: Colors.orangeAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kCard   = _kCard(widget.isDark);
    final kText   = _kText(widget.isDark);
    final kMuted  = _kMuted(widget.isDark);
    final kBorder = _kBorder(widget.isDark);
    final kDeep   = _kDeep(widget.isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBorder),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _pulseOpacity,
                builder: (_, __) => Opacity(
                  opacity: _pulseOpacity.value,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kRed.withOpacity(0.25)),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _iconCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _iconRotate.value,
                  child: Transform.scale(
                    scale: _iconScale.value,
                    child: Container(
                      width: 62, height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kRed.withOpacity(0.15),
                        border: Border.all(
                            color: _kRed.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: _kRed, size: 28),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Logout',
              style: TextStyle(
                  color: kText, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kDeep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              "You'll need to sign in again to access your account",
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _PressScale(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: kDeep,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: _kPrimary.withOpacity(0.5)),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded,
                            color: _kPrimary, size: 18),
                        SizedBox(width: 6),
                        Text('Cancel',
                            style: TextStyle(
                                color: _kPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PressScale(
                onTap: () => _handleLogout(context), // ✅
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF2D55), _kRed]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _kRed.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: _loggingOut
                      ? const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Logout',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ]),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TRADER DETAILS SCREEN  (About + Shipments tabs)
// ══════════════════════════════════════════════════════════════════════════
class TraderDetailsScreen extends StatefulWidget {
  const TraderDetailsScreen({super.key});

  @override
  State<TraderDetailsScreen> createState() => _TraderDetailsScreenState();
}

class _TraderDetailsScreenState extends State<TraderDetailsScreen>
    with TickerProviderStateMixin {

  int _tab = 0;

  late AnimationController _pageCtrl;
  late AnimationController _avatarCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _headerCtrl;
  late AnimationController _statsCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _tabContentCtrl;
  late AnimationController _btnCtrl;

  late Animation<double> _pageFade;
  late Animation<Offset>  _pageSlide;
  late Animation<double> _avatarScale;
  late Animation<double> _ringAngle;
  late Animation<double> _nameFade;
  late Animation<Offset>  _nameSlide;
  late Animation<double> _roleFade;
  late Animation<Offset>  _roleSlide;
  late Animation<double> _tabFade;
  late Animation<Offset>  _tabSlide;
  late Animation<double> _btnScale;
  late Animation<int>    _tripsCount;
  late Animation<int>    _completedCount;

  final List<Animation<double>> _statsFade  = [];
  final List<Animation<Offset>>  _statsSlide = [];

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550))..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _avatarCtrl.forward(); });

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))..repeat();
    _ringAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ringCtrl);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _nameFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _roleFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _roleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _headerCtrl.forward(); });

    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    for (int i = 0; i < 4; i++) {
      final start = i * 0.18;
      final end   = (start + 0.5).clamp(0.0, 1.0);
      _statsFade.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _statsCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _statsSlide.add(
          Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(CurvedAnimation(parent: _statsCtrl,
                  curve: Interval(start, end, curve: Curves.easeOut))));
    }
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _statsCtrl.forward(); });

    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _tripsCount     = IntTween(begin: 0, end: 70).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _completedCount = IntTween(begin: 0, end: 50).animate(
        CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _counterCtrl.forward(); });

    _tabContentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _tabFade  = CurvedAnimation(parent: _tabContentCtrl, curve: Curves.easeOut);
    _tabSlide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tabContentCtrl, curve: Curves.easeOut));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _btnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut));

    // ✅ جيب بيانات البروفايل من الباك
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraderProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _avatarCtrl.dispose();
    _ringCtrl.dispose();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _counterCtrl.dispose();
    _tabContentCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _tabContentCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final user     = context.watch<UserProvider>();
    final trader   = context.watch<TraderProvider>(); // ✅

    // ✅ بيانات من الباك مع fallback
    final name = trader.fullName.isNotEmpty
        ? trader.fullName
        : (user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed');
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'TM';

    final kBg     = _kBg(isDark);
    final kCard   = _kCard(isDark);
    final kText   = _kText(isDark);
    final kMuted  = _kMuted(isDark);
    final kBorder = _kBorder(isDark);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ScaleTransition(
          scale: _btnScale,
          child: _PressScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kCard,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kPrimary, size: 16),
            ),
          ),
        ),
        actions: [
          ScaleTransition(
            scale: _btnScale,
            child: _PressScale(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorder),
                ),
                child: const Icon(Icons.share_outlined,
                    color: _kPrimary, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: RefreshIndicator(
            color: _kPrimary,
            onRefresh: () => context.read<TraderProvider>().loadProfile(), // ✅
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(children: [

              // Avatar
              ScaleTransition(
                scale: _avatarScale,
                child: _AnimatedAvatarRing(
                    initials: initials,
                    ringAngle: _ringAngle,
                    isDark: isDark),
              ),
              const SizedBox(height: 12),

              // Name
              FadeTransition(
                opacity: _nameFade,
                child: SlideTransition(
                  position: _nameSlide,
                  child: Text(name,
                      style: TextStyle(
                          color: kText,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: _roleFade,
                child: SlideTransition(
                  position: _roleSlide,
                  child: Text('Trader',
                      style: TextStyle(color: kMuted, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              AnimatedBuilder(
                animation: _statsCtrl,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(0, Icons.inventory_2_outlined, '5',
                        'Total Ships', kMuted, isDark),
                    _statItem(1, Icons.access_time,
                        '2', 'Active', kMuted, isDark),
                    _statItem(2, Icons.check_circle_outline,
                        '3', 'Completed', kMuted, isDark),
                    _statItem(3, Icons.people_outline,
                        '5', 'Drivers', kMuted, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab bar
              Row(children: [
                _AnimatedTabBtn(
                    label: 'About',
                    active: _tab == 0,
                    isDark: isDark,
                    onTap: () => _switchTab(0)),
                const SizedBox(width: 28),
                _AnimatedTabBtn(
                    label: 'Shipments',
                    active: _tab == 1,
                    isDark: isDark,
                    onTap: () => _switchTab(1)),
              ]),
              Divider(height: 1, color: kBorder.withOpacity(0.5)),
              const SizedBox(height: 20),

              // Tab content
              FadeTransition(
                opacity: _tabFade,
                child: SlideTransition(
                  position: _tabSlide,
                  child: _tab == 0
                      ? _AboutTab(isDark: isDark, trader: trader, fallbackName: name)
                      : _ShipmentsTab(isDark: isDark),
                ),
              ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(int i, IconData icon, String value, String label,
      Color kMuted, bool isDark) {
    final fade  = i < _statsFade.length  ? _statsFade[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _statsSlide.length ? _statsSlide[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _kCard(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder(isDark)),
            ),
            child: Icon(icon, color: _kPrimary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: kMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Animated Tab Button
// ══════════════════════════════════════════════════════════════════════════
class _AnimatedTabBtn extends StatefulWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _AnimatedTabBtn({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedTabBtn> createState() => _AnimatedTabBtnState();
}

class _AnimatedTabBtnState extends State<_AnimatedTabBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _underlineW;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _underlineW = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.active) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedTabBtn old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: widget.active
                    ? _kText(widget.isDark)
                    : _kMuted(widget.isDark),
                fontSize: 16,
                fontWeight:
                    widget.active ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(widget.label),
            ),
          ),
          AnimatedBuilder(
            animation: _underlineW,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 2,
                width: (widget.label.length * 9.5) * _underlineW.value,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFF009689),
                    _kPrimary,
                    Color(0xFF00B8DB),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════
//  About Tab — staggered slideX rows
//  ✅ بيانات من TraderProvider (الباك) مع fallback على القيم الثابتة
// ══════════════════════════════════════════════════════════════════════════
class _AboutTab extends StatefulWidget {
  final bool isDark;
  final TraderProvider trader;
  final String fallbackName;
  const _AboutTab({required this.isDark, required this.trader, required this.fallbackName});

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<Animation<double>> _fades  = [];
  final List<Animation<Offset>>  _slides = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    for (int i = 0; i < 5; i++) {
      final s = (i * 0.15).clamp(0.0, 0.70);
      final e = (s + 0.35).clamp(0.0, 1.0);
      _fades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _slides.add(
          Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _ctrl,
                  curve: Interval(s, e, curve: Curves.easeOut))));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kCard   = _kCard(widget.isDark);
    final kText   = _kText(widget.isDark);
    final kMuted  = _kMuted(widget.isDark);
    final kBorder = _kBorder(widget.isDark);

    final trader = widget.trader;

    // ✅ بيانات حقيقية من GET /api/trader/settings/profile مع fallback
    final items = <String, String>{
      'Full Name':       trader.fullName.isNotEmpty ? trader.fullName : widget.fallbackName,
      'Business Name':   trader.businessName.isNotEmpty ? trader.businessName : 'Smith Logistics Co.',
      'Email':           trader.email.isNotEmpty ? trader.email : 'Maroahmed@truckmate.com',
      'Phone Number':    trader.phoneNumber.isNotEmpty ? trader.phoneNumber : '+2 01284892003',
      'Total Shipments': '5 Shipments',
    };

    final keys   = items.keys.toList();
    final values = items.values.toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trader Information',
          style: TextStyle(
              color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: widget.isDark ? [] : [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: List.generate(keys.length, (i) {
            final fade  = i < _fades.length  ? _fades[i]  : const AlwaysStoppedAnimation(1.0);
            final slide = i < _slides.length ? _slides[i] : const AlwaysStoppedAnimation(Offset.zero);
            final isLast = i == keys.length - 1;
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: i == 0 ? 0 : 16, bottom: isLast ? 0 : 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(keys[i],
                              style: TextStyle(color: kMuted, fontSize: 14)),
                        ),
                        Flexible(
                          child: Text(values[i],
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: kText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: kBorder.withOpacity(0.5)),
                ]),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Shipments Tab — staggered slideY cards
//  ✅ FIX: View All → /trader_my_shipments
// ══════════════════════════════════════════════════════════════════════════
class _ShipmentsTab extends StatefulWidget {
  final bool isDark;
  const _ShipmentsTab({required this.isDark});

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<Animation<double>> _fades  = [];
  final List<Animation<Offset>>  _slides = [];

  static const _shipments = [
    (id: '#2145', type: 'Heavy Duty',   from: 'Cairo', to: 'Fayoum',  price: 220, duration: '3h 45m', km: '380 km', status: 'Completed'),
    (id: '#2144', type: 'Medium Truck', from: 'Cairo', to: 'Maadi',   price: 310, duration: '4h 15m', km: '50 km',  status: 'Pending'),
    (id: '#2143', type: 'Heavy Duty',   from: 'Alex',  to: 'Matrouh', price: 180, duration: '3h 30m', km: '385 km', status: 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))..forward();
    for (int i = 0; i < 3; i++) {
      final s = i * 0.25;
      final e = (s + 0.5).clamp(0.0, 1.0);
      _fades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _slides.add(
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: _ctrl,
                  curve: Interval(s, e, curve: Curves.easeOut))));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kCard   = _kCard(widget.isDark);
    final kText   = _kText(widget.isDark);
    final kMuted  = _kMuted(widget.isDark);
    final kBorder = _kBorder(widget.isDark);
    final kOrange = const Color(0xFFFF9F0A);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Shipments',
            style: TextStyle(
                color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        // ✅ FIX: View All → /trader_my_shipments (مش /trips)
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/trader_my_shipments'),
          child: const Text('View All',
              style: TextStyle(
                  color: _kPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 14),
      ...List.generate(_shipments.length, (i) {
        final s     = _shipments[i];
        final fade  = i < _fades.length  ? _fades[i]  : const AlwaysStoppedAnimation(1.0);
        final slide = i < _slides.length ? _slides[i] : const AlwaysStoppedAnimation(Offset.zero);
        final isCompleted = s.status == 'Completed';
        final statusColor = isCompleted ? _kPrimary : kOrange;

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: _PressScale(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: widget.isDark ? [] : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text('Shipment ${s.id}',
                        style: const TextStyle(
                            color: _kPrimary, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(s.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(s.type,
                      style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: _kPrimary, size: 14),
                    const SizedBox(width: 4),
                    Text('${s.from} → ${s.to}',
                        style: TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${s.price}',
                          style: TextStyle(
                              color: kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Row(children: [
                        Icon(Icons.access_time, color: kMuted, size: 13),
                        const SizedBox(width: 4),
                        Text(s.duration,
                            style: TextStyle(color: kMuted, fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.trending_up_rounded,
                            color: kMuted, size: 13),
                        const SizedBox(width: 4),
                        Text(s.km,
                            style: TextStyle(color: kMuted, fontSize: 11)),
                      ]),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    ]);
  }
}