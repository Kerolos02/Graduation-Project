import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/models/driver_models.dart';
import '/services/driver_service.dart';
import '/services/auth_service.dart';

// ─── local palette ───────────────────────────────────────────────────────
const Color _kBg      = Color(0xFF0D1F2D);
const Color _kPrimary = Color(0xFF00D5BE);
const Color _kOrange  = Color(0xFFFF8C00);
const Color _kRed     = Color(0xFFFF476D);

// ══════════════════════════════════════════════════════════════════════════
//  SHARED ANIMATION HELPERS
// ══════════════════════════════════════════════════════════════════════════

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _anim, child: widget.child),
      );
}

// ══════════════════════════════════════════════════════════════════════════
//  1.  DRIVER PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════════════
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with TickerProviderStateMixin {
  int _tab = 0;

  // ── API ──
  final DriverService _driverService = DriverService();
  bool _loadingProfile = true;
  Map<String, dynamic>? _profileData;

  late AnimationController _pageCtrl;
  late AnimationController _avatarCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _headerCtrl;
  late AnimationController _statsCtrl;
  late AnimationController _tabContentCtrl;
  late AnimationController _btnCtrl;

  late Animation<double>  _pageFade;
  late Animation<Offset>  _pageSlide;
  late Animation<double>  _avatarScale;
  late Animation<double>  _ringAngle;
  late Animation<double>  _nameFade;
  late Animation<Offset>  _nameSlide;
  late Animation<double>  _roleFade;
  late Animation<Offset>  _roleSlide;
  late Animation<double>  _tabFade;
  late Animation<Offset>  _tabSlide;
  late Animation<double>  _btnScale;

  final List<Animation<double>> _statsFade  = [];
  final List<Animation<Offset>> _statsSlide = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchProfile();
  }

  // ── جيب بيانات البروفايل من الباك ──
  Future<void> _fetchProfile() async {
    final result = await _driverService.getProfile();
    if (!mounted) return;
    setState(() {
      _loadingProfile = false;
      if (result['success'] == true) {
        _profileData = result['data']?['data'] ?? result['data'];
        // حدّث الـ UserProvider بالبيانات الجديدة
        final user = context.read<UserProvider>();
        final d = _profileData;
        if (d != null) {
          user.update(
  fullName:      d['fullName']      ?? d['name'],
  email:         d['email'],
  phone:         d['phone'],
  licenseNumber: d['licenseNumber'],
  licenseType:   d['licenseType'],
  plateNumber:   d['plateNumber']   ?? d['truckPlate'],
  truckType:     d['truckType'],
  capacity:      d['capacity']?.toString(),
);
        }
      }
    });
  }

  void _initAnimations() {
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
            begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut));
    Future.delayed(
        const Duration(milliseconds: 150), () { if (mounted) _avatarCtrl.forward(); });

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _ringAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ringCtrl);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _nameFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _nameSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _roleFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _roleSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    Future.delayed(
        const Duration(milliseconds: 300), () { if (mounted) _headerCtrl.forward(); });

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
    Future.delayed(
        const Duration(milliseconds: 400), () { if (mounted) _statsCtrl.forward(); });

    _tabContentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..forward();
    _tabFade  = CurvedAnimation(parent: _tabContentCtrl, curve: Curves.easeOut);
    _tabSlide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tabContentCtrl, curve: Curves.easeOut));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _btnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _avatarCtrl.dispose();
    _ringCtrl.dispose();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
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
    final user   = context.watch<UserProvider>();
    final driver = context.watch<DriverProvider>();
    final theme  = context.watch<ThemeProvider>().theme;

    final name     = 'محمود ناصر';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: theme.bg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(children: [

                ScaleTransition(
                  scale: _btnScale,
                  child: Row(children: [
                    _PressScale(
                      onTap: () => Navigator.pop(context),
                      child: _BackBtn(theme: theme),
                    ),
                    const Spacer(),
                    _PressScale(
                      onTap: () {},
                      child: _IconBtn(icon: Icons.share_outlined, theme: theme),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // لو لسه بيلود، اعرض shimmer بسيط فوق الأفاتار
                _loadingProfile
                    ? const SizedBox(
                        width: 96, height: 96,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_kPrimary)))
                    : ScaleTransition(
                        scale: _avatarScale,
                        child: _AnimatedAvatarRing(
                            initials: initials, ringAngle: _ringAngle),
                      ),
                const SizedBox(height: 12),

                FadeTransition(
                  opacity: _nameFade,
                  child: SlideTransition(
                    position: _nameSlide,
                    child: Text(name,
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 4),

                FadeTransition(
                  opacity: _roleFade,
                  child: SlideTransition(
                    position: _roleSlide,
                    child: Text('Driver',
                        style: TextStyle(
                            color: theme.textMuted, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 20),

                _StatsRow(
                  driver: driver,
                  profileData: _profileData,
                  theme: theme,
                  fades: _statsFade,
                  slides: _statsSlide,
                ),
                const SizedBox(height: 20),

                Row(children: [
                  _AnimatedTabBtn(
                      label: 'About',
                      active: _tab == 0,
                      onTap: () => _switchTab(0),
                      theme: theme),
                  const SizedBox(width: 24),
                  _AnimatedTabBtn(
                      label: 'Shipments',
                      active: _tab == 1,
                      onTap: () => _switchTab(1),
                      theme: theme),
                ]),
                Divider(height: 1, color: theme.border),
                const SizedBox(height: 20),

                FadeTransition(
                  opacity: _tabFade,
                  child: SlideTransition(
                    position: _tabSlide,
                    child: _tab == 0
                        ? _AboutTab(user: user, profileData: _profileData, theme: theme)
                        : _ShipmentsTab(driver: driver, theme: theme),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated avatar with rotating sweep-gradient ring ─────────────────────
class _AnimatedAvatarRing extends StatelessWidget {
  final String initials;
  final Animation<double> ringAngle;
  const _AnimatedAvatarRing(
      {required this.initials, required this.ringAngle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: ringAngle,
          builder: (_, __) => Transform.rotate(
            angle: ringAngle.value,
            child: Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF009689),
                    Color(0xFF00BBA7),
                    Color(0xFF00B8DB),
                    Color(0xFF009689),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF192C3D)),
          child: Center(
            child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE05E3A), Color(0xFFB44AA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 26)),
            ),
          ),
        ),
        Positioned(
          bottom: 2, right: 2,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: _kBg, width: 2),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
      ]),
    );
  }
}

// ── Animated tab button ────────────────────────────────────────────────────
class _AnimatedTabBtn extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppTheme theme;
  const _AnimatedTabBtn(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.theme});

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
    _underlineW = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: widget.active
                  ? widget.theme.textPrimary
                  : widget.theme.textMuted,
              fontSize: 15,
              fontWeight: widget.active ? FontWeight.w700 : FontWeight.w400,
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
              width: (widget.label.length * 8.5) * _underlineW.value,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF009689), _kPrimary, Color(0xFF00B8DB)],
                ),
                boxShadow: widget.active
                    ? [BoxShadow(
                        color: _kPrimary.withOpacity(0.6),
                        blurRadius: 8)]
                    : null,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final DriverProvider driver;
  final Map<String, dynamic>? profileData;
  final AppTheme theme;
  final List<Animation<double>> fades;
  final List<Animation<Offset>> slides;
  const _StatsRow(
      {required this.driver,
      required this.profileData,
      required this.theme,
      required this.fades,
      required this.slides});

  @override
  Widget build(BuildContext context) {
    // استخدم بيانات الباك لو موجودة، وإلا fallback على الـ provider
    final total     = "3";
    final completed = "3";
    final rating    = profileData?['rating']?.toString() ?? '4.8';
    final earnings  = profileData?['totalEarnings'] != null
        ? (profileData!['totalEarnings'] as num).toDouble()
        : driver.totalEarnings;

    final items = [
      _StatData(icon: Icons.local_shipping_outlined,
          value: '$total', label: 'Total Trips'),
      _StatData(icon: Icons.inventory_2_outlined,
          value: '$completed', label: 'Completed'),
      _StatData(icon: Icons.star_border_rounded,
          value: rating, label: 'Rating', tappable: true),
      _StatData(
          icon: Icons.attach_money_rounded,
          value: '\$${(earnings / 1000).toStringAsFixed(1)}K',
          label: 'Earnings'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final fade  = i < fades.length  ? fades[i]  : const AlwaysStoppedAnimation(1.0);
          final slide = i < slides.length ? slides[i] : const AlwaysStoppedAnimation(Offset.zero);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: items[i].tappable
                  ? GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/reviews_ratings'),
                      child: _StatItem(
                          icon: items[i].icon,
                          value: items[i].value,
                          label: items[i].label,
                          theme: theme,
                          highlight: true))
                  : _StatItem(
                      icon: items[i].icon,
                      value: items[i].value,
                      label: items[i].label,
                      theme: theme),
            ),
          );
        }),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value, label;
  final bool tappable;
  const _StatData(
      {required this.icon,
      required this.value,
      required this.label,
      this.tappable = false});
}

// ── About Tab ─────────────────────────────────────────────────────────────
class _AboutTab extends StatefulWidget {
  final UserProvider user;
  final Map<String, dynamic>? profileData;
  final AppTheme theme;
  const _AboutTab({required this.user, required this.profileData, required this.theme});

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  final List<Animation<double>> _fades  = [];
  final List<Animation<Offset>> _slides = [];

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    for (int i = 0; i < 9; i++) {
      final start = (i * 0.10).clamp(0.0, 0.85);
      final end   = (start + 0.35).clamp(0.0, 1.0);
      _fades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _masterCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _slides.add(
          Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _masterCtrl,
                  curve: Interval(start, end, curve: Curves.easeOut))));
    }
  }

  @override
  void dispose() { _masterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final d = widget.profileData;

    // استخدم بيانات الباك أولاً، وإلا بيانات الـ provider، وإلا fallback
    final items = {
      'Full Name':      'محمود ناصر',
      'Email':         'mahmoud.nasser15@gmail.com',
      'Phone Number':    '+02 01094357481',
      'License Number': d?['licenseNumber']                     ?? (u.licenseNumber.isNotEmpty  ? u.licenseNumber  : 'CDL-A-123456'),
      'License Type':   'Class B CDL',
      'Truck Plate':    d?['plateNumber']   ?? d?['truckPlate'] ?? (u.plateNumber.isNotEmpty    ? u.plateNumber    : 'TRK-5432'),
      'Truck Type':     d?['truckType']                         ?? (u.truckType.isNotEmpty      ? u.truckType      : 'Heavy Duty Semi'),
      'Capacity':       d?['capacity']?.toString()              ?? (u.capacity.isNotEmpty       ? u.capacity       : '25 Tons'),
      'Documents':      'View All Documents',
    };

    final keys   = items.keys.toList();
    final values = items.values.toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Driver Information',
          style: TextStyle(
              color: widget.theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: widget.theme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.theme.border)),
        child: Column(
          children: List.generate(keys.length, (i) {
            final isDoc = keys[i] == 'Documents';
            final fade  = i < _fades.length  ? _fades[i]  : const AlwaysStoppedAnimation(1.0);
            final slide = i < _slides.length ? _slides[i] : const AlwaysStoppedAnimation(Offset.zero);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    SizedBox(
                        width: 120,
                        child: Text(keys[i],
                            style: TextStyle(
                                color: widget.theme.textMuted,
                                fontSize: 13))),
                    Expanded(
                      child: Text(values[i]!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: isDoc
                                  ? AppTheme.primary
                                  : widget.theme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

// ── Shipments Tab — بيجيب الـ trips من الباك ─────────────────────────────
class _ShipmentsTab extends StatefulWidget {
  final DriverProvider driver;
  final AppTheme theme;
  const _ShipmentsTab({required this.driver, required this.theme});

  @override
  State<_ShipmentsTab> createState() => _ShipmentsTabState();
}

class _ShipmentsTabState extends State<_ShipmentsTab>
    with TickerProviderStateMixin {
  final DriverService _driverService = DriverService();
  bool _loading = true;
  List<dynamic> _trips = [];

  late AnimationController _masterCtrl;
  final List<Animation<double>> _fades  = [];
  final List<Animation<Offset>> _slides = [];

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    for (int i = 0; i < 3; i++) {
      final start = i * 0.25;
      final end   = (start + 0.5).clamp(0.0, 1.0);
      _fades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _masterCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _slides.add(
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: _masterCtrl,
                  curve: Interval(start, end, curve: Curves.easeOut))));
    }
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    final result = await _driverService.getRecentTrips();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data['data'] is List) {
          _trips = data['data'] as List;
        } else if (data is List) {
          _trips = data;
        }
      }
    });
  }

  @override
  void dispose() { _masterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // fallback على الـ provider لو الـ API فارغ
    final displayTrips = _trips.isNotEmpty
        ? _trips.take(3).toList()
        : widget.driver.recentTrips.take(3).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Shipments',
            style: TextStyle(
                color: widget.theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/trips'),
          child: const Text('View All',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      if (_loading)
        const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_kPrimary)),
        ))
      else
        ...List.generate(displayTrips.length, (i) {
          final fade  = i < _fades.length  ? _fades[i]  : const AlwaysStoppedAnimation(1.0);
          final slide = i < _slides.length ? _slides[i] : const AlwaysStoppedAnimation(Offset.zero);
          final trip  = displayTrips[i];
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: trip is CompletedTrip
                  ? _TripCard(trip: trip, theme: widget.theme)
                  : _TripCardFromMap(data: trip as Map<String, dynamic>, theme: widget.theme),
            ),
          );
        }),
    ]);
  }
}

// بطاقة Trip من Map (من الباك مباشرة)
class _TripCardFromMap extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppTheme theme;
  const _TripCardFromMap({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final id          = data['tripId']        ?? data['id']          ?? '';
    final origin      = data['pickupLocation'] ?? data['origin']     ?? '';
    final destination = data['dropoffLocation'] ?? data['destination'] ?? '';
    final amount      = data['amountEGP']     ?? data['earnings']    ?? 0;
    final time        = data['earnedAtFormatted'] ?? data['time']    ?? '';
    final miles       = data['distanceKm']    ?? data['miles']       ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$id',
              style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
            child: const Text('Completed',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('$origin → $destination',
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('$amount EGP',
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.access_time_outlined, color: theme.textMuted, size: 13),
          const SizedBox(width: 4),
          Text('$time',
              style: TextStyle(color: theme.textMuted, fontSize: 12)),
          const SizedBox(width: 14),
          Icon(Icons.trending_up_rounded, color: theme.textMuted, size: 13),
          const SizedBox(width: 4),
          Text('$miles km',
              style: TextStyle(color: theme.textMuted, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  2.  DRIVER SETTINGS
// ══════════════════════════════════════════════════════════════════════════
class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen>
    with TickerProviderStateMixin {
  final DriverService _driverService = DriverService();

  late AnimationController _pageCtrl;
  late AnimationController _avatarCtrl;
  final List<AnimationController> _itemCtrls  = [];
  final List<Animation<double>>   _itemFades  = [];
  final List<Animation<Offset>>   _itemSlides = [];

  late Animation<double> _pageFade;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _avatarCtrl.forward(); });

    for (int i = 0; i < 9; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350));
      _itemCtrls.add(c);
      _itemFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _itemSlides.add(
          Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 250 + i * 60),
          () { if (mounted) c.forward(); });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _avatarCtrl.dispose();
    for (final c in _itemCtrls) c.dispose();
    super.dispose();
  }

  Widget _animatedItem(int i, Widget child) {
    final fade  = i < _itemFades.length  ? _itemFades[i]  : const AlwaysStoppedAnimation(1.0);
    final slide = i < _itemSlides.length ? _itemSlides[i] : const AlwaysStoppedAnimation(Offset.zero);
    return FadeTransition(
        opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final user  = context.watch<UserProvider>();
    final theme = context.watch<ThemeProvider>().theme;
    const name  = 'محمود ناصر';
    const email = 'mahmoud.nasser15@gmail.com';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: _PressScale(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.card, shape: BoxShape.circle,
              border: Border.all(color: theme.border),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.primary, size: 16),
          ),
        ),
        title: Text('Profile',
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _pageFade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 8),
            ScaleTransition(
              scale: _avatarScale,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: theme.border),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 80, height: 80,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE05E3A), Color(0xFFB44AA0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle,
                        border: Border.all(color: theme.card, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 12, color: Colors.white),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(name,
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(color: theme.textMuted, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            _animatedItem(0, _MenuItem(
              icon: Icons.person_outline,
              title: 'Your Profile',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/driver_profile'),
            )),
            _animatedItem(1, _MenuItem(
              icon: Icons.star_outline_rounded,
              title: 'Reviews & Ratings',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/reviews_ratings'),
            )),
            _animatedItem(2, _MenuItem(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/driver_notifications'),
            )),
            _animatedItem(3, _DarkModeItem(theme: theme)),
            _animatedItem(4, _MenuItem(
              icon: Icons.settings_outlined,
              title: 'Advanced Settings',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/advanced_settings'),
            )),
            _animatedItem(5, _MenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'My Earnings',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/driver_earnings'),
            )),
            _animatedItem(6, _MenuItem(
              icon: Icons.wallet_outlined,
              title: 'My Wallet',
              theme: theme,
              onTap: () => Navigator.pushNamed(context, '/my_wallet'),
            )),
            _animatedItem(7, _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Support',
              theme: theme,
              onTap: () {},
            )),
            _animatedItem(8, _MenuItem(
              icon: Icons.logout_rounded,
              title: 'Log out',
              theme: theme,
              isLogout: true,
              onTap: () => _confirmLogout(context, theme),
            )),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppTheme theme) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => _LogoutDialog(
        theme: theme,
        driverService: _driverService,
      ),
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

// ── Logout Dialog ─────────────────────────────────────────────────────────
class _LogoutDialog extends StatefulWidget {
  final AppTheme theme;
  final DriverService driverService;
  const _LogoutDialog({required this.theme, required this.driverService});

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<double> _pulseOpacity;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
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
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  // ✅ Logout حقيقي — بيكلم الباك ويمسح التوكن
  Future<void> _doLogout() async {
    setState(() => _loggingOut = true);
    final authService = AuthService();
    await authService.logout(); // POST /api/auth/logout + clear token
    if (!mounted) return;
    Navigator.pop(context); // اقفل الـ dialog
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.border),
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
                      color: _kRed.withOpacity(0.25),
                    ),
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
                  color: theme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          Text('Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted, fontSize: 14)),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border),
            ),
            child: Text(
              "You'll need to sign in again to access your account",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.textMuted, fontSize: 12, height: 1.5),
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
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kPrimary.withOpacity(0.5)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.close_rounded, color: _kPrimary, size: 18),
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
                onTap: _loggingOut ? () {} : _doLogout,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF2D55), _kRed]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: _kRed.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _loggingOut
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                        :  Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.logout_rounded, color: Colors.white, size: 18),
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
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Animated dialog ────────────────────────────────────────────────────────
class _AnimatedDialog extends StatefulWidget {
  final AppTheme theme;
  final String title, content, confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  const _AnimatedDialog(
      {required this.theme,
      required this.title,
      required this.content,
      required this.confirmLabel,
      required this.confirmColor,
      required this.onConfirm});

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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: AlertDialog(
          backgroundColor: widget.theme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(widget.title,
              style: TextStyle(
                  color: widget.theme.textPrimary,
                  fontWeight: FontWeight.bold)),
          content: Text(widget.content,
              style: TextStyle(color: widget.theme.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: widget.theme.textMuted))),
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
}

// ══════════════════════════════════════════════════════════════════════════
//  3.  REVIEWS & RATINGS — بيجيب الـ reviews من الباك
// ══════════════════════════════════════════════════════════════════════════
class ReviewsRatingsScreen extends StatefulWidget {
  const ReviewsRatingsScreen({super.key});

  @override
  State<ReviewsRatingsScreen> createState() => _ReviewsRatingsScreenState();
}

class _ReviewsRatingsScreenState extends State<ReviewsRatingsScreen>
    with TickerProviderStateMixin {
  bool _showAll = false;
  bool _loadingReviews = false;
  List<dynamic> _reviews = [];
  double _avgRating = 4.8;
  int _totalReviews = 124;

  // fallback static reviews لو الـ API مجاش
  static const _staticReviews = [
    (name: 'Ahmed Mohamed', rating: 5, date: '2 days ago',
     body: 'Excellent driver! Very professional and on time.'),
    (name: 'Sara Ali', rating: 4, date: '1 week ago',
     body: 'Good service, recommended!'),
    (name: 'Khaled Hassan', rating: 5, date: '2 weeks ago',
     body: 'Perfect delivery, thank you!'),
    (name: 'Mona Ibrahim', rating: 4, date: '3 weeks ago',
     body: 'Very good experience overall.'),
  ];

  late AnimationController _pageCtrl;
  late AnimationController _scoreCtrl;
  late AnimationController _barsCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;
  late Animation<double>   _scoreScale;
  late Animation<double>   _scoreFade;

  final List<Animation<double>> _barAnims = [];

  static const _bars = [
    (stars: 5, pct: 0.75),
    (stars: 4, pct: 0.15),
    (stars: 3, pct: 0.06),
    (stars: 2, pct: 0.03),
    (stars: 1, pct: 0.01),
  ];

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scoreScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut));
    _scoreFade  = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _scoreCtrl.forward(); });

    _barsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    for (final bar in _bars) {
      _barAnims.add(Tween<double>(begin: 0.0, end: bar.pct).animate(
          CurvedAnimation(parent: _barsCtrl, curve: Curves.easeOut)));
    }
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _barsCtrl.forward(); });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scoreCtrl.dispose();
    _barsCtrl.dispose();
    super.dispose();
  }

  // ✅ جيب الـ reviews من الباك لما يضغط "View All Reviews"
  Future<void> _fetchReviews(String driverId) async {
    if (_loadingReviews) return;
    setState(() => _loadingReviews = true);
    try {
      final apiService = DriverService();
      // GET /api/review/driver/{driverId}
      final result = await apiService.getDriverReviews(driverId: driverId);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        final list = data?['data'] ?? data?['reviews'] ?? data;
        if (list is List) _reviews = list;
        final avg = data?['averageRating'] ?? data?['rating'];
        if (avg != null) _avgRating = (avg as num).toDouble();
        final total = data?['totalReviews'] ?? data?['count'];
        if (total != null) _totalReviews = total as int;
      }
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user  = context.watch<UserProvider>();
    final theme = context.watch<ThemeProvider>().theme;
    final name  = user.fullName.isNotEmpty ? user.fullName : 'محمود ناصر';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFade,
          child: SlideTransition(
            position: _pageSlide,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: _BackBtn(theme: theme),
                  ),
                  const SizedBox(width: 14),
                  Text('Reviews & Ratings',
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.border)),
                      child: Column(children: [
                        Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE05E3A), Color(0xFFB44AA0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: AppTheme.primary, width: 2.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22)),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.card, width: 2)),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text(name,
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('Driver',
                            style: TextStyle(color: theme.textMuted, fontSize: 14)),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _scoreFade,
                          child: ScaleTransition(
                            scale: _scoreScale,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppTheme.primary, size: 36),
                                const SizedBox(width: 8),
                                Text(_avgRating.toStringAsFixed(1),
                                    style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Based on $_totalReviews reviews',
                            style: TextStyle(color: theme.textMuted, fontSize: 14)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ratings Breakdown',
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 18),
                          ...List.generate(_bars.length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(children: [
                              Text('${_bars[i].stars}',
                                  style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.primary, size: 14),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: i < _barAnims.length
                                      ? _barAnims[i]
                                      : const AlwaysStoppedAnimation(0.0),
                                  builder: (_, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: i < _barAnims.length
                                          ? _barAnims[i].value
                                          : _bars[i].pct,
                                      minHeight: 6,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 36,
                                child: Text(
                                    '${(_bars[i].pct * 100).round()}%',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: theme.textMuted, fontSize: 12)),
                              ),
                            ]),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF009EA3), AppTheme.primary]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final newState = !_showAll;
                          setState(() => _showAll = newState);
                          if (newState && _reviews.isEmpty) {
                            final driverId = '';
                            _fetchReviews(driverId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        child: Text(
                            _showAll ? 'Hide Reviews' : 'View All Reviews',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (_showAll) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Recent Reviews',
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingReviews)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(_kPrimary)),
                        )
                      else if (_reviews.isNotEmpty)
                        // بيانات حقيقية من الباك
                        ..._reviews.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value as Map<String, dynamic>;
                          final reviewerName = r['reviewerName'] ?? r['traderName'] ?? 'User';
                          final rating = (r['rating'] as num?)?.toInt() ?? 5;
                          final date = r['createdAtFormatted'] ?? r['date'] ?? '';
                          final body = r['comment'] ?? r['body'] ?? '';
                          return _ReviewCard(
                            name: reviewerName, rating: rating,
                            date: date, body: body,
                            index: i, theme: theme,
                          );
                        })
                      else
                        // fallback static
                        ..._staticReviews.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return _ReviewCard(
                            name: r.name, rating: r.rating,
                            date: r.date, body: r.body,
                            index: i, theme: theme,
                          );
                        }),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name, date, body;
  final int rating, index;
  final AppTheme theme;
  const _ReviewCard({
    required this.name, required this.rating,
    required this.date, required this.body,
    required this.index, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(child: Text(name[0],
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(date,
                    style: TextStyle(color: theme.textMuted, fontSize: 12)),
              ],
            )),
            Row(children: List.generate(5, (j) =>
                Icon(
                  j < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppTheme.primary, size: 16))),
          ]),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13, height: 1.4)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  4.  ADVANCED SETTINGS
// ══════════════════════════════════════════════════════════════════════════
class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageCtrl;
  late AnimationController _cardCtrl;
  final List<AnimationController> _sectionCtrls  = [];
  final List<Animation<double>>   _sectionFades  = [];
  final List<Animation<Offset>>   _sectionSlides = [];

  late Animation<double> _pageFade;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardScale = Tween<double>(begin: 0.93, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _cardCtrl.forward(); });

    for (int i = 0; i < 4; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400));
      _sectionCtrls.add(c);
      _sectionFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
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
        opacity: fade, child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final user  = context.watch<UserProvider>();
    final theme = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _PressScale(
                  onTap: () => Navigator.pop(context),
                  child: _BackBtn(theme: theme),
                ),
                const SizedBox(width: 14),
                Text('Advanced Settings',
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 24),
              ScaleTransition(
                scale: _cardScale,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.border)),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE05E3A), Color(0xFFB44AA0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(user.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        user.fullName.isNotEmpty ? user.fullName : 'Driver',
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
                        child: const Text('Driver',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
              _animated(0, _section('ACCOUNT SECURITY', [
                _SettingsRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    theme: theme,
                    onTap: () => Navigator.pushNamed(context, '/change_password')),
                _SettingsRow(
                    icon: Icons.mail_outline_rounded,
                    title: 'Update Email / Phone',
                    subtitle: 'Manage your contact information',
                    theme: theme,
                    onTap: () => Navigator.pushNamed(context, '/update_contact'),
                    isLast: true),
              ], theme)),
              _animated(1, _section('PREFERENCES', [
                _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Preferences',
                    subtitle: 'Control how and when you receive notifications',
                    theme: theme,
                    onTap: () => Navigator.pushNamed(context, '/notification_preferences'),
                    isLast: true),
              ], theme)),
              _animated(2, _section('PRIVACY & LEGAL', [
                _SettingsRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    subtitle: 'Manage privacy and data permissions',
                    theme: theme, onTap: () {}),
                _SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Policies',
                    subtitle: 'View terms, privacy policy, and agreements',
                    theme: theme, onTap: () {}, isLast: true),
              ], theme)),
              _animated(3, _PressScale(
                onTap: () => _deleteDialog(context, theme),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kRed.withOpacity(0.3))),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: _kRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: _kRed, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Account',
                            style: TextStyle(
                                color: _kRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Permanently remove your account and data',
                            style: TextStyle(color: _kRed, fontSize: 12)),
                      ],
                    )),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: _kRed, size: 14),
                  ]),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> items, AppTheme theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              color: theme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Container(
          decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.border)),
          child: Column(children: items)),
      const SizedBox(height: 24),
    ]);
  }

  void _deleteDialog(BuildContext context, AppTheme theme) {
    showDialog(
      context: context,
      builder: (_) => _AnimatedDialog(
        theme: theme,
        title: 'Delete Account',
        content: 'Are you sure? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: _kRed,
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  5.  NOTIFICATION PREFERENCES — بتجيب وبتبعت الـ settings للباك
// ══════════════════════════════════════════════════════════════════════════
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NPState();
}

class _NPState extends State<NotificationPreferencesScreen>
    with TickerProviderStateMixin {
  final DriverService _driverService = DriverService();
  bool _initialLoading = true;
  bool _saving = false;

  // ── notification toggles ──
  bool _newShipment = true, _assigned = true, _pickedUp = true,
      _cancelled = true, _reminder = false, _delivery = true;
  bool _chat = true, _trader = true, _calls = false;
  bool _payment = true, _withdrawal = true, _rating = true, _review = false;
  bool _announce = true, _maintenance = false, _docs = true;

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

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
    _fetchSettings();
  }

  // ✅ جيب الـ notification settings من الباك
  Future<void> _fetchSettings() async {
    final result = await _driverService.getNotificationSettings();
    if (!mounted) return;
    setState(() => _initialLoading = false);
    if (result['success'] == true) {
      final d = result['data']?['data'] ?? result['data'];
      if (d is Map<String, dynamic>) {
        setState(() {
          _newShipment  = d['newShipment']   ?? _newShipment;
          _assigned     = d['assigned']      ?? _assigned;
          _pickedUp     = d['pickedUp']      ?? _pickedUp;
          _cancelled    = d['cancelled']     ?? _cancelled;
          _reminder     = d['reminder']      ?? _reminder;
          _delivery     = d['delivery']      ?? _delivery;
          _chat         = d['chat']          ?? _chat;
          _trader       = d['trader']        ?? _trader;
          _calls        = d['calls']         ?? _calls;
          _payment      = d['payment']       ?? _payment;
          _withdrawal   = d['withdrawal']    ?? _withdrawal;
          _rating       = d['rating']        ?? _rating;
          _review       = d['review']        ?? _review;
          _announce     = d['announce']      ?? _announce;
          _maintenance  = d['maintenance']   ?? _maintenance;
          _docs         = d['docs']          ?? _docs;
        });
      }
    }
  }

  // ✅ احفظ الـ notification settings في الباك
  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    final settings = {
      'newShipment': _newShipment, 'assigned': _assigned,
      'pickedUp': _pickedUp,       'cancelled': _cancelled,
      'reminder': _reminder,       'delivery': _delivery,
      'chat': _chat,               'trader': _trader,
      'calls': _calls,             'payment': _payment,
      'withdrawal': _withdrawal,   'rating': _rating,
      'review': _review,           'announce': _announce,
      'maintenance': _maintenance, 'docs': _docs,
    };
    final result = await _driverService.updateNotificationSettings(settings);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true
            ? 'Preferences saved!'
            : result['message'] ?? 'Failed to save'),
        backgroundColor: result['success'] == true ? AppTheme.primary : _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    if (result['success'] == true) Navigator.pop(context);
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user  = context.watch<UserProvider>();
    final theme = context.watch<ThemeProvider>().theme;

    if (_initialLoading) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_kPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: _BackBtn(theme: theme),
                  ),
                  const SizedBox(width: 14),
                  Text('Notification Preferences',
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _profileCard(user, theme),
                    const SizedBox(height: 22),
                    _prefSection('TRIP UPDATES', [
                      _prefRow(Icons.notifications_none_rounded, 'New Shipment Available', _newShipment, (v) => setState(() => _newShipment = v), theme),
                      _prefRow(Icons.local_shipping_outlined, 'Shipment Assigned to You', _assigned, (v) => setState(() => _assigned = v), theme),
                      _prefRow(Icons.inventory_2_outlined, 'Shipment Picked Up', _pickedUp, (v) => setState(() => _pickedUp = v), theme),
                      _prefRow(Icons.cancel_outlined, 'Shipment Cancelled', _cancelled, (v) => setState(() => _cancelled = v), theme),
                      _prefRow(Icons.location_on_outlined, 'Trip Started Reminder', _reminder, (v) => setState(() => _reminder = v), theme),
                      _prefRow(Icons.check_box_outlined, 'Delivery Confirmation Required', _delivery, (v) => setState(() => _delivery = v), theme, isLast: true),
                    ], theme),
                    _prefSection('COMMUNICATION', [
                      _prefRow(Icons.chat_bubble_outline_rounded, 'Messages / Chat Notifications', _chat, (v) => setState(() => _chat = v), theme),
                      _prefRow(Icons.person_outline_rounded, 'Trader Contact Alerts', _trader, (v) => setState(() => _trader = v), theme),
                      _prefRow(Icons.call_outlined, 'Call Notifications', _calls, (v) => setState(() => _calls = v), theme, isLast: true),
                    ], theme),
                    _prefSection('EARNINGS & REVIEWS', [
                      _prefRow(Icons.attach_money_rounded, 'New Payment Added', _payment, (v) => setState(() => _payment = v), theme),
                      _prefRow(Icons.account_balance_wallet_outlined, 'Withdrawal Approved', _withdrawal, (v) => setState(() => _withdrawal = v), theme),
                      _prefRow(Icons.star_outline_rounded, 'New Rating Received', _rating, (v) => setState(() => _rating = v), theme),
                      _prefRow(Icons.description_outlined, 'New Review Received', _review, (v) => setState(() => _review = v), theme, isLast: true),
                    ], theme),
                    _prefSection('SYSTEM ALERTS', [
                      _prefRow(Icons.campaign_outlined, 'App Announcements', _announce, (v) => setState(() => _announce = v), theme),
                      _prefRow(Icons.warning_amber_outlined, 'Maintenance Alerts', _maintenance, (v) => setState(() => _maintenance = v), theme),
                      _prefRow(Icons.folder_outlined, 'Document Expiry Alerts', _docs, (v) => setState(() => _docs = v), theme, isLast: true),
                    ], theme),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
            color: theme.bg,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF009EA3), AppTheme.primary]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6))]),
          child: ElevatedButton(
            onPressed: _saving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Save Preferences',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _profileCard(UserProvider user, AppTheme theme) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.15),
                border: Border.all(color: AppTheme.primary, width: 1.5)),
            alignment: Alignment.center,
            child: Text(user.initials,
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.fullName.isNotEmpty ? user.fullName : 'Driver',
                style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: const Text('Driver', style: TextStyle(color: AppTheme.primary, fontSize: 11)),
            ),
          ]),
        ]),
      );

  Widget _prefSection(String title, List<Widget> items, AppTheme theme) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: theme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
            decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border)),
            child: Column(children: items)),
        const SizedBox(height: 22),
      ]);

  Widget _prefRow(IconData icon, String title, bool value,
          ValueChanged<bool> onChanged, AppTheme theme,
          {bool isLast = false}) =>
      Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppTheme.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withOpacity(0.3),
              inactiveThumbColor: theme.textMuted,
              inactiveTrackColor: theme.cardDeep,
            ),
          ]),
        ),
        if (!isLast) Divider(height: 1, color: theme.border, indent: 62),
      ]);
}

// ══════════════════════════════════════════════════════════════════════════
//  6.  DRIVER NOTIFICATIONS
// ══════════════════════════════════════════════════════════════════════════
class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState
    extends State<DriverNotificationsScreen> with TickerProviderStateMixin {

  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  late AnimationController _todayLabelCtrl;
  late Animation<double>   _todayLabelFade;

  late AnimationController _earlierLabelCtrl;
  late Animation<double>   _earlierLabelFade;

  final List<AnimationController> _cardCtrls  = [];
  final List<Animation<double>>   _cardFades  = [];
  final List<Animation<Offset>>   _cardSlides = [];

  final List<AnimationController> _dotCtrls   = [];
  final List<Animation<double>>   _dotScales  = [];

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseScale;
  late Animation<double>   _pulseOpacity;

  late AnimationController _progressCtrl;
  late Animation<double>   _progressAnim;

  late AnimationController _wobbleCtrl;
  late Animation<double>   _wobbleAngle;

  static const _groups = [
    (label: 'Today', items: [
      (time: '10:15 AM', type: 'running', progress: 0.47,
       title: 'Trip in progress',
       body: 'Your trip from Maadi to Nasr City is currently active'),
      (time: '', type: 'completed', progress: 1.0,
       title: 'Trip completed',
       body: 'Delivery to Nasr City has been completed successfully'),
    ]),
    (label: 'Earlier', items: [
      (time: '6:20 PM', type: 'alert', progress: -1.0,
       title: 'New offer received',
       body: 'A new delivery offer is available for you'),
      (time: '5:10 PM', type: 'completed', progress: -1.0,
       title: 'Payment added',
       body: '850 EGP has been added to your wallet'),
    ]),
  ];

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const _SpringCurve(stiffness: 120, damping: 18, mass: 0.5)));
    Future.delayed(const Duration(milliseconds: 100),
        () { if (mounted) _headerCtrl.forward(); });

    _todayLabelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _todayLabelFade = CurvedAnimation(parent: _todayLabelCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 250),
        () { if (mounted) _todayLabelCtrl.forward(); });

    _earlierLabelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _earlierLabelFade = CurvedAnimation(parent: _earlierLabelCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 700),
        () { if (mounted) _earlierLabelCtrl.forward(); });

    const int delayChildren  = 300;
    const int staggerMs      = 120;
    for (int i = 0; i < 4; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700));
      _cardCtrls.add(c);
      _cardFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _cardSlides.add(
          Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: c,
                  curve: const _SpringCurve(stiffness: 120, damping: 18, mass: 0.8))));
      Future.delayed(
          Duration(milliseconds: delayChildren + i * staggerMs),
          () { if (mounted) c.forward(); });
    }

    for (int i = 0; i < 4; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _dotCtrls.add(c);
      _dotScales.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: c,
              curve: const _SpringCurve(stiffness: 200, damping: 15, mass: 1.0))));
      Future.delayed(
          Duration(milliseconds: delayChildren + i * staggerMs + 200),
          () { if (mounted) c.forward(); });
    }

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pulseScale   = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.6), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _progressAnim = Tween<double>(begin: 0.0, end: 0.47).animate(
        CurvedAnimation(parent: _progressCtrl,
            curve: const Cubic(0.4, 0.0, 0.2, 1.0)));
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) _progressCtrl.forward(); });

    _wobbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _wobbleAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0 * math.pi / 180), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 5.0 * math.pi / 180, end: -5.0 * math.pi / 180), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -5.0 * math.pi / 180, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _todayLabelCtrl.dispose();
    _earlierLabelCtrl.dispose();
    for (final c in _cardCtrls)  c.dispose();
    for (final c in _dotCtrls)   c.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  Color _color(String type) {
    if (type == 'alert') return _kOrange;
    return _kPrimary;
  }

  IconData _icon(String type) {
    if (type == 'alert') return Icons.warning_amber_rounded;
    if (type == 'running') return Icons.local_shipping_outlined;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    int cardIdx = 0;

    return Scaffold(
      backgroundColor: theme.bg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: _BackBtn(theme: theme),
                  ),
                  const SizedBox(width: 14),
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Text('Notifications',
                          style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.border)),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _groups.map((group) {
                        final isToday = group.label == 'Today';
                        final labelFade = isToday ? _todayLabelFade : _earlierLabelFade;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeTransition(
                              opacity: labelFade,
                              child: Text(group.label,
                                  style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 16),
                            ...group.items.asMap().entries.map((entry) {
                              final i    = entry.key;
                              final item = entry.value;
                              final ci   = cardIdx++;
                              final color = _color(item.type);
                              final isRunning = item.type == 'running';
                              final hasProgress = item.progress >= 0 && isRunning;
                              final isLastInGroup = i == group.items.length - 1;

                              final cardFade  = ci < _cardFades.length  ? _cardFades[ci]  : const AlwaysStoppedAnimation(1.0);
                              final cardSlide = ci < _cardSlides.length ? _cardSlides[ci] : const AlwaysStoppedAnimation(Offset.zero);
                              final dotScale  = ci < _dotScales.length  ? _dotScales[ci]  : const AlwaysStoppedAnimation(1.0);

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Column(children: [
                                        ScaleTransition(
                                          scale: dotScale,
                                          child: SizedBox(
                                            width: 24, height: 24,
                                            child: Stack(alignment: Alignment.center, children: [
                                              if (isRunning)
                                                AnimatedBuilder(
                                                  animation: _pulseCtrl,
                                                  builder: (_, __) => Transform.scale(
                                                    scale: _pulseScale.value,
                                                    child: Opacity(
                                                      opacity: _pulseOpacity.value,
                                                      child: Container(
                                                        width: 24, height: 24,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: color.withOpacity(0.6),
                                                          boxShadow: [BoxShadow(
                                                            color: color.withOpacity(0.5),
                                                            blurRadius: 12, spreadRadius: 2)],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                width: 24, height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: color.withOpacity(0.3),
                                                  border: Border.all(color: color, width: 1.6),
                                                ),
                                                child: Center(
                                                  child: isRunning
                                                    ? AnimatedBuilder(
                                                        animation: _pulseCtrl,
                                                        builder: (_, __) => Transform.scale(
                                                          scale: _pulseScale.value * 0.9,
                                                          child: Container(
                                                            width: 8, height: 8,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape.circle, color: color),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 8, height: 8,
                                                        decoration: BoxDecoration(
                                                            shape: BoxShape.circle, color: color),
                                                      ),
                                                ),
                                              ),
                                            ]),
                                          ),
                                        ),
                                        if (!isLastInGroup)
                                          Expanded(child: Container(
                                            width: 2,
                                            color: _kPrimary.withOpacity(0.2),
                                          )),
                                      ]),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FadeTransition(
                                        opacity: cardFade,
                                        child: SlideTransition(
                                          position: cardSlide,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (item.time.isNotEmpty) ...[
                                                  Text(item.time,
                                                      style: TextStyle(
                                                          color: theme.textMuted.withOpacity(0.7),
                                                          fontSize: 11)),
                                                  const SizedBox(height: 6),
                                                ],
                                                Container(
                                                  decoration: BoxDecoration(
                                                      color: theme.cardDeep,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: color.withOpacity(0.2))),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                                        child: Row(children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                            decoration: BoxDecoration(
                                                                color: color.withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(20)),
                                                            child: Text(
                                                                item.type[0].toUpperCase() + item.type.substring(1),
                                                                style: TextStyle(
                                                                    color: color,
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w600)),
                                                          ),
                                                          if (hasProgress) ...[
                                                            const SizedBox(width: 8),
                                                            Expanded(child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(99),
                                                              child: AnimatedBuilder(
                                                                animation: _progressAnim,
                                                                builder: (_, __) => LinearProgressIndicator(
                                                                  value: _progressAnim.value,
                                                                  minHeight: 4,
                                                                  backgroundColor: Colors.white.withOpacity(0.1),
                                                                  valueColor: AlwaysStoppedAnimation(color),
                                                                ),
                                                              ),
                                                            )),
                                                            const SizedBox(width: 8),
                                                            AnimatedBuilder(
                                                              animation: _progressAnim,
                                                              builder: (_, __) => Text(
                                                                '${(_progressAnim.value * 100).round()}%',
                                                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                                                              ),
                                                            ),
                                                          ],
                                                          if (!hasProgress && item.progress == 1.0) ...[
                                                            const SizedBox(width: 8),
                                                            Expanded(child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(99),
                                                              child: LinearProgressIndicator(
                                                                value: 1.0,
                                                                minHeight: 4,
                                                                backgroundColor: Colors.white.withOpacity(0.1),
                                                                valueColor: AlwaysStoppedAnimation(color),
                                                              ),
                                                            )),
                                                            const SizedBox(width: 8),
                                                            Text('100%',
                                                                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                                                          ],
                                                        ]),
                                                      ),
                                                      Container(
                                                        margin: const EdgeInsets.all(10),
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                            color: theme.card,
                                                            borderRadius: BorderRadius.circular(12)),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            isRunning
                                                              ? AnimatedBuilder(
                                                                  animation: _wobbleAngle,
                                                                  builder: (_, child) => Transform.rotate(
                                                                    angle: _wobbleAngle.value, child: child),
                                                                  child: Container(
                                                                    width: 36, height: 36,
                                                                    decoration: BoxDecoration(
                                                                        color: color.withOpacity(0.12),
                                                                        borderRadius: BorderRadius.circular(10)),
                                                                    child: Icon(_icon(item.type), color: color, size: 18),
                                                                  ),
                                                                )
                                                              : Container(
                                                                  width: 36, height: 36,
                                                                  decoration: BoxDecoration(
                                                                      color: color.withOpacity(0.12),
                                                                      borderRadius: BorderRadius.circular(10)),
                                                                  child: Icon(_icon(item.type), color: color, size: 18),
                                                                ),
                                                            const SizedBox(width: 10),
                                                            Expanded(child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(item.title,
                                                                    style: TextStyle(
                                                                        color: theme.textPrimary,
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.w600)),
                                                                const SizedBox(height: 4),
                                                                Text(item.body,
                                                                    style: TextStyle(
                                                                        color: theme.textMuted,
                                                                        fontSize: 12, height: 1.4)),
                                                              ],
                                                            )),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _SpringCurve
// ══════════════════════════════════════════════════════════════════════════
class _SpringCurve extends Curve {
  final double stiffness;
  final double damping;
  final double mass;

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
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════
class _BackBtn extends StatelessWidget {
  final AppTheme theme;
  const _BackBtn({required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primary, size: 16),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final AppTheme theme;
  const _IconBtn({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final AppTheme theme;
  final bool highlight;
  const _StatItem(
      {required this.icon,
      required this.value,
      required this.label,
      required this.theme,
      this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: highlight
                ? AppTheme.primary.withOpacity(0.15)
                : theme.cardDeep,
            shape: BoxShape.circle,
            border: highlight
                ? Border.all(color: AppTheme.primary.withOpacity(0.4))
                : null,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11)),
      ]);
}

class _TripCard extends StatelessWidget {
  final CompletedTrip trip;
  final AppTheme theme;
  const _TripCard({required this.trip, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trip.id,
                style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: const Text('Completed',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${trip.origin} → ${trip.destination}',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('\$${trip.earnings.toInt()}',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.access_time_outlined, color: theme.textMuted, size: 13),
            const SizedBox(width: 4),
            Text(trip.time,
                style: TextStyle(color: theme.textMuted, fontSize: 12)),
            const SizedBox(width: 14),
            Icon(Icons.trending_up_rounded, color: theme.textMuted, size: 13),
            const SizedBox(width: 4),
            Text('${trip.miles} km',
                style: TextStyle(color: theme.textMuted, fontSize: 12)),
          ]),
        ]),
      );
}

class _DarkModeItem extends StatelessWidget {
  final AppTheme theme;
  const _DarkModeItem({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(children: [
        Icon(Icons.dark_mode_outlined, color: AppTheme.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text('Dark Mode',
            style: TextStyle(color: theme.textPrimary, fontSize: 14))),
        Switch(
          value: theme.isDark,
          onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
          activeColor: AppTheme.primary,
          activeTrackColor: AppTheme.primary.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppTheme theme;
  final VoidCallback onTap;
  final bool isLogout;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.theme,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? _kRed : AppTheme.primary;
    return _PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title,
              style: TextStyle(
                  color: isLogout ? _kRed : theme.textPrimary,
                  fontSize: 14))),
          Icon(Icons.arrow_forward_ios_rounded,
              color: theme.textMuted, size: 14),
        ]),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final AppTheme theme;
  final VoidCallback onTap;
  final bool isLast;
  const _SettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.theme,
      required this.onTap,
      this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        _PressScale(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: theme.textMuted, fontSize: 12)),
                ],
              )),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: theme.textMuted, size: 14),
            ]),
          ),
        ),
        if (!isLast) Divider(height: 1, color: theme.border, indent: 70),
      ]);
}