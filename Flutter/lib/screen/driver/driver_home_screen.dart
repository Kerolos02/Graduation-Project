// ════════════════════════════════════════════════════════════
//  driver_home_screen.dart
//  ✨ ALL ANIMATIONS PRESERVED — API CONNECTED
//  API: GET /api/driver/home  |  PATCH /api/driver/status
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';
import '/screen/driver/live_navigation_screen.dart';
import '/screen/driver/trips_screen.dart';
import '/screen/driver/driver_earnings_screen.dart';
import '/screen/driver/driver_profile_screens.dart';
import '/screen/driver/driver_trip_screens.dart';

// ── Palette ──
const Color _kTeal  = Color(0xFF00D5BE);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kGold  = Color(0xFFC9A063);
const Color _kGreen = Color(0xFF34C759);

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {

  int _navIndex = 0;
  bool _showOffer = false;

  late AnimationController _pageCtrl;
  late List<Animation<double>> _staggerAnims;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  late AnimationController _floatCtrl1;
  late AnimationController _floatCtrl2;
  late Animation<double> _floatAnim1;
  late Animation<double> _floatAnim2;
  late AnimationController _offerBorderCtrl;
  late Animation<double> _offerBorderAnim;
  late AnimationController _offerGlowCtrl;
  late Animation<double> _offerGlowAnim;

  bool _prevOnline = false;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _staggerAnims = List.generate(10, (i) {
      final start = (i * 0.08).clamp(0.0, 0.8);
      final end   = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _pageCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _rotateAnim = Tween<double>(begin: -0.26, end: 0.26).animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.easeInOut));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: const Cubic(0.22, 1, 0.36, 1));

    _floatCtrl1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat(reverse: true);
    _floatCtrl2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))..repeat(reverse: true);
    _floatAnim1 = Tween<double>(begin: 0, end: 30).animate(CurvedAnimation(parent: _floatCtrl1, curve: Curves.easeInOut));
    _floatAnim2 = Tween<double>(begin: 0, end: -20).animate(CurvedAnimation(parent: _floatCtrl2, curve: Curves.easeInOut));

    _offerBorderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _offerBorderAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _offerBorderCtrl, curve: Curves.linear));

    _offerGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _offerGlowAnim = Tween<double>(begin: 0.05, end: 0.1).animate(CurvedAnimation(parent: _offerGlowCtrl, curve: Curves.easeInOut));

    // ── Load real data from API ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadHome();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _rotateCtrl.dispose();
    _progressCtrl.dispose();
    _floatCtrl1.dispose();
    _floatCtrl2.dispose();
    _offerBorderCtrl.dispose();
    _offerGlowCtrl.dispose();
    super.dispose();
  }

  void _restartEntrance() => _pageCtrl.forward(from: 0);

  Future<bool> _onWillPop() async {
    if (_navIndex != 0) { setState(() => _navIndex = 0); return false; }
    return await _showLogoutDialog();
  }

  Future<bool> _showLogoutDialog() async {
    final theme = context.read<ThemeProvider>().theme;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: theme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: theme.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: _kTeal, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('role');
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final driver   = context.watch<DriverProvider>();
    final theme    = context.watch<ThemeProvider>().theme;
    final user     = context.watch<UserProvider>();
    final isDark   = theme.isDark;
    final isOnline = driver.isOnline;

    if (_prevOnline != isOnline) {
      _prevOnline = isOnline;
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartEntrance());
    }

    if (driver.hasActiveTrip && driver.activeTrip?.status == TripStatus.inProgress) {
      if (!_progressCtrl.isAnimating && _progressCtrl.value == 0) _progressCtrl.forward();
    }

    final kBg     = isDark ? const Color(0xFF0F2334) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async { if (didPop) return; await _onWillPop(); },
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(children: [
          _buildBgOrbs(isDark),
          SafeArea(child: Column(children: [
            Expanded(child: _buildPage(driver, theme, user, isDark, kBg, kCard, kBorder, kText, kMuted)),
          ])),

          // ── Loading overlay (شفاف خفيف فوق كل حاجة) ──
          if (driver.isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black12,
                  child: Center(
                    child: CircularProgressIndicator(color: _kTeal, strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
        ]),
        bottomNavigationBar: _buildBottomNav(theme, isDark),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  BACKGROUND ORBS
  // ══════════════════════════════════════════
  Widget _buildBgOrbs(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl1, _floatCtrl2]),
      builder: (_, __) => Stack(children: [
        Positioned(
          top: 80 + _floatAnim1.value, right: 40,
          child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _kAmber.withOpacity(isDark ? 0.05 : 0.03), blurRadius: 80, spreadRadius: 40)])),
        ),
        Positioned(
          top: 160 + _floatAnim2.value, left: 40,
          child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _kTeal.withOpacity(isDark ? 0.05 : 0.03), blurRadius: 70, spreadRadius: 35)])),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  PAGE ROUTER
  // ══════════════════════════════════════════
  Widget _buildPage(DriverProvider driver, AppTheme theme, UserProvider user, bool isDark,
      Color kBg, Color kCard, Color kBorder, Color kText, Color kMuted) {
    final pages = [
      _buildHomeTab(driver, theme, user, isDark, kBg, kCard, kBorder, kText, kMuted),
      const TripsScreen(),
      const DriverEarningsScreen(),
      const DriverNotificationsScreen(),
      const DriverSettingsScreen(),
    ];
    return pages[_navIndex];
  }

  // ══════════════════════════════════════════
  //  HOME TAB
  // ══════════════════════════════════════════
  Widget _buildHomeTab(DriverProvider driver, AppTheme theme, UserProvider user, bool isDark,
      Color kBg, Color kCard, Color kBorder, Color kText, Color kMuted) {
    final isOnline    = driver.isOnline;
    final hasTrip     = driver.hasActiveTrip;
    final isInTransit = hasTrip && driver.activeTrip?.status == TripStatus.inProgress;
    final isAssigned  = hasTrip && driver.activeTrip?.status != TripStatus.inProgress;

    // ── Error banner ──
    if (driver.error != null && !driver.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Connection error — showing cached data'),
            backgroundColor: _kAmber,
            duration: const Duration(seconds: 3),
          ));
          // ✅ FIX: امسح الـ error بعد عرضه عشان ما يفضلش عالق بين الصفحات
          context.read<DriverProvider>().clearError();
        }
      });
    }

    return RefreshIndicator(
      color: _kTeal,
      onRefresh: () => context.read<DriverProvider>().loadHome(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          _animItem(0, _buildHeader(user, driver, isDark, kText, kMuted)),
          const SizedBox(height: 14),
          _animItem(1, _buildStatusChip(driver, isDark, kMuted)),
          const SizedBox(height: 24),

          if (!hasTrip && !isOnline)
            _animItem(2, _buildOfflineHero(isDark, kCard, kBorder, kText, kMuted)),
          if (!hasTrip && isOnline)
            _animItem(2, _buildOnlineHero(isDark, kCard, kBorder, kText, kMuted)),
          if (isAssigned)
            _animItem(2, _buildAssignedHero(driver, isDark, kCard, kBorder, kText, kMuted)),
          if (isInTransit)
            _animItem(2, _buildInTransitHero(driver, isDark, kCard, kBorder, kText, kMuted)),

          const SizedBox(height: 14),

          if (!hasTrip && isOnline) ...[
            _animItem(3, _buildOutlineBtn('Go Offline', isDark,
                () => context.read<DriverProvider>().toggleOnline())),
            const SizedBox(height: 24),
          ],

          if (!hasTrip && isOnline) ...[
            _animItem(4, _buildIncomingTripsSection(isDark, kCard, kBorder, kText, kMuted)),
            const SizedBox(height: 24),
          ],

          if (!hasTrip) ...[
            _animItem(5, _buildTodayStats(driver, isDark, kCard, kBorder, kText, kMuted)),
            const SizedBox(height: 24),
          ],

          _animItem(6, _buildRecentTripsHeader(isDark, kText)),
          const SizedBox(height: 12),
          _animItem(7, _buildRecentTrips(driver, isDark, kCard, kBorder, kText, kMuted)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _animItem(int index, Widget child) {
    final anim = _staggerAnims[index.clamp(0, _staggerAnims.length - 1)];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════
  Widget _buildHeader(UserProvider user, DriverProvider driver, bool isDark, Color kText, Color kMuted) {
    // ✅ FIX: الاسم والـ initials بقوا جايين من DriverProvider (نتيجة /api/driver/home)
    final name     = driver.driverName.isNotEmpty ? driver.driverName : 'Driver';
    final initials = driver.initials;

    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 2),
        Text(name, style: TextStyle(color: kText, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _staggerAnims[0],
          builder: (_, __) => Container(
            width: 60 * _staggerAnims[0].value, height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kAmber, _kTeal, Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ])),
      AnimatedBuilder(
        animation: _rotateAnim,
        builder: (_, child) => Transform.rotate(angle: _rotateAnim.value * 0.2, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_kGold.withOpacity(0.12), _kTeal.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGold.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: _kGold, size: 15),
            const SizedBox(width: 4),
            // ✅ FIX: الـ rating بقى جاي من DriverProvider (نتيجة /api/driver/home)
            Text(driver.rating.toStringAsFixed(1), style: TextStyle(color: kText, fontSize: 13)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
        child: driver.isOnline ? _onlinePill() : _offlinePill(kMuted),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => setState(() => _navIndex = 4),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_kAmber.withOpacity(0.2), _kTeal.withOpacity(0.15)]),
            border: Border.all(color: _kAmber.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initials, style: const TextStyle(color: _kAmber, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]);
  }

  Widget _onlinePill() => Container(
    key: const ValueKey('online'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _kGreen.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kGreen.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 7, height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _kGreen,
              boxShadow: [BoxShadow(color: _kGreen.withOpacity(_pulseCtrl.value * 0.5), blurRadius: 6, spreadRadius: 1)]),
        ),
      ),
      const SizedBox(width: 5),
      const Text('ONLINE', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _offlinePill(Color kMuted) => Container(
    key: const ValueKey('offline'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: kMuted.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kMuted.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: kMuted)),
      const SizedBox(width: 5),
      Text('OFFLINE', style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  // ══════════════════════════════════════════
  //  STATUS CHIP
  // ══════════════════════════════════════════
  Widget _buildStatusChip(DriverProvider driver, bool isDark, Color kMuted) {
    if (driver.hasActiveTrip && driver.activeTrip?.status == TripStatus.inProgress) {
      return _statusChip(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _kTeal,
                  boxShadow: [BoxShadow(color: _kTeal.withOpacity(_pulseCtrl.value * 0.6), blurRadius: 4)]),
            ),
          ),
          const SizedBox(width: 6),
          const Text('In Transit', style: TextStyle(color: _kTeal, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        bg: _kTeal.withOpacity(0.12), border: _kTeal.withOpacity(0.3),
      );
    }
    if (driver.hasActiveTrip) {
      return _statusChip(
        child: const Text('Assigned', style: TextStyle(color: _kTeal, fontSize: 13, fontWeight: FontWeight.w600)),
        bg: _kTeal.withOpacity(0.12), border: _kTeal.withOpacity(0.3),
      );
    }
    return _statusChip(
      child: Text('No Active Trip', style: TextStyle(color: kMuted, fontSize: 13)),
      bg: kMuted.withOpacity(0.15), border: kMuted.withOpacity(0.2),
    );
  }

  Widget _statusChip({required Widget child, required Color bg, required Color border}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: child,
      );

  // ══════════════════════════════════════════
  //  OFFLINE HERO
  // ══════════════════════════════════════════
  Widget _buildOfflineHero(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)]
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F4F8)),
          child: Icon(Icons.local_shipping_outlined,
              color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFFB0BEC5), size: 36),
        ),
        const SizedBox(height: 20),
        Text("You're Offline", style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text("You're not receiving new trips", style: TextStyle(color: kMuted, fontSize: 14)),
        const SizedBox(height: 28),
        _buildGradientBtn('Go Online', Icons.wifi_tethering,
            () => context.read<DriverProvider>().toggleOnline()),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  ONLINE HERO
  // ══════════════════════════════════════════
  Widget _buildOnlineHero(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0D3D30), Color(0xFF0D2A35)])
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_kTeal.withOpacity(0.06), _kTeal.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withOpacity(isDark ? 0.2 : 0.3)),
      ),
      child: Column(children: [
        SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) {
            final v = _pulseCtrl.value;
            return Container(width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: _kGreen.withOpacity(0.6 * (1 - v)), width: 2)),
              transform: Matrix4.identity()..scale(1.0 + 0.8 * v),
              transformAlignment: Alignment.center);
          }),
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) {
            final v = (_pulseCtrl.value + 0.3) % 1.0;
            return Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: _kGreen.withOpacity(0.5 * (1 - v)), width: 2)),
              transform: Matrix4.identity()..scale(1.0 + 0.5 * v),
              transformAlignment: Alignment.center);
          }),
          AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) {
            final v = (_pulseCtrl.value + 0.6) % 1.0;
            return Container(width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: _kGreen.withOpacity(0.4 * (1 - v)), width: 2)),
              transform: Matrix4.identity()..scale(1.0 + 0.3 * v),
              transformAlignment: Alignment.center);
          }),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_kGreen, Color(0xFF30B0C7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.4), blurRadius: 16, spreadRadius: 2)]),
              child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 24),
            ),
          ),
        ])),
        const SizedBox(height: 20),
        Text("You're Online", style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Waiting for new trip requests', style: TextStyle(color: kMuted, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : _kTeal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_outlined, color: _kTeal, size: 16),
            SizedBox(width: 6),
            Text('Zone: Downtown Area', style: TextStyle(color: _kTeal, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  ASSIGNED HERO
  // ══════════════════════════════════════════
  Widget _buildAssignedHero(DriverProvider driver, bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorder)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_kTeal.withOpacity(0.15), _kTeal.withOpacity(0.08)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(bottom: BorderSide(color: _kTeal.withOpacity(0.15))),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Trip Ready to Start', style: TextStyle(color: _kTeal, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(driver.activeTrip?.id ?? 'SHP-0000', style: TextStyle(color: kMuted, fontSize: 13)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _routeSection(driver, isDark, kText, kMuted),
            const SizedBox(height: 20),
            Divider(height: 1, color: kBorder),
            const SizedBox(height: 20),
            _infoRow(kText, kMuted, 'Client', driver.activeTrip?.traderName ?? '—'),
            const SizedBox(height: 10),
            _infoRow(kText, kMuted, 'Cargo', driver.activeTrip?.goodsType ?? '—'),
            const SizedBox(height: 10),
            _infoRow(kText, kMuted, 'Weight', '${driver.activeTrip?.weightTons ?? 0} tons'),
            const SizedBox(height: 16),
            if (driver.activeTrip?.isFragile == true) _buildFragileTag(),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  IN TRANSIT HERO
  // ══════════════════════════════════════════
  Widget _buildInTransitHero(DriverProvider driver, bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    final kDeep = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF0F4F8);
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0D3040), Color(0xFF0D2535)])
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_kTeal.withOpacity(0.08), _kTeal.withOpacity(0.03)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kTeal.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(driver.activeTrip?.id ?? 'SHP-0000', style: TextStyle(color: kMuted, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        _routeSection(driver, isDark, kText, kMuted),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kDeep, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAmber.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ETA', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(driver.activeTrip?.estimatedTime ?? '— min',
                  style: const TextStyle(color: _kAmber, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
          )),
          const SizedBox(width: 12),
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kDeep, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kTeal.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Progress', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 6),
              const Text('65%', style: TextStyle(color: _kTeal, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
          )),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => Stack(children: [
              Container(height: 8, decoration: BoxDecoration(color: _kTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(6))),
              FractionallySizedBox(
                widthFactor: 0.65 * _progressAnim.value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kAmber, _kTeal, Color(0xFF00BBA7)]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.4), blurRadius: 8)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(_shimmerAnim.value * 100, 0),
                        child: Container(decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent]))),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _buildGradientBtn('View Live Navigation', Icons.navigation,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveNavigationScreen()))),
      ]),
    );
  }

  Widget _routeSection(DriverProvider driver, bool isDark, Color kText, Color kMuted) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kAmber)),
        Container(width: 2, height: 40, color: _kTeal.withOpacity(0.3)),
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kTeal, width: 2))),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('From', style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(driver.activeTrip?.origin ?? '—', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text('To', style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(driver.activeTrip?.destination ?? '—', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }

  Widget _buildFragileTag() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _kAmber.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kAmber.withOpacity(0.35)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.warning_amber_rounded, color: _kAmber, size: 13),
      SizedBox(width: 5),
      Text('FRAGILE', style: TextStyle(color: _kAmber, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  // ══════════════════════════════════════════
  //  INCOMING TRIPS
  // ══════════════════════════════════════════
  Widget _buildIncomingTripsSection(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Incoming Trips', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: () => setState(() => _showOffer = !_showOffer),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(_showOffer ? 'Hide Offer' : 'Show Offer',
                key: ValueKey(_showOffer), style: const TextStyle(color: _kTeal, fontSize: 14)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: _showOffer
            ? _buildOfferCard(isDark, kCard, kBorder, kText, kMuted)
            : _buildNoOffersCard(isDark, kCard, kBorder, kText, kMuted),
      ),
    ]);
  }

  Widget _buildNoOffersCard(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    return Container(
      key: const ValueKey('no_offers'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => Transform.rotate(
            angle: (_pulseCtrl.value - 0.5) * 0.2,
            child: Transform.scale(scale: 1.0 + _pulseCtrl.value * 0.05, child: child),
          ),
          child: Container(width: 56, height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _kTeal.withOpacity(0.12)),
            child: const Icon(Icons.move_to_inbox_outlined, color: _kTeal, size: 28)),
        ),
        const SizedBox(height: 14),
        Text('No trips available right now', style: TextStyle(color: kText, fontSize: 15)),
        const SizedBox(height: 6),
        Text('Stay online to receive nearby shipments', style: TextStyle(color: kMuted, fontSize: 13)),
      ]),
    );
  }

  Widget _buildOfferCard(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    // Use first available trip from API, fallback to placeholder
    final trips = context.read<DriverProvider>().availableTrips;
    final offer = trips.isNotEmpty ? trips.first : null;

    return AnimatedBuilder(
      animation: _offerBorderAnim,
      builder: (_, __) {
        final t = _offerBorderAnim.value;
        final borderColor = Color.lerp(_kTeal, _kAmber, (sin(t * pi * 2) + 1) / 2)!;
        return Container(
          key: const ValueKey('offer'),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_kTeal.withOpacity(0.15), _kAmber.withOpacity(0.08), _kTeal.withOpacity(0.10)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.15), blurRadius: 20)],
          ),
          child: Stack(children: [
            AnimatedBuilder(
              animation: _offerGlowAnim,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(colors: [_kTeal.withOpacity(_offerGlowAnim.value), Colors.transparent]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color.lerp(_kTeal, _kAmber, _pulseCtrl.value)!.withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _kTeal,
                              boxShadow: [BoxShadow(color: _kTeal.withOpacity(_pulseCtrl.value * 0.5), blurRadius: 4)]),
                        )),
                        const SizedBox(width: 6),
                        const Text('NEW TRIP REQUEST', style: TextStyle(color: _kTeal, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    _OfferFloatingDots(pulseCtrl: _pulseCtrl),
                    const SizedBox(width: 8),
                    _OfferPriceBounce(shimmerAnim: _shimmerAnim, price: offer != null ? '${offer.price.toStringAsFixed(0)} EGP' : '— EGP'),
                  ]),
                ]),
                const SizedBox(height: 14),
                _tripRouteRow(kText, kMuted,
                    offer?.origin ?? 'Loading...',
                    offer?.destination ?? 'Loading...'),
                const SizedBox(height: 12),
                Row(children: [
                  Text(offer?.distance ?? '—', style: TextStyle(color: kMuted, fontSize: 12)),
                  Text('  •  ', style: TextStyle(color: kMuted, fontSize: 12)),
                  Text(offer?.estimatedTime ?? '—', style: TextStyle(color: kMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 1),
                  child: Container(
                    width: double.infinity, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kAmber, _kTeal, Color(0xFF00BBA7)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(_shimmerAnim.value * 200, 0),
                            child: Container(width: 80, decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.transparent, Colors.white24, Colors.transparent]))),
                          ),
                        ),
                      ),
                      const Text('View Offer', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _tripRouteRow(Color kText, Color kMuted, String from, String to) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kTeal)),
        Container(width: 1.5, height: 30, color: _kTeal.withOpacity(0.3)),
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kTeal, width: 1.5))),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('From', style: TextStyle(color: kMuted, fontSize: 11)),
        Text(from, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Text('To', style: TextStyle(color: kMuted, fontSize: 11)),
        Text(to, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }

  // ══════════════════════════════════════════
  //  TODAY STATS
  // ══════════════════════════════════════════
  Widget _buildTodayStats(DriverProvider driver, bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    final stats = driver.todayStats;
    final items = [
      {'icon': Icons.trending_up, 'color': _kAmber, 'label': 'Trips completed', 'value': '3', 'tap': null},
      {'icon': Icons.attach_money, 'color': _kTeal, 'label': 'Earnings',
       'value': '390 EGP', 'tap': () => setState(() => _navIndex = 2)},
      {'icon': Icons.access_time, 'color': const Color(0xFFFBBF24), 'label': 'Online time', 'value': stats.onlineTime, 'tap': null},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Today', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      ...items.asMap().entries.map((e) => _animItem(5 + e.key, Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildStatRow(isDark, kCard, kBorder, kText, kMuted,
          icon: e.value['icon'] as IconData,
          iconColor: e.value['color'] as Color,
          label: e.value['label'] as String,
          value: e.value['value'] as String,
          onTap: e.value['tap'] as VoidCallback?,
        ),
      ))),
    ]);
  }

  Widget _buildStatRow(bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted, {
    required IconData icon, required Color iconColor,
    required String label, required String value, VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: kMuted, fontSize: 14))),
          Text(value, style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
          if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, color: kMuted, size: 16)],
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  RECENT TRIPS
  // ══════════════════════════════════════════
  Widget _buildRecentTripsHeader(bool isDark, Color kText) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Recent Trips', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
      GestureDetector(
        onTap: () => setState(() => _navIndex = 1),
        child: const Text('View all', style: TextStyle(color: _kTeal, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    ]);
  }

  Widget _buildRecentTrips(DriverProvider driver, bool isDark, Color kCard, Color kBorder, Color kText, Color kMuted) {
    final trips = driver.recentTrips.take(2).toList();
    if (trips.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('No recent trips yet', style: TextStyle(color: kMuted, fontSize: 14)),
      ));
    }
    return Column(
      children: trips.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _animItem(7 + e.key, GestureDetector(
          onTap: () => setState(() => _navIndex = 1),
          child: _TripCard(
            id: e.value.id, date: e.value.date,
            route: '${e.value.origin} \u2192 ${e.value.destination}',
            status: 'Completed', time: e.value.time,
            isDark: isDark, kCard: kCard, kBorder: kBorder, kText: kText, kMuted: kMuted,
          ),
        )),
      )).toList(),
    );
  }

  // ══════════════════════════════════════════
  //  BUTTONS
  // ══════════════════════════════════════════
  Widget _buildGradientBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kTeal, Color(0xFF00BBA7)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(alignment: Alignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_shimmerAnim.value * 200, 0),
                child: Container(width: 80, decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, Colors.white24, Colors.transparent]))),
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildOutlineBtn(String label, bool isDark, VoidCallback onTap) {
    final bg = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F4F8);
    final border = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2EAF0);
    final textColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF8A9BB0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _infoRow(Color kText, Color kMuted, String label, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: kMuted, fontSize: 14)),
        Text(value, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
      ]);

  // ══════════════════════════════════════════
  //  BOTTOM NAV
  // ══════════════════════════════════════════
  Widget _buildBottomNav(AppTheme theme, bool isDark) {
    final kCard   = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);
    const items = [
      {'icon': Icons.home_outlined,                   'activeIcon': Icons.home_rounded,                         'label': 'Home'},
      {'icon': Icons.local_shipping_outlined,          'activeIcon': Icons.local_shipping_rounded,               'label': 'Trips'},
      {'icon': Icons.account_balance_wallet_outlined,  'activeIcon': Icons.account_balance_wallet_rounded,       'label': 'Earnings'},
      {'icon': Icons.notifications_outlined,           'activeIcon': Icons.notifications_rounded,                'label': 'Alerts'},
      {'icon': Icons.person_outline_rounded,           'activeIcon': Icons.person_rounded,                       'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key; final item = e.value; final active = _navIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _navIndex = i);
                    // Load available trips when switching to Trips tab
                    if (i == 1) context.read<DriverProvider>().loadAvailableTrips();
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 3, width: active ? 36 : 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        gradient: active ? const LinearGradient(colors: [_kTeal, Color(0xFF00BBA7)]) : null,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: active ? [BoxShadow(color: _kTeal.withOpacity(0.4), blurRadius: 8)] : [],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        active ? item['activeIcon'] as IconData : item['icon'] as IconData,
                        key: ValueKey('${i}_$active'),
                        color: active ? _kTeal : theme.textMuted, size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(item['label'] as String, style: TextStyle(
                        color: active ? _kTeal : theme.textMuted,
                        fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TRIP CARD WIDGET
// ══════════════════════════════════════════
class _TripCard extends StatefulWidget {
  final String id, date, route, status, time;
  final bool isDark;
  final Color kCard, kBorder, kText, kMuted;
  const _TripCard({required this.id, required this.date, required this.route,
    required this.status, required this.time, required this.isDark,
    required this.kCard, required this.kBorder, required this.kText, required this.kMuted});
  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedSlide(
        offset: _pressed ? const Offset(0.01, 0) : Offset.zero,
        duration: const Duration(milliseconds: 120),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.kCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.kBorder),
              boxShadow: widget.isDark
                  ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(widget.id, style: TextStyle(color: widget.kMuted, fontSize: 12)),
                Text(widget.date, style: TextStyle(color: widget.kMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Text(widget.route, style: TextStyle(color: widget.kText, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kGreen)),
                    const SizedBox(width: 5),
                    Text(widget.status, style: const TextStyle(color: _kGreen, fontSize: 12)),
                  ]),
                ),
                Text(widget.time, style: TextStyle(color: widget.kMuted, fontSize: 13)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  OFFER FLOATING DOTS
// ══════════════════════════════════════════
class _OfferFloatingDots extends StatefulWidget {
  final AnimationController pulseCtrl;
  const _OfferFloatingDots({required this.pulseCtrl});
  @override
  State<_OfferFloatingDots> createState() => _OfferFloatingDotsState();
}
class _OfferFloatingDotsState extends State<_OfferFloatingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y1, _y2, _y3;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _y1 = Tween<double>(begin: 0.0, end: -4.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _y2 = Tween<double>(begin: -2.0, end: 2.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 1.0, curve: Curves.easeInOut)));
    _y3 = Tween<double>(begin: 0.0, end: -3.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Transform.translate(offset: Offset(0, _y1.value), child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kTeal))),
        const SizedBox(width: 4),
        Transform.translate(offset: Offset(0, _y2.value), child: Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kAmber))),
        const SizedBox(width: 4),
        Transform.translate(offset: Offset(0, _y3.value), child: Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: _kTeal.withOpacity(0.6)))),
      ]),
    );
  }
}

// ══════════════════════════════════════════
//  OFFER PRICE BOUNCE
// ══════════════════════════════════════════
class _OfferPriceBounce extends StatefulWidget {
  final Animation<double> shimmerAnim;
  final String price;
  const _OfferPriceBounce({required this.shimmerAnim, required this.price});
  @override
  State<_OfferPriceBounce> createState() => _OfferPriceBounceState();
}
class _OfferPriceBounceState extends State<_OfferPriceBounce> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Text(widget.price, style: const TextStyle(color: _kAmber, fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}