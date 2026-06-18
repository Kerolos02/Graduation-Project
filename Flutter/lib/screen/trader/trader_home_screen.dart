import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/theme_provider.dart';
import '/models/trader_models.dart';
import '/data/trader_dummy_data.dart';
import '/screen/trader/trader_ui.dart';
import '/screen/trader/trader_new_shipment_screen.dart';
import '/screen/trader/trader_rating_screen.dart';
import '/screen/trader/trader_driver_screens.dart' hide OfferStatus;
import '/screen/trader/payment_screens.dart';
import '/providers/trader_provider.dart'; // ✅

// ══════════════════════════════════════════════════════════
//  ANIMATION CONSTANTS
// ══════════════════════════════════════════════════════════
const Duration _kFastAnim = Duration(milliseconds: 350);
const Duration _kMedAnim  = Duration(milliseconds: 500);
const Duration _kSlowAnim = Duration(milliseconds: 700);
const Duration _kStagger  = Duration(milliseconds: 80);

const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;
const Curve _kEaseInOut    = Curves.easeInOutCubic;

class TraderHomeScreen extends StatefulWidget {
  const TraderHomeScreen({super.key});
  @override
  State<TraderHomeScreen> createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen>
    with TickerProviderStateMixin {
  late List<Shipment> _shipments;
  late List<DriverOffer> _offers;
  late List<TraderNotification> _notifications;
  int _currentIndex = 0;bool _apiLoading = true;
  String _traderName = '';
  String _traderEmail = '';
  ShipmentStatus _mapApiStatus(dynamic v) {
    switch (v) {
      case 3: case 4:
      case 'inTransit':   return ShipmentStatus.inTransit;
      case 5:
      case 'delivered':   return ShipmentStatus.delivered;
      case 6:
      case 'cancelled':   return ShipmentStatus.cancelled;
      default:            return ShipmentStatus.pending;
    }
  }

  double _mapProgress(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.pending:   return 0.22;
      case ShipmentStatus.inTransit: return 0.64;
      case ShipmentStatus.delivered: return 1.0;
      case ShipmentStatus.cancelled: return 0.15;
    }
  }

  late AnimationController _pageEnterCtrl;
  late AnimationController _bottomNavCtrl;
  late AnimationController _tabSwitchCtrl;
  late AnimationController _staggerCtrl;
  late AnimationController _headerCtrl;
  late AnimationController _headerNameCtrl;
  late AnimationController _headerBtnsCtrl;
  late AnimationController _heroCtrl;
  late AnimationController _heroGlow1Ctrl;
  late AnimationController _heroGlow2Ctrl;
  late AnimationController _detailCtrl;
  late AnimationController _ctaCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _floatCtrl1;
  late AnimationController _floatCtrl2;
  late AnimationController _rotateCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;
  late Animation<Offset> _bottomNavSlide;
  late Animation<double> _tabFade;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerNameOpacity;
  late Animation<Offset> _headerNameSlide;
  late Animation<double> _headerBtnsOpacity;
  late Animation<Offset> _headerBtnsSlide;
  late Animation<double> _heroOpacity;
  late Animation<double> _heroScale;
  late Animation<Offset>  _heroSlide;
  late Animation<double> _heroGlow1;
  late Animation<double> _heroGlow2;
  late Animation<double> _detailOpacity;
  late Animation<Offset>  _detailSlide;
  late Animation<double> _ctaOpacity;
  late Animation<double> _ctaScale;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _floatAnim1;
  late Animation<double> _floatAnim2;
  late Animation<double> _rotateAnim;
  late Animation<double> _particleAnim;

  static const int _kStaggerCount = 10;
  late List<Animation<double>> _staggerFade;
  late List<Animation<Offset>>  _staggerSlide;

  @override
  void initState() {
    super.initState();
    _shipments     = [];
    _offers        = [];
    _notifications = TraderDummyData.notifications();

    // ✅ جيب البيانات الحقيقية من الـ API
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());

    _pageEnterCtrl = AnimationController(vsync: this, duration: _kMedAnim);
    _pageOpacity   = CurvedAnimation(parent: _pageEnterCtrl, curve: _kEaseOutCubic);
    _pageSlide     = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageEnterCtrl, curve: _kEaseOutCubic));

    _bottomNavCtrl  = AnimationController(vsync: this, duration: _kMedAnim);
    _bottomNavSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bottomNavCtrl, curve: _kEaseOutCubic));

    _tabSwitchCtrl = AnimationController(vsync: this, duration: _kFastAnim);
    _tabFade       = CurvedAnimation(parent: _tabSwitchCtrl, curve: _kEaseInOut);

    _headerCtrl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerOpacity    = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide      = Tween<Offset>(begin: const Offset(0, -0.025), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _headerNameCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerNameOpacity = CurvedAnimation(parent: _headerNameCtrl, curve: Curves.easeOut);
    _headerNameSlide   = Tween<Offset>(begin: const Offset(-0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerNameCtrl, curve: Curves.easeOut));

    _headerBtnsCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerBtnsOpacity = CurvedAnimation(parent: _headerBtnsCtrl, curve: Curves.easeOut);
    _headerBtnsSlide   = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerBtnsCtrl, curve: Curves.easeOut));

    _heroCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heroOpacity = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroScale   = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: const Cubic(0.22, 1, 0.36, 1)));
    _heroSlide   = Tween<Offset>(begin: const Offset(0, 0.065), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: const Cubic(0.22, 1, 0.36, 1)));

    _heroGlow1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _heroGlow1     = Tween<double>(begin: 0.10, end: 0.20)
        .animate(CurvedAnimation(parent: _heroGlow1Ctrl, curve: Curves.easeInOut));

    _heroGlow2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _heroGlow2     = Tween<double>(begin: 0.10, end: 0.20)
        .animate(CurvedAnimation(parent: _heroGlow2Ctrl, curve: Curves.easeInOut));

    _detailCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _detailOpacity = CurvedAnimation(parent: _detailCtrl, curve: Curves.easeOut);
    _detailSlide   = Tween<Offset>(begin: const Offset(0, 0.038), end: Offset.zero)
        .animate(CurvedAnimation(parent: _detailCtrl, curve: Curves.easeOut));

    _ctaCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ctaOpacity = CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeOut);
    _ctaScale   = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _floatCtrl1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat(reverse: true);
    _floatCtrl2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))
      ..repeat(reverse: true);
    _floatAnim1 = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _floatCtrl1, curve: Curves.easeInOut));
    _floatAnim2 = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _floatCtrl2, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _rotateAnim = Tween<double>(begin: -0.26, end: 0.26)
        .animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _particleAnim = CurvedAnimation(parent: _particleCtrl, curve: Curves.easeInOut);

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900 + _kStaggerCount * _kStagger.inMilliseconds),
    );
    _staggerFade = List.generate(_kStaggerCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.8);
      final end   = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(start, end, curve: _kEaseOutCubic)));
    });
    _staggerSlide = List.generate(_kStaggerCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.8);
      final end   = (start + 0.40).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(start, end, curve: _kEaseOutCubic)));
    });

    _runEnterSequence();
  }

  void _runEnterSequence() async {
    _bottomNavCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _pageEnterCtrl.forward();
    _staggerCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 100));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _headerNameCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _headerBtnsCtrl.forward();
    _heroCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _detailCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _ctaCtrl.forward();
    _tabSwitchCtrl.value = 1.0;
  }

  // ✅ جيب البيانات الحقيقية من الـ API
  Future<void> _loadData() async {
    final provider = context.read<TraderProvider>();

    await Future.wait([
      provider.loadHome(),
      provider.loadShipments(),
      provider.loadProfile(),
    ]);

    if (!mounted) return;
    setState(() {
      // ✅ الاسم من الـ profile
      if (provider.fullName.isNotEmpty) _traderName = provider.fullName;

      _apiLoading = false;

      // ✅ لو في shipments من الـ API، استخدمهم
      if (provider.shipments.isNotEmpty) {
        _shipments = provider.shipments.map((s) {
          final status = _parseStatus(s['status']?.toString() ?? 'pending');
          final driverName = s['driver']?['name'] ?? s['driverName'] ?? '';
          return Shipment(
            id:             s['id']?.toString() ?? '',
            title:          s['vehicleType']    ?? 'Delivery',
            reference:      s['shipmentId']?.toString() ?? s['id']?.toString() ?? '',
            origin:         s['pickupLocation'] ?? s['route']?['pickupLocation'] ?? '',
            destination:    s['dropOffLocation'] ?? s['route']?['dropoffLocation'] ?? '',
            status:         status,
            progress:       _progressFromStatus(status),
            departureDate:  s['scheduledDate']?.toString() ?? '',
            weightTons:     (s['weight']      as num?)?.toDouble() ?? 1.0,
            price:          (s['finalCost']   as num?)?.toDouble() ?? 0,
            driverName:     driverName.isNotEmpty ? driverName : 'Unassigned',
            driverInitials: makeInitials(driverName.isNotEmpty ? driverName : 'Unassigned'),
            vehicleInfo:    s['vehicleType']  ?? '',
            goodsType:      s['vehicleType']  ?? '',
            priority:       'Standard',
            cancelReason:   null,
            timeline: [
              const ShipmentMilestone(label: 'Created',    time: '', isDone: true),
              ShipmentMilestone(label: 'In Transit', time: '',
                  isDone: status == ShipmentStatus.inTransit || status == ShipmentStatus.delivered),
              ShipmentMilestone(label: 'Delivered',  time: '',
                  isDone: status == ShipmentStatus.delivered),
            ],
          );
        }).toList();
      }
    });
  }

  ShipmentStatus _parseStatus(String s) {
    switch (s) {
      case '3': case '4':
      case 'inTransit':   return ShipmentStatus.inTransit;
      case '5':
      case 'delivered':   return ShipmentStatus.delivered;
      case '6':
      case 'cancelled':   return ShipmentStatus.cancelled;
      default:            return ShipmentStatus.pending;
    }
  }

  double _progressFromStatus(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.pending:   return 0.22;
      case ShipmentStatus.inTransit: return 0.64;
      case ShipmentStatus.delivered: return 1.0;
      case ShipmentStatus.cancelled: return 0.15;
    }
  }

  @override
  void dispose() {
    _pageEnterCtrl.dispose();
    _bottomNavCtrl.dispose();
    _tabSwitchCtrl.dispose();
    _staggerCtrl.dispose();
    _headerCtrl.dispose();
    _headerNameCtrl.dispose();
    _headerBtnsCtrl.dispose();
    _heroCtrl.dispose();
    _heroGlow1Ctrl.dispose();
    _heroGlow2Ctrl.dispose();
    _detailCtrl.dispose();
    _ctaCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl1.dispose();
    _floatCtrl2.dispose();
    _rotateCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Widget _animItem(int index, Widget child) {
    final fade  = _staggerFade[index.clamp(0, _kStaggerCount - 1)];
    final slide = _staggerSlide[index.clamp(0, _kStaggerCount - 1)];
    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (_, __) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - fade.value)), child: child),
      ),
    );
  }

  // ✅ FIX 1 — _acceptOffer: بيغير الـ status + يودي للـ Payment
  void _acceptOffer(DriverOffer offer) {
    setState(() {
      _offers = _offers.map((item) => item.id == offer.id
          ? DriverOffer(
        id:             item.id,
        shipmentId:     item.shipmentId,
        driverName:     item.driverName,
        driverInitials: item.driverInitials,
        rating:         item.rating,
        completedTrips: item.completedTrips,
        price:          item.price,
        etaHours:       item.etaHours,
        vehicleType:    item.vehicleType,
        status:         OfferStatus.accepted,
        note:           item.note,
      )
          : item).toList();
    });

    // ✅ navigate للـ PaymentMethodsSelectScreen مع بيانات الـ driver
    Navigator.push(
      context,
      _slideUpRoute(PaymentMethodsSelectScreen(
        driverName:     offer.driverName,
        driverInitials: offer.driverInitials,
        price:          offer.price,
      )),
    );
  }

  Future<void> _switchTab(int index) async {
    if (index == _currentIndex) return;
    await _tabSwitchCtrl.reverse();
    setState(() => _currentIndex = index);
    _tabSwitchCtrl.forward();
    if (index == 0) {
      _staggerCtrl.forward(from: 0);
      _heroCtrl..reset()..forward();
    }
  }

  Future<void> _logout() async {
    final t = TraderTheme(isDark: context.read<ThemeProvider>().isDark);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: t.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: t.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(
                      color: TraderTheme.accent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('role');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t           = traderTheme(context);
    final user        = context.watch<UserProvider>();
    // ✅ الاسم من الـ API أولاً، لو مش موجود من UserProvider
    final displayName = _traderName.isNotEmpty
        ? _traderName
        : user.fullName.isNotEmpty ? user.fullName : 'Trader';
    final summary     = TraderDummyData.summary(_shipments, _offers);
    // ✅ فيكس: مش هيكراش لو _shipments فاضية
    final featuredShipment = _shipments.isEmpty
        ? Shipment(
      id: '', title: 'No Shipment', reference: 'TM-000000',
      origin: '', destination: '', departureDate: '-',
      price: 0, weightTons: 0,
      status: ShipmentStatus.pending, progress: 0,
      driverName: 'Unassigned', driverInitials: 'NA',
      vehicleInfo: '', goodsType: '', priority: 'Standard',
      cancelReason: null, timeline: const [],
    )
        : _shipments.firstWhere(
            (s) => s.isActive, orElse: () => _shipments.first);

    final pages = [
      _DashboardPage(
        t: t, displayName: displayName, summary: summary,
        featuredShipment: featuredShipment,
        recentShipments: _shipments.take(5).toList(),
        onOpenShipments:  () => _switchTab(1),
        onOpenOffers:     () => _switchTab(2),
        onOpenAlerts:     () => Navigator.pushNamed(context, '/trader_notifications'),
        onShowShipment:   _showShipmentDetails,
        onShowLive:       _openLiveTracking,
        onCreateShipment: _openCreateShipment,
        onLogout:         _logout,
        heroOpacity:       _heroOpacity,
        heroScaleAnim:     _heroScale,
        heroSlideAnim:     _heroSlide,
        heroGlow1Anim:     _heroGlow1,
        heroGlow2Anim:     _heroGlow2,
        detailOpacity:     _detailOpacity,
        detailSlide:       _detailSlide,
        ctaOpacity:        _ctaOpacity,
        ctaScale:          _ctaScale,
        headerOpacity:     _headerOpacity,
        headerSlide:       _headerSlide,
        headerNameOpacity: _headerNameOpacity,
        headerNameSlide:   _headerNameSlide,
        headerBtnsOpacity: _headerBtnsOpacity,
        headerBtnsSlide:   _headerBtnsSlide,
        staggerFade:       _staggerFade,
        staggerSlide:      _staggerSlide,
        pulseAnim:         _pulseAnim,
        pulseCtrl:         _pulseCtrl,
        shimmerAnim:       _shimmerAnim,
        rotateAnim:        _rotateAnim,
        particleAnim:      _particleAnim,
        animItem:          _animItem,
      ),
      _ShipmentsPage(t: t, shipments: _shipments,
          onBack: () => _switchTab(0), onShowDetails: _showShipmentDetails),
      _OffersPage(t: t, featuredShipment: featuredShipment, offers: _offers,
          onBack: () => _switchTab(0), onAccept: _acceptOffer),
      _AlertsPage(t: t, notifications: _notifications, onBack: () => _switchTab(0)),
    ];

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: t.isDark
            ? const Color(0xFF0A1628)
            : const Color(0xFFF5F8FA),
        body: Stack(children: [
          Container(
            decoration: BoxDecoration(
              gradient: t.isDark
                  ? const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), Color(0xFF0D1F33), Color(0xFF0A1628)],
                  stops: [0.0, 0.5, 1.0])
                  : LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5F8FA),
                    const Color(0xFFEAF4FB),
                    const Color(0xFFF5F8FA),
                  ],
                  stops: const [0.0, 0.5, 1.0]),
            ),
          ),
          if (t.isDark) _buildBgOrbs(),
          _buildParticles(),
          SafeArea(
            child: FadeTransition(
              opacity: _pageOpacity,
              child: SlideTransition(
                position: _pageSlide,
                child: FadeTransition(
                  opacity: _tabFade,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: pages[_currentIndex],
                  ),
                ),
              ),
            ),
          ),
        ]),
        bottomNavigationBar: SlideTransition(
          position: _bottomNavSlide,
          child: _BottomNav(
            t: t, currentIndex: _currentIndex, pulseCtrl: _pulseCtrl,
            onTap: (i) {
              if (i == 4) Navigator.pushNamed(context, '/trader_profile_settings');
              else _switchTab(i);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBgOrbs() => AnimatedBuilder(
    animation: Listenable.merge([_floatCtrl1, _floatCtrl2]),
    builder: (_, __) => Stack(children: [
      Positioned(top: 80 + _floatAnim1.value, right: 40,
          child: Container(width: 220, height: 220,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Color(0x0D00D5BE), blurRadius: 90, spreadRadius: 50)]))),
      Positioned(top: 200 + _floatAnim2.value, left: 30,
          child: Container(width: 160, height: 160,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Color(0x0D0097A7), blurRadius: 70, spreadRadius: 35)]))),
    ]),
  );

  Widget _buildParticles() {
    final w = MediaQuery.of(context).size.width;
    if (!context.watch<ThemeProvider>().isDark) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _particleAnim,
      builder: (_, __) => Stack(children: [
        Positioned(top: 20, left: w * 0.10,
            child: Container(width: 4, height: 4,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF10B981)
                        .withOpacity(0.40 + _particleAnim.value * 0.10)))),
        Positioned(top: 40, right: w * 0.15,
            child: Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF30B0C7)
                        .withOpacity(0.30 + (1 - _particleAnim.value) * 0.10)))),
        Positioned(top: 60, left: w * 0.20,
            child: Container(width: 4, height: 4,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF10B981)
                        .withOpacity(0.50 + _particleAnim.value * 0.10)))),
      ]),
    );
  }

  Future<void> _openLiveTracking(Shipment shipment) async {
    await Navigator.push(context, _slideUpRoute(TrackingScreen(
      shipmentId:  shipment.reference,
      origin:      shipment.origin,
      destination: shipment.destination,
      driverName:  shipment.driverName,
      vehicleInfo: shipment.vehicleInfo,
      weight:      '${shipment.weightTons} tons',
      price:       '\$${shipment.price.toStringAsFixed(0)}',
      status:      shipment.status.name,
    )));
  }

  // ✅ FIX 5 — يمرر driverName + driverInitials + cancelReason
  Future<void> _showShipmentDetails(Shipment shipment) async {
    await Navigator.pushNamed(context, '/shipment_details_args', arguments: {
      'shipmentId':     shipment.reference,
      'pickup':         shipment.origin,
      'dropoff':        shipment.destination,
      'date':           shipment.departureDate,
      'time':           '12:00 PM',
      'packages':       '1',
      'weight':         '${shipment.weightTons} tons',
      'status':         shipment.status.name,
      'driverName':     shipment.driverName,
      'driverInitials': shipment.driverInitials,
      'cancelReason':   shipment.cancelReason,
    });
    // ✅ حدّث الشحنات لما ترجع
    if (mounted) _loadData();
  }

  Future<void> _openCreateShipment() async {
    await Navigator.push(context, _slideUpRoute(const TraderNewShipmentScreen()));
    // ✅ لما ترجع، حدّث الشحنات
    if (mounted) _loadData();
  }
}

Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMedAnim,
  reverseTransitionDuration: _kFastAnim,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    final fade = CurvedAnimation(parent: anim, curve: _kEaseOutCubic);
    return SlideTransition(
        position: slide, child: FadeTransition(opacity: fade, child: child));
  },
);

Route<T> _slideRightRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMedAnim,
  reverseTransitionDuration: _kFastAnim,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    final fade = CurvedAnimation(parent: anim, curve: _kEaseOutCubic);
    return SlideTransition(
        position: slide, child: FadeTransition(opacity: fade, child: child));
  },
);

// ══════════════════════════════════════════════════════════
//  BOTTOM NAV
// ══════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final TraderTheme t;
  final AnimationController pulseCtrl;
  const _BottomNav({required this.currentIndex, required this.onTap,
    required this.t, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.home_outlined,              'activeIcon': Icons.home_rounded,          'label': 'Home'},
      {'icon': Icons.inventory_2_outlined,       'activeIcon': Icons.inventory_2_rounded,   'label': 'Shipments'},
      {'icon': Icons.handshake_outlined,         'activeIcon': Icons.handshake_rounded,     'label': 'Offers'},
      {'icon': Icons.notifications_none_rounded, 'activeIcon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.person_outline_rounded,     'activeIcon': Icons.person_rounded,        'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF0A1628) : Colors.white,
        border: Border(top: BorderSide(color: t.border, width: 1)),
        boxShadow: [BoxShadow(
          color: t.isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
          blurRadius: 16, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key; final item = e.value; final active = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 3, width: active ? 36 : 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(
                            colors: [Color(0xFF0097A7), TraderTheme.accent])
                            : null,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: active
                            ? [BoxShadow(
                            color: TraderTheme.accent.withOpacity(0.4),
                            blurRadius: 8)]
                            : [],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        active
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        key: ValueKey('${i}_$active'),
                        color: active ? TraderTheme.accent : t.textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(item['label'] as String,
                        style: TextStyle(
                          color: active ? TraderTheme.accent : t.textMuted,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        )),
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

// ══════════════════════════════════════════════════════════
//  DASHBOARD PAGE
// ══════════════════════════════════════════════════════════
class _DashboardPage extends StatelessWidget {
  final TraderTheme t;
  final String displayName;
  final TraderSummary summary;
  final Shipment featuredShipment;
  final List<Shipment> recentShipments;
  final VoidCallback onOpenShipments, onOpenOffers, onOpenAlerts,
      onCreateShipment, onLogout;
  final ValueChanged<Shipment> onShowShipment, onShowLive;
  final Animation<double> heroOpacity, heroScaleAnim, heroGlow1Anim, heroGlow2Anim;
  final Animation<Offset>  heroSlideAnim;
  final Animation<double> detailOpacity, ctaOpacity, ctaScale;
  final Animation<Offset>  detailSlide;
  final Animation<double> headerOpacity, headerNameOpacity, headerBtnsOpacity;
  final Animation<Offset>  headerSlide, headerNameSlide, headerBtnsSlide;
  final List<Animation<double>> staggerFade;
  final List<Animation<Offset>>  staggerSlide;
  final Animation<double> pulseAnim, shimmerAnim, rotateAnim, particleAnim;
  final AnimationController pulseCtrl;
  final Widget Function(int, Widget) animItem;

  const _DashboardPage({
    required this.t, required this.displayName, required this.summary,
    required this.featuredShipment, required this.recentShipments,
    required this.onOpenShipments, required this.onOpenOffers,
    required this.onOpenAlerts, required this.onShowShipment,
    required this.onShowLive, required this.onCreateShipment,
    required this.onLogout,
    required this.heroOpacity, required this.heroScaleAnim,
    required this.heroSlideAnim, required this.heroGlow1Anim,
    required this.heroGlow2Anim, required this.detailOpacity,
    required this.detailSlide, required this.ctaOpacity, required this.ctaScale,
    required this.headerOpacity, required this.headerSlide,
    required this.headerNameOpacity, required this.headerNameSlide,
    required this.headerBtnsOpacity, required this.headerBtnsSlide,
    required this.staggerFade, required this.staggerSlide,
    required this.pulseAnim, required this.pulseCtrl,
    required this.shimmerAnim, required this.rotateAnim,
    required this.particleAnim, required this.animItem,
  });

  @override
  Widget build(BuildContext context) {
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning'
        : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final initial  = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';
    final textPrimary = t.isDark
        ? const Color(0xFFF0FDFA) : const Color(0xFF1A2A3A);
    final textMuted   = t.isDark
        ? const Color(0x80CBFBF1) : const Color(0xFF7A93A8);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Header ──
      FadeTransition(
        opacity: headerOpacity,
        child: SlideTransition(
          position: headerSlide,
          child: Row(children: [
            Expanded(
              child: FadeTransition(
                opacity: headerNameOpacity,
                child: SlideTransition(
                  position: headerNameSlide,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/trader_profile'),
                    child: Row(children: [
                      Container(width: 2, height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.40),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          )),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting, style: TextStyle(
                                color: textMuted, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 2),
                            Text(displayName,
                                style: TextStyle(
                                    color: textPrimary, fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: staggerFade[0],
                              builder: (_, __) => Container(
                                width: 60 * staggerFade[0].value, height: 2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF0097A7), TraderTheme.accent,
                                    Colors.transparent
                                  ]),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ])),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FadeTransition(
              opacity: headerBtnsOpacity,
              child: SlideTransition(
                position: headerBtnsSlide,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Theme toggle
                  AnimatedBuilder(
                    animation: rotateAnim,
                    builder: (_, child) => Transform.rotate(
                        angle: rotateAnim.value * 0.2, child: child),
                    child: GestureDetector(
                      onTap: () => context.read<ThemeProvider>().toggleTheme(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: t.isDark
                              ? const LinearGradient(colors: [
                            Color(0x1F00D5BE), Color(0x140097A7)])
                              : LinearGradient(colors: [
                            TraderTheme.accent.withOpacity(0.1),
                            TraderTheme.accent.withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: TraderTheme.accent.withOpacity(0.25)),
                        ),
                        child: Icon(
                          t.isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: TraderTheme.accent, size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Avatar
                  _SpringTapButton(
                    onTap: () =>
                        Navigator.pushNamed(context, '/trader_profile'),
                    hoverScale: 1.1, tapScale: 0.95,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF30B0C7)]),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.25),
                            width: 2),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      alignment: Alignment.center,
                      child: Text(initial, style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 20),

      // ── Hero ──
      FadeTransition(
        opacity: heroOpacity,
        child: SlideTransition(
          position: heroSlideAnim,
          child: ScaleTransition(
            scale: heroScaleAnim,
            child: _SpringTapButton(
              onTap: () => onShowShipment(featuredShipment),
              hoverScale: 1.02, tapScale: 0.97,
              child: Stack(children: [
                AnimatedBuilder(
                  animation: heroGlow1Anim,
                  builder: (_, __) => Positioned(
                    top: -80, left: 0, right: 0,
                    child: Container(height: 224,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF10B981)
                                .withOpacity(heroGlow1Anim.value),
                            blurRadius: 120, spreadRadius: 40,
                          )]),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: heroGlow2Anim,
                  builder: (_, __) => Positioned(
                    top: -48, left: 0, right: 0,
                    child: Container(height: 160,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF30B0C7)
                                .withOpacity(heroGlow2Anim.value),
                            blurRadius: 90, spreadRadius: 30,
                          )]),
                    ),
                  ),
                ),
                // ✅ الـ HeroCard الأصلية — أي ضغطة تفتح الـ TrackingScreen
                GestureDetector(
                  onTap: () => onShowLive(featuredShipment),
                  child: _HeroCard(
                    shipment:    featuredShipment,
                    t:           t,
                    shimmerAnim: shimmerAnim,
                    pulseCtrl:   pulseCtrl,
                    onViewLive:  () => onShowLive(featuredShipment),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),

      // ── Shipment details ──
      FadeTransition(
        opacity: detailOpacity,
        child: SlideTransition(
          position: detailSlide,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 2, margin: const EdgeInsets.only(right: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0x4010B981), Color(0x1F10B981), Colors.transparent],
                    ),
                  )),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SHIPMENT DETAILS', style: TextStyle(
                    color: textMuted, fontSize: 10, letterSpacing: 1.4,
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _DetailDividerRow(
                  label: 'Progress', labelColor: textMuted,
                  trailing: Row(children: [
                    Container(width: 112, height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: featuredShipment.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF30B0C7)]),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedBuilder(
                              animation: shimmerAnim,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(shimmerAnim.value * 100, 0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Colors.transparent,
                                      Colors.white24,
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${(featuredShipment.progress * 100).round()}%',
                        style: const TextStyle(color: Color(0xFF10B981),
                            fontSize: 15, fontWeight: FontWeight.bold,
                            fontFamily: 'monospace')),
                  ]),
                ),
                _DetailDividerRow(
                  label: 'Driver', labelColor: textMuted,
                  trailing: Row(children: [
                    Container(width: 28, height: 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF30B0C7)])),
                      alignment: Alignment.center,
                      child: Text(
                        featuredShipment.driverName.split(' ')
                            .map((p) => p[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(featuredShipment.driverName, style: TextStyle(
                        color: textPrimary, fontSize: 14,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFFBBF24)
                                .withOpacity(pulseCtrl.value * 0.15),
                            blurRadius: 6,
                          )],
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star_rounded,
                              color: Color(0xFFFBBF24), size: 12),
                          SizedBox(width: 2),
                          Text('4.8', style: TextStyle(
                              color: Color(0xFFFBBF24), fontSize: 12,
                              fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    Text('Shipment ID', style: TextStyle(
                        color: textMuted, fontSize: 13,
                        fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(featuredShipment.reference,
                        style: const TextStyle(color: Color(0xA510B981),
                            fontSize: 13, fontWeight: FontWeight.w600,
                            fontFamily: 'monospace')),
                  ]),
                ),
              ])),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 18),

      // ── CTA ──
      FadeTransition(
        opacity: ctaOpacity,
        child: ScaleTransition(
          scale: ctaScale,
          child: _SpringTapButton(
            onTap: onCreateShipment,
            hoverScale: 1.03, tapScale: 0.98,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: t.isDark
                    ? const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0x3330B0C7), Color(0x1F30B0C7)])
                    : LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF30B0C7).withOpacity(0.12),
                      const Color(0xFF30B0C7).withOpacity(0.06),
                    ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF30B0C7)
                      .withOpacity(t.isDark ? 0.40 : 0.25),
                  width: 2,
                ),
              ),
              child: Row(children: [
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, child) => Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF30B0C7), Color(0xFF2A9EB3)]),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF30B0C7)
                            .withOpacity(0.30 + pulseCtrl.value * 0.15),
                        blurRadius: 24 + pulseCtrl.value * 4,
                        offset: const Offset(0, 8),
                      )],
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create New\nShipment', style: TextStyle(
                          color: textPrimary, fontSize: 18,
                          fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 4),
                      Text('Get instant driver matches',
                          style: TextStyle(color: textMuted, fontSize: 13)),
                    ])),
                const Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF30B0C7), size: 24),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),

      // ── Recent Activity ──
      animItem(5, Row(children: [
        Text('RECENT ACTIVITY', style: TextStyle(
            color: textMuted, fontSize: 10, letterSpacing: 1.3,
            fontWeight: FontWeight.w500)),
        const Spacer(),
        GestureDetector(
          onTap: onOpenShipments,
          child: const Text('View All', style: TextStyle(
              color: Color(0xFF10B981), fontSize: 12,
              fontWeight: FontWeight.w500)),
        ),
      ])),
      const SizedBox(height: 12),

      if (recentShipments.isEmpty)
        animItem(6, Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text(
            'No recent shipments yet',
            style: TextStyle(color: textMuted, fontSize: 13),
          )),
        ))
      else
        animItem(6, _StaggeredList(
          count: recentShipments.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecentTile(shipment: recentShipments[i], t: t,
                onTap: () => onShowShipment(recentShipments[i])),
          ),
        )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  HERO CARD
// ══════════════════════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  final Shipment shipment;
  final TraderTheme t;
  final Animation<double> shimmerAnim;
  final AnimationController pulseCtrl;
  final VoidCallback? onViewLive;

  const _HeroCard({required this.shipment, required this.t,
    required this.shimmerAnim, required this.pulseCtrl, this.onViewLive});

  @override
  Widget build(BuildContext context) {
    final cardMid    = t.isDark ? const Color(0xFA0A1E3C) : const Color(0xFAE8F7F5);
    final cardBorder = t.isDark ? const Color(0x4D30B0C7) : const Color(0x5500D5BE);
    final cardShadow = t.isDark
        ? Colors.black.withOpacity(0.60)
        : const Color(0xFF00D5BE).withOpacity(0.12);
    final etaTextMuted = t.isDark
        ? const Color(0x7203FBCF1) : const Color(0xFF7A93A8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0x2634C759), cardMid, const Color(0x2630B0C7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 0.8),
        boxShadow: [BoxShadow(
            color: cardShadow, blurRadius: 60, offset: const Offset(0, 20))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: [
          SizedBox(height: 155, child: Stack(children: [
            Positioned.fill(child: Container(decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Color(0x99000000), Color(0x26000000), Colors.transparent]),
            ))),
            Positioned(top: 0, left: 0, bottom: 0,
                child: Container(width: 200, decoration: const BoxDecoration(
                    gradient: RadialGradient(center: Alignment.centerLeft, radius: 0.8,
                        colors: [Color(0x1F34C759), Colors.transparent])))),
            Positioned(top: 0, right: 0, bottom: 0,
                child: Container(width: 200, decoration: const BoxDecoration(
                    gradient: RadialGradient(center: Alignment.centerRight, radius: 0.8,
                        colors: [Color(0x1F30B0C7), Colors.transparent])))),
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned.fill(child: CustomPaint(painter: _ScanLinePainter())),
            Positioned.fill(child: CustomPaint(painter: _RouteGlowPainter())),
            const _AnimatedRouteDots(),
            Positioned(top: -12, left: -12, child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                  border: Border(
                      left: BorderSide(color: Color(0x6610B981), width: 2.5),
                      top:  BorderSide(color: Color(0x6610B981), width: 2.5)),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24))),
              child: Align(alignment: Alignment.topLeft,
                  child: Container(width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF10B981), shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x8010B981), blurRadius: 8)]))),
            )),
            Positioned(bottom: -12, right: -12, child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                  border: Border(
                      right:  BorderSide(color: Color(0x6610B981), width: 2.5),
                      bottom: BorderSide(color: Color(0x6610B981), width: 2.5)),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(24))),
              child: Align(alignment: Alignment.bottomRight,
                  child: Container(width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF10B981), shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x8010B981), blurRadius: 8)]))),
            )),
            const Positioned(left: 35, bottom: 8, child: _OriginMarker()),
            Positioned(left: 171, top: 76,
                child: _DriverMarker(pulseCtrl: pulseCtrl)),
            const Positioned(right: 14, top: 53, child: _DestMarker()),
            Positioned(top: 16, left: 16, right: 16,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InTransitBadge(pulseCtrl: pulseCtrl),
                    _RouteBadge(
                        origin: shipment.origin,
                        destination: shipment.destination),
                  ]),
            ),
          ])),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.isDark
                  ? const [Color(0x1E30B0C7), Color(0x1A30B0C7), Color(0x1430B0C7)]
                  : [
                const Color(0xFF30B0C7).withOpacity(0.08),
                const Color(0xFF30B0C7).withOpacity(0.05),
                const Color(0xFF30B0C7).withOpacity(0.03),
              ]),
              border: Border(top: BorderSide(
                color: t.isDark
                    ? const Color(0x5930B0C7)
                    : const Color(0x3000D5BE),
              )),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Container(width: 32, height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Color(0xFF30B0C7), Color(0xFF2A9EB3)]),
                      boxShadow: [BoxShadow(
                          color: Color(0x6630B0C7), blurRadius: 12)]),
                  child: const Icon(Icons.flash_on_rounded,
                      color: Colors.white, size: 16)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Estimated Time', style: TextStyle(
                    color: etaTextMuted, fontSize: 10,
                    letterSpacing: 0.8, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                RichText(text: const TextSpan(children: [
                  TextSpan(text: '45',
                      style: TextStyle(color: Color(0xFF34C759),
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' min',
                      style: TextStyle(color: Color(0x9934C759), fontSize: 14)),
                ])),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: onViewLive,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFF30B0C7), Color(0xFF2A9EB3)]),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                        boxShadow: [BoxShadow(
                            color: Color(0x6630B0C7), blurRadius: 12,
                            offset: Offset(0, 4))],
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('View Live', style: TextStyle(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 14),
                      ]),
                    ),
                    Positioned.fill(child: AnimatedBuilder(
                      animation: shimmerAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(shimmerAnim.value * 80, 0),
                        child: Container(width: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white24,
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    )),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  HERO CARD WIDGETS
// ══════════════════════════════════════════════════════════
class _InTransitBadge extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _InTransitBadge({required this.pulseCtrl});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xF234C759), Color(0xD934C759)]),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
      boxShadow: [BoxShadow(
          color: const Color(0xFF34C759).withOpacity(0.30), blurRadius: 8)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(width: 6, height: 6,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: Colors.white.withOpacity(0.7 * pulseCtrl.value),
                  blurRadius: 4, spreadRadius: 1)]),
        ),
      ),
      const SizedBox(width: 6),
      const Text('IN TRANSIT', style: TextStyle(
          color: Colors.white, fontSize: 10,
          fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    ]),
  );
}

class _RouteBadge extends StatelessWidget {
  final String origin, destination;
  const _RouteBadge({required this.origin, required this.destination});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xF00A1628),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x8030B0C7)),
        boxShadow: [BoxShadow(
            color: const Color(0xFF30B0C7).withOpacity(0.25), blurRadius: 8)],
      ),
      child: Text('$origin  →  $destination',
          style: const TextStyle(color: Color(0xFF30B0C7),
              fontSize: 10, fontWeight: FontWeight.bold)),
    ),
    const SizedBox(height: 3),
    Container(height: 1.5, width: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFF30B0C7), Color(0xFF4FC3D9), Color(0xFF30B0C7)]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(
            color: const Color(0xFF30B0C7).withOpacity(0.50), blurRadius: 4)],
      ),
    ),
  ]);
}

class _OriginMarker extends StatelessWidget {
  const _OriginMarker();
  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
    Container(width: 36, height: 36, decoration: const BoxDecoration(
        shape: BoxShape.circle, color: Color(0x4034C759))),
    Container(width: 20, height: 20, decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30B0C7)]),
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: [BoxShadow(
          color: const Color(0xFF34C759).withOpacity(0.40), blurRadius: 10)],
    ), child: const Center(
        child: CircleAvatar(radius: 3, backgroundColor: Colors.white))),
  ]);
}

class _DriverMarker extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _DriverMarker({required this.pulseCtrl});
  @override
  Widget build(BuildContext context) =>
      Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(animation: pulseCtrl, builder: (_, __) => Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF30B0C7).withOpacity(0.20 * pulseCtrl.value)))),
        Positioned(left: 0,
            child: Container(width: 24, height: 4,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.transparent, Color(0xFF30B0C7)]),
                    borderRadius: BorderRadius.circular(2)))),
        Container(width: 28, height: 28, decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color(0xFF30B0C7), Color(0xFF248C9F)]),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
              color: const Color(0xFF30B0C7).withOpacity(0.60), blurRadius: 14)],
        ), child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 14)),
        Positioned(top: 5, right: 5,
            child: AnimatedBuilder(animation: pulseCtrl, builder: (_, __) => Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: const Color(0xFF34C759), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF34C759)
                            .withOpacity(0.5 * pulseCtrl.value),
                        blurRadius: 4)])))),
      ]);
}

class _DestMarker extends StatelessWidget {
  const _DestMarker();
  @override
  Widget build(BuildContext context) =>
      Stack(alignment: Alignment.center, children: [
        Container(width: 32, height: 32, decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0x3334C759))),
        Container(width: 24, height: 24, decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color(0xFF34C759), Color(0xFF30B0C7)]),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
              color: const Color(0xFF34C759).withOpacity(0.50), blurRadius: 12)],
        ), child: const Icon(Icons.location_on, color: Colors.white, size: 12)),
      ]);
}

class _AnimatedRouteDots extends StatefulWidget {
  const _AnimatedRouteDots();
  @override State<_AnimatedRouteDots> createState() =>
      _AnimatedRouteDotsState();
}
class _AnimatedRouteDotsState extends State<_AnimatedRouteDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;
  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000)));
    _anims = _ctrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.linear)).toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (mounted) _ctrls[i].repeat();
      });
    }
  }
  @override void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: AnimatedBuilder(
      animation: Listenable.merge(_ctrls),
      builder: (_, __) => CustomPaint(
        painter: _RouteDotsAnimPainter(
            progresses: _anims.map((a) => a.value).toList()),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  SHIPMENT DETAILS SCREEN  ← ✅ FIX 2/3/4
// ══════════════════════════════════════════════════════════
class ShipmentDetailsScreen extends StatefulWidget {
  final String shipmentId, pickup, dropoff, date, time, packages, weight, status;
  final String driverName;      // ✅ FIX 4
  final String driverInitials;  // ✅ FIX 4
  final String? cancelReason;   // ✅ FIX 4

  const ShipmentDetailsScreen({
    super.key,
    this.shipmentId     = 'TM-000000',
    this.pickup         = 'Not set',
    this.dropoff        = 'Not set',
    this.date           = '-',
    this.time           = '-',
    this.packages       = '1',
    this.weight         = '0',
    this.status         = 'pending',
    this.driverName     = 'Ahmed Hassan',
    this.driverInitials = 'AH',
    this.cancelReason,
  });

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen>
    with TickerProviderStateMixin {

  late AnimationController _badgeCtrl, _idCtrl, _cardsCtrl, _btnsCtrl;
  late Animation<double> _badgeScale, _badgeFade, _idFade, _btnsFade;
  late Animation<Offset>  _btnsSlide;

  static const int _kCards = 3;
  late List<Animation<double>> _cardFade;
  late List<Animation<Offset>>  _cardSlide;

  Color get _statusColor {
    switch (widget.status) {
      case 'inTransit':  return const Color(0xFF3B82F6);
      case 'delivered':  return const Color(0xFF00D5BE);
      case 'cancelled':  return const Color(0xFFEF4444);
      default:           return const Color(0xFFFFB800);
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'inTransit':  return 'In Transit';
      case 'delivered':  return 'Delivered';
      case 'cancelled':  return 'Cancelled';
      default:           return 'Pending';
    }
  }

  List<Map<String, dynamic>> get _timelineItems {
    final isPending   = widget.status == 'pending';
    final isInTransit = widget.status == 'inTransit';
    final isDelivered = widget.status == 'delivered';
    return [
      {'title': 'Created',        'sub': widget.date,        'done': true},
      {'title': 'Pending Driver', 'sub': isPending ? 'Waiting...' : 'Driver assigned', 'done': !isPending},
      {'title': 'In Progress',    'sub': isInTransit || isDelivered ? 'Picked up' : 'Pending', 'done': isInTransit || isDelivered},
      {'title': 'Delivered',      'sub': isDelivered ? 'Successfully delivered' : 'Pending', 'done': isDelivered},
    ];
  }

  @override
  void initState() {
    super.initState();
    _badgeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _badgeScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack));
    _badgeFade  = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut);

    _idCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _idFade  = CurvedAnimation(parent: _idCtrl, curve: Curves.easeOut);

    final totalMs = 400 + _kCards * 90;
    _cardsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _cardFade  = List.generate(_kCards, (i) {
      final s = (i * 90) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _cardsCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic)));
    });
    _cardSlide = List.generate(_kCards, (i) {
      final s = (i * 90) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardsCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic)));
    });

    _btnsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutCubic));
    _btnsFade  = CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut);

    _runSequence();
  }

  void _runSequence() async {
    _badgeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _idCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _btnsCtrl.forward();
  }

  @override
  void dispose() {
    _badgeCtrl.dispose(); _idCtrl.dispose();
    _cardsCtrl.dispose(); _btnsCtrl.dispose();
    super.dispose();
  }

  Widget _animCard(int i, Widget child) => FadeTransition(
      opacity: _cardFade[i],
      child: SlideTransition(position: _cardSlide[i], child: child));

  // ✅ FIX 3 — دالة بتبني الـ buttons حسب الـ status
  Widget _buildActionButtons(BuildContext context) {
    final isDark  = context.read<ThemeProvider>().isDark;
    final kCard   = isDark
        ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kBorder = isDark
        ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00D5BE);
    const kGreen  = Color(0xFF009689);

    switch (widget.status) {

    // ── delivered: Rate Driver + View Invoice ──────────────────
      case 'delivered':
        return Column(children: [
          // Rate Driver
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RateDriverScreen(
                driverName:     widget.driverName,
                driverInitials: widget.driverInitials,
              )),
            ),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF00BBA7), kTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: kTeal.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_outline_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Rate Driver', style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          // View Invoice
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/invoice'),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined,
                        color: kTeal, size: 20),
                    const SizedBox(width: 8),
                    Text('View Invoice', style: TextStyle(
                        color: kText, fontSize: 16,
                        fontWeight: FontWeight.w500)),
                  ]),
            ),
          ),
        ]);

    // ── cancelled: سبب الإلغاء + Create New ────────────────────
      case 'cancelled':
        return Column(children: [
          // بوكس سبب الإلغاء
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.cancel_outlined,
                        color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Cancellation Reason',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    widget.cancelReason ?? 'Shipment was cancelled',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF6B8096),
                        fontSize: 13,
                        height: 1.5),
                  ),
                ]),
          ),
          const SizedBox(height: 12),
          // Create New Shipment
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/create_shipment'),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF00BBA7), kTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: kTeal.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Create New Shipment', style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ]),
            ),
          ),
        ]);

    // ── pending / inTransit: View Drivers + View Offers ─────────
      default:
        return Column(children: [
          // View Available Drivers
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              _slideRightRoute(SuggestedDriversScreen(
                pickup:   widget.pickup,
                dropoff:  widget.dropoff,
                date:     widget.date,
                time:     widget.time,
                packages: widget.packages,
                weight:   widget.weight,
              )),
            ),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF00BBA7), kTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: kTeal.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('View Available Drivers', style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          // View Offers
          GestureDetector(
            onTap: () => Navigator.push(
                context, _slideRightRoute(const DriverOffersScreen())),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              alignment: Alignment.center,
              child: Text('View Offers', style: TextStyle(
                  color: kText, fontSize: 16,
                  fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg2    = isDark
        ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
    final kBdr    = isDark
        ? const Color(0xFF00D5BE).withOpacity(0.1)
        : const Color(0xFFE2EAF0);

    Widget cardDeco(Widget child) => Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: kBg2, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBdr),
            boxShadow: isDark ? [] : [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10, offset: const Offset(0, 3))]),
        child: child);

    final timeline = _timelineItems;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A1628) : const Color(0xFFF5F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // ── Header ──
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A1628).withOpacity(0.6)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBdr),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                      size: 24),
                ),
              ),
              Expanded(child: Center(child: Text('Shipment Details',
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                      fontSize: 20, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 42),
            ]),
            const SizedBox(height: 20),

            // ── Status badge ──
            ScaleTransition(scale: _badgeScale,
              child: FadeTransition(opacity: _badgeFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(_statusLabel, style: TextStyle(
                      color: _statusColor, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Shipment ID ──
            FadeTransition(opacity: _idFade,
              child: Column(children: [
                Text('Shipment ID', style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8A9BB0)
                        : const Color(0xFF8A9BB0),
                    fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.shipmentId, style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8A9BB0)
                        : const Color(0xFF8A9BB0),
                    fontSize: 18, fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Timeline card ──
            _animCard(0, cardDeco(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Timeline', style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...List.generate(timeline.length, (i) => _tlItem(
                    title: timeline[i]['title'],
                    sub:   timeline[i]['sub'],
                    done:  timeline[i]['done'],
                    first: i == 0,
                    last:  i == timeline.length - 1,
                    isDark: isDark,
                  )),
                ]))),
            const SizedBox(height: 20),

            // ── Route card ──
            _animCard(1, cardDeco(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route Details', style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      _dot(const Color(0xFF00D5BE)),
                      Container(width: 2, height: 40,
                          color: const Color(0xFF00D5BE)),
                      _dot(const Color(0xFF00B8DB)),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup', style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8A9BB0)
                                  : const Color(0xFF8A9BB0),
                              fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(widget.pickup, style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                              fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 18),
                          Text('Drop-off', style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8A9BB0)
                                  : const Color(0xFF8A9BB0),
                              fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(widget.dropoff, style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1A2A3A),
                              fontSize: 17, fontWeight: FontWeight.w600)),
                        ])),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _dtItem('Scheduled Date',
                        Icons.calendar_today, widget.date, isDark)),
                    Expanded(child: _dtItem('Time',
                        Icons.access_time, widget.time, isDark)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _dtItem('Packages',
                        Icons.inventory_2_outlined, widget.packages, isDark)),
                    Expanded(child: _dtItem('Weight',
                        Icons.scale_outlined, widget.weight, isDark)),
                  ]),
                ]))),
            const SizedBox(height: 20),

            // ── Cost card ──
            _animCard(2, cardDeco(Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost', style: TextStyle(
                      color: isDark
                          ? const Color(0xFF8A9BB0) : const Color(0xFF8A9BB0),
                      fontSize: 16)),
                  const Text('\$240', style: TextStyle(
                      color: Color(0xFF00D5BE), fontSize: 28,
                      fontWeight: FontWeight.bold)),
                ]))),
            const SizedBox(height: 20),

            // ✅ FIX 2 — Action buttons حسب الـ status
            SlideTransition(
              position: _btnsSlide,
              child: FadeTransition(
                opacity: _btnsFade,
                child: _buildActionButtons(context),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 12, height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _tlItem({required String title, required String sub,
    required bool done, required bool first, required bool last,
    required bool isDark}) =>
      Row(children: [
        Column(children: [
          if (!first)
            Container(width: 2, height: 28,
                color: done
                    ? const Color(0xFF00D5BE)
                    : isDark
                    ? const Color(0xFF1A3550)
                    : const Color(0xFFE2EAF0)),
          Container(width: 26, height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: done ? const Color(0xFF00D5BE) : Colors.transparent,
                  border: Border.all(
                      color: done
                          ? const Color(0xFF00D5BE)
                          : isDark
                          ? const Color(0xFF1A3550)
                          : const Color(0xFFE2EAF0),
                      width: 2)),
              child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null),
          if (!last)
            Container(width: 2, height: 28,
                color: done
                    ? const Color(0xFF00D5BE)
                    : isDark
                    ? const Color(0xFF1A3550)
                    : const Color(0xFFE2EAF0)),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                  color: done
                      ? (isDark ? Colors.white : const Color(0xFF1A2A3A))
                      : (isDark
                      ? const Color(0xFF8A9BB0)
                      : const Color(0xFF8A9BB0)),
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(
                  color: Color(0xFF8A9BB0), fontSize: 12)),
            ]))),
      ]);

  Widget _dtItem(String label, IconData icon, String value, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            color: Color(0xFF8A9BB0), fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(icon, color: const Color(0xFF00D5BE), size: 15),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A2A3A),
              fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ]);
}

// ══════════════════════════════════════════════════════════
//  SPRING TAP BUTTON
// ══════════════════════════════════════════════════════════
class _SpringTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale, tapScale;
  const _SpringTapButton({required this.child, this.onTap,
    this.hoverScale = 1.05, this.tapScale = 0.95});
  @override State<_SpringTapButton> createState() =>
      _SpringTapButtonState();
}
class _SpringTapButtonState extends State<_SpringTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this,
      duration: const Duration(milliseconds: 150));
  late final Animation<double> _scale =
  Tween<double>(begin: 1.0, end: widget.tapScale)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// ══════════════════════════════════════════════════════════
//  DETAIL DIVIDER ROW
// ══════════════════════════════════════════════════════════
class _DetailDividerRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final Color? labelColor;
  const _DetailDividerRow(
      {required this.label, required this.trailing, this.labelColor});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Text(label, style: TextStyle(
            color: labelColor ?? const Color(0x80CBFBF1),
            fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        trailing,
      ]),
    ),
    Container(height: 1, color: const Color(0x1510B981)),
  ]);
}

// ══════════════════════════════════════════════════════════
//  STAGGERED LIST
// ══════════════════════════════════════════════════════════
class _StaggeredList extends StatefulWidget {
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  const _StaggeredList({required this.count, required this.itemBuilder});
  @override State<_StaggeredList> createState() => _StaggeredListState();
}
class _StaggeredListState extends State<_StaggeredList>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>>  _slides;
  @override
  void initState() {
    super.initState();
    final total = Duration(
        milliseconds: 300 + widget.count * _kStagger.inMilliseconds);
    _ctrl = AnimationController(vsync: this, duration: total);
    _fades = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = math.min(s + 0.5, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _ctrl, curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _slides = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = math.min(s + 0.55, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl,
          curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(widget.count, (i) => FadeTransition(
      opacity: _fades[i],
      child: SlideTransition(
          position: _slides[i],
          child: widget.itemBuilder(context, i)),
    )),
  );
}

// ══════════════════════════════════════════════════════════
//  RECENT TILE
// ══════════════════════════════════════════════════════════
class _RecentTile extends StatefulWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  final TraderTheme t;
  const _RecentTile({required this.shipment, required this.onTap,
    required this.t});
  @override State<_RecentTile> createState() => _RecentTileState();
}
class _RecentTileState extends State<_RecentTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this,
      duration: const Duration(milliseconds: 150));
  late final Animation<double> _scale =
  Tween<double>(begin: 1.0, end: 0.98)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late final Animation<double> _x =
  Tween<double>(begin: 0, end: 4)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(_x.value, 0),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.t.isDark
              ? const Color(0x4D0A1628) : widget.t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.t.isDark
                  ? const Color(0x1A10B981) : widget.t.border),
          boxShadow: widget.t.cardShadow,
        ),
        child: Row(children: [
          Container(width: 24, height: 24,
              decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.30))),
              child: const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF10B981), size: 14)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '${widget.shipment.origin} → ${widget.shipment.destination}',
                style: TextStyle(color: widget.t.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
                '${widget.shipment.departureDate.replaceAll('2026-', 'Jan ')}  ·  Delivered',
                style: TextStyle(color: widget.t.textMuted, fontSize: 11)),
          ])),
          Text('\$${widget.shipment.price.toStringAsFixed(0)}',
              style: const TextStyle(color: Color(0xFF10B981),
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  SHIPMENTS PAGE
// ══════════════════════════════════════════════════════════
class _ShipmentsPage extends StatefulWidget {
  final List<Shipment> shipments;
  final VoidCallback onBack;
  final ValueChanged<Shipment> onShowDetails;
  final TraderTheme t;
  const _ShipmentsPage({required this.shipments, required this.onBack,
    required this.onShowDetails, required this.t});
  @override State<_ShipmentsPage> createState() => _ShipmentsPageState();
}
class _ShipmentsPageState extends State<_ShipmentsPage> {
  int _page = 0;
  static const int _pageSize = 6;
  @override
  Widget build(BuildContext context) {
    final total = (widget.shipments.length / _pageSize).ceil().clamp(1, 999);
    final items = widget.shipments.skip(_page * _pageSize).take(_pageSize).toList();
    final spent = items.fold<double>(0, (s, x) => s + x.price) / 1000;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTopBar(title: 'My Shipments',
          subtitle: '${widget.shipments.length} total shipments',
          leading: TraderIconButton(
              icon: Icons.arrow_back_ios_new_rounded, onTap: widget.onBack)),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: MetricMiniCard(
            icon: Icons.calendar_today_outlined,
            label: 'This Month', value: '12')),
        const SizedBox(width: 12),
        Expanded(child: MetricMiniCard(
            icon: Icons.attach_money_rounded, label: 'Total Spent',
            value: '\$${spent.toStringAsFixed(1)}K')),
      ]),
      const SizedBox(height: 16),
      _StaggeredList(count: items.length,
          itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShipTile(shipment: items[i], t: widget.t,
                  onTap: () => widget.onShowDetails(items[i])))),
      const SizedBox(height: 8),
      _Pager(t: widget.t, page: _page, total: total,
          onPrev: _page == 0 ? null : () => setState(() => _page--),
          onNext: _page >= total - 1 ? null : () => setState(() => _page++)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  OFFERS PAGE
// ══════════════════════════════════════════════════════════
class _OffersPage extends StatefulWidget {
  final Shipment featuredShipment;
  final List<DriverOffer> offers;
  final VoidCallback onBack;
  final ValueChanged<DriverOffer> onAccept;
  final TraderTheme t;
  const _OffersPage({required this.featuredShipment, required this.offers,
    required this.onBack, required this.onAccept, required this.t});
  @override State<_OffersPage> createState() => _OffersPageState();
}
class _OffersPageState extends State<_OffersPage> {
  int _page = 0, _filterIndex = 0;
  static const int _pageSize = 4;

  List<DriverOffer> get _filtered {
    switch (_filterIndex) {
      case 0: return widget.offers.where((o) => o.status == OfferStatus.pending).toList();
      case 1: return widget.offers.where((o) => o.status == OfferStatus.accepted).toList();
      case 2: return widget.offers.where((o) => o.status == OfferStatus.rejected).toList();
      default: return widget.offers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total  = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final items  = filtered.skip(_page * _pageSize).take(_pageSize).toList();
    final pCount = widget.offers.where((o) => o.status == OfferStatus.pending).length;
    final aCount = widget.offers.where((o) => o.status == OfferStatus.accepted).length;
    final rCount = widget.offers.where((o) => o.status == OfferStatus.rejected).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTopBar(title: 'Driver Offers',
          subtitle: '${widget.offers.length} drivers available',
          leading: TraderIconButton(
              icon: Icons.arrow_back_ios_new_rounded, onTap: widget.onBack)),
      const SizedBox(height: 16),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: [
          _FilterTab(label: 'Pending',  count: pCount,
              selected: _filterIndex == 0, t: widget.t,
              onTap: () => setState(() { _filterIndex = 0; _page = 0; })),
          const SizedBox(width: 8),
          _FilterTab(label: 'Accepted', count: aCount,
              selected: _filterIndex == 1, t: widget.t,
              onTap: () => setState(() { _filterIndex = 1; _page = 0; })),
          const SizedBox(width: 8),
          _FilterTab(label: 'Rejected', count: rCount,
              selected: _filterIndex == 2, t: widget.t,
              onTap: () => setState(() { _filterIndex = 2; _page = 0; })),
        ]),
      ),
      const SizedBox(height: 16),
      if (items.isEmpty) _StaggeredList(
        count: 3,
        itemBuilder: (context, index) {
          final String avatar = index == 0 ? 'م ح' : (index == 1 ? 'A M' : 'Y A');
          final String name = index == 0 ? 'محمود حسن ' : (index == 1 ? 'Ahmed Mohamed' : 'Yasser Ahmed');
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF071A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(.15),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF12D6E3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '• 8 mins ago',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF00D4FF),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '3.1 km',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Van',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Price & ETA
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081426),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Offer Price',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '220',
                                style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white10,
                        ),
                        const SizedBox(width: 24),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Color(0xFF00D4FF),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ETA',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '20 mins',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(
                              color: Colors.red,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Accept',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: const Color(0xFF12D6E3),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF12D6E3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      )
      else ...[
        _StaggeredList(count: items.length,
            itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferTile(offer: items[i], t: widget.t,
                    onAccept: () => widget.onAccept(items[i])))),
        _Pager(t: widget.t, page: _page, total: total,
            onPrev: _page == 0 ? null : () => setState(() => _page--),
            onNext: _page >= total - 1 ? null : () => setState(() => _page++)),
      ],
    ]);
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final TraderTheme t;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.count,
    required this.selected, required this.t, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: _kFastAnim, curve: _kEaseOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
          color: selected ? TraderTheme.accent : t.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? TraderTheme.accent : t.border, width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
            color: selected ? Colors.white : t.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.25) : t.surfaceDeep,
              borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(
              color: selected ? Colors.white : t.textMuted,
              fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  ALERTS PAGE
// ══════════════════════════════════════════════════════════
class _AlertsPage extends StatelessWidget {
  final List<TraderNotification> notifications;
  final VoidCallback onBack;
  final TraderTheme t;
  const _AlertsPage({required this.notifications, required this.onBack,
    required this.t});

  @override
  Widget build(BuildContext context) {
    final textPrimary = t.isDark
        ? const Color(0xFFF0FDFA) : const Color(0xFF1A2A3A);
    final textMuted   = t.isDark
        ? const Color(0x80CBFBF1) : const Color(0xFF7A93A8);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTopBar(
        title: 'Alerts',
        subtitle: '${notifications.length} recent updates',
        leading: TraderIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
      ),
      const SizedBox(height: 18),
      _StaggeredList(count: notifications.length, itemBuilder: (_, i) {
        final item = notifications[i];
        final dotColor = item.type == NotificationType.offer
            ? const Color(0xFFFF8904)
            : item.type == NotificationType.payment
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 32, child: Column(children: [
                Container(width: 24, height: 24,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor.withOpacity(0.2),
                        border: Border.all(color: dotColor, width: 1.6)),
                    child: Center(child: Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: dotColor)))),
                if (i < notifications.length - 1)
                  Expanded(child: Container(width: 2,
                      color: const Color(0xFF00D5BE).withOpacity(0.2))),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.timeLabel, style: TextStyle(
                          color: textMuted.withOpacity(0.7), fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: t.isDark
                              ? const Color(0xFF0A1520)
                              : const Color(0xFFF0F7F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: dotColor.withOpacity(0.15)),
                          boxShadow: t.cardShadow,
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: dotColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                        item.type == NotificationType.offer
                                            ? 'Action Required'
                                            : item.type == NotificationType.payment
                                            ? 'Info' : 'Update',
                                        style: TextStyle(color: dotColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                              ),
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: t.surface,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [
                                  Container(width: 38, height: 38,
                                      decoration: BoxDecoration(
                                          color: dotColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10)),
                                      child: Icon(notificationIcon(item.type),
                                          color: dotColor, size: 18)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title, style: TextStyle(
                                            color: textPrimary, fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(item.subtitle, style: TextStyle(
                                            color: textMuted, fontSize: 12,
                                            height: 1.4)),
                                      ])),
                                ]),
                              ),
                              if (item.type == NotificationType.offer)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, '/driver_offers'),
                                    child: Container(
                                      width: double.infinity, height: 42,
                                      decoration: BoxDecoration(
                                          color: dotColor,
                                          borderRadius: BorderRadius.circular(12)),
                                      alignment: Alignment.center,
                                      child: const Text('View Offer',
                                          style: TextStyle(color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ),
                            ]),
                      ),
                    ]),
              )),
            ]),
          ),
        );
      }),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  SHARED TILES
// ══════════════════════════════════════════════════════════
class _ShipTile extends StatelessWidget {
  final Shipment shipment; final VoidCallback onTap; final TraderTheme t;
  const _ShipTile({required this.shipment, required this.onTap,
    required this.t});
  @override
  Widget build(BuildContext context) => _SpringTapButton(
    onTap: onTap, tapScale: 0.98,
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.surfaceDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
          boxShadow: t.isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
              : [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Row(children: [
          Text(shipment.departureDate
              .replaceAll('2026-01-', 'Jan ')
              .replaceAll('-', '/'),
              style: TextStyle(color: t.textMuted, fontSize: 11)),
          const Spacer(),
          StatusPill(label: shipmentStatusLabel(shipment.status),
              color: shipmentStatusColor(shipment.status)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.circle, color: TraderTheme.accent, size: 7),
          const SizedBox(width: 6),
          Expanded(child: Text(
              '${shipment.origin}  →  ${shipment.destination}',
              style: TextStyle(color: t.textPrimary,
                  fontWeight: FontWeight.w600))),
          Text('\$${shipment.price.toStringAsFixed(0)}',
              style: const TextStyle(color: TraderTheme.accent,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft,
            child: Text('Driver: ${shipment.driverName}',
                style: TextStyle(color: t.textMuted, fontSize: 11))),
      ]),
    ),
  );
}

class _OfferTile extends StatelessWidget {
  final DriverOffer offer; final VoidCallback onAccept; final TraderTheme t;
  const _OfferTile({required this.offer, required this.onAccept,
    required this.t});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: t.isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]
            : t.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 22, backgroundColor: TraderTheme.accent,
            child: Text(offer.driverName.split(' ')
                .map((p) => p[0]).take(2).join(),
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.driverName, style: TextStyle(
                  color: t.textPrimary, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star, color: Color(0xFFF4C14B), size: 13),
                const SizedBox(width: 3),
                Text(offer.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Color(0xFFF4C14B), fontSize: 12)),
                Text('  ·  ${offer.etaHours} mins ago',
                    style: TextStyle(color: t.textMuted, fontSize: 12)),
              ]),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    color: t.textMuted, size: 13),
                Text(' ${(offer.etaHours * 1.2).toStringAsFixed(1)} km'
                    '  ${offer.vehicleType}',
                    style: TextStyle(color: t.textMuted, fontSize: 12)),
              ]),
            ])),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Offer Price',
              style: TextStyle(color: t.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text('\$${offer.price.toStringAsFixed(0)}',
              style: const TextStyle(color: TraderTheme.accent,
                  fontSize: 26, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('ETA', style: TextStyle(color: t.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.access_time_outlined,
                color: t.textMuted, size: 14),
            const SizedBox(width: 4),
            Text('${offer.etaHours * 5} mins',
                style: TextStyle(color: t.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF476D),
                side: BorderSide(
                    color: const Color(0xFFFF476D).withOpacity(0.5)),
                backgroundColor: const Color(0xFFFF476D).withOpacity(0.07),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Reject',
                style: TextStyle(fontWeight: FontWeight.w600)))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
                backgroundColor: TraderTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Accept',
                style: TextStyle(fontWeight: FontWeight.w700)))),
      ]),
    ]),
  );
}

class _Pager extends StatelessWidget {
  final int page, total;
  final VoidCallback? onPrev, onNext;
  final TraderTheme t;
  const _Pager({required this.page, required this.total,
    required this.onPrev, required this.onNext, required this.t});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('Page ${page + 1} / $total',
        style: TextStyle(color: t.textMuted, fontSize: 11)),
    const Spacer(),
    TraderIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
    const SizedBox(width: 8),
    TraderIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
  ]);
}

// ══════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF34C759).withOpacity(0.07)
      ..strokeWidth = 0.6;
    final dotPaint = Paint()
      ..color = const Color(0xFF34C759).withOpacity(0.05);
    const step = 45.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF34C759).withOpacity(0.05)
      ..strokeWidth = 0.4;
    for (double y = 0; y <= size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _RouteGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(55, 135)
      ..quadraticBezierTo(185, 90, 305, 65);
    final rect = const Rect.fromLTWH(55, 65, 250, 70);

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF34C759).withOpacity(0.25)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF34C759).withOpacity(0.40)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawPath(path, Paint()
      ..shader = const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30B0C7)])
          .createShader(rect)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(_) => false;
}

class _RouteDotsAnimPainter extends CustomPainter {
  final List<double> progresses;
  static const _colors    = [Color(0xFF34C759), Color(0xFF30B0C7), Color(0xFF34C759)];
  static const _radii     = [2.5, 2.0, 1.5];
  static const _opacities = [0.8, 0.6, 0.5];
  const _RouteDotsAnimPainter({required this.progresses});

  Offset _bezier(double t) {
    const p0 = Offset(55, 135); const p1 = Offset(185, 90);
    const p2 = Offset(305, 65);
    final mt = 1 - t;
    return Offset(
        mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
        mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < progresses.length; i++) {
      final pos = _bezier(progresses[i]);
      canvas.drawCircle(pos, _radii[i],
          Paint()..color = _colors[i].withOpacity(_opacities[i]));
    }
  }
  @override bool shouldRepaint(_RouteDotsAnimPainter o) =>
      o.progresses != progresses;
}

// ══════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════
String shipmentStatusLabel(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.pending:   return 'Pending';
    case ShipmentStatus.inTransit: return 'In Transit';
    case ShipmentStatus.delivered: return 'Delivered';
    case ShipmentStatus.cancelled: return 'Cancelled';
  }
}

Color shipmentStatusColor(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.pending:   return const Color(0xFFF3B64C);
    case ShipmentStatus.inTransit: return const Color(0xFF3A73FF);
    case ShipmentStatus.delivered: return TraderTheme.accent;
    case ShipmentStatus.cancelled: return TraderTheme.danger;
  }
}

IconData notificationIcon(NotificationType t) {
  switch (t) {
    case NotificationType.offer:    return Icons.handshake_outlined;
    case NotificationType.shipment: return Icons.local_shipping_outlined;
    case NotificationType.payment:  return Icons.payments_outlined;
    case NotificationType.system:   return Icons.info_outline;
  }
}