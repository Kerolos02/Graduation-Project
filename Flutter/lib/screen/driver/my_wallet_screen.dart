import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/driver_service.dart'; // ← الـ service الموجود

// ══════════════════════════════════════════════════════
//  FILE: lib/screen/driver/my_wallet_screen.dart
//  CONNECTED TO BACKEND:
//    GET /api/driver/wallet/screen?filter=all|this_week|this_month&page=1&pageSize=10
//  All animations preserved exactly as original.
// ══════════════════════════════════════════════════════

const Color _kTeal  = Color(0xFF00D5BE);
const Color _kGreen = Color(0xFF00B4A0);

const Duration _kFast    = Duration(milliseconds: 300);
const Duration _kMed     = Duration(milliseconds: 500);
const Duration _kSlow    = Duration(milliseconds: 700);
const Duration _kStagger = Duration(milliseconds: 60);
const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;

// ── Trip Model — mapped from API response ──
class WalletTrip {
  final String id, from, to, date, status;
  final double amount;

  const WalletTrip({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.status,
    required this.amount,
  });

  /// من الـ API response:
  /// {
  ///   "tripId": "guid",
  ///   "shipmentNumber": "TRIP-4522",
  ///   "pickupLocation": "Cairo",
  ///   "dropoffLocation": "Alexandria",
  ///   "earnedAtFormatted": "2026-04-25 14:30",
  ///   "amountEGP": 240.00,
  ///   "status": "Completed"
  /// }
  factory WalletTrip.fromJson(Map<String, dynamic> json) {
    return WalletTrip(
      id:     json['shipmentNumber'] ?? json['tripId'] ?? '',
      from:   json['pickupLocation']  ?? '',
      to:     json['dropoffLocation'] ?? '',
      date:   json['earnedAtFormatted'] ?? json['earnedAt'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amountEGP'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Wallet Summary Model ──
class WalletSummary {
  final double totalEarnings;
  final double thisWeek;
  final double thisMonth;
  final int totalTrips;
  final int weeklyGrowthPercent;
  final String weeklyGrowthDirection; // "up" | "down"

  const WalletSummary({
    required this.totalEarnings,
    required this.thisWeek,
    required this.thisMonth,
    required this.totalTrips,
    required this.weeklyGrowthPercent,
    required this.weeklyGrowthDirection,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      totalEarnings:         (json['totalEarningsEGP'] as num?)?.toDouble() ?? 0,
      thisWeek:              (json['thisWeekEarningsEGP'] as num?)?.toDouble() ?? 0,
      thisMonth:             (json['thisMonthEarningsEGP'] as num?)?.toDouble() ?? 0,
      totalTrips:            (json['totalTripsCompleted'] as num?)?.toInt() ?? 0,
      weeklyGrowthPercent:   (json['weeklyGrowthPercent'] as num?)?.toInt() ?? 0,
      weeklyGrowthDirection: json['weeklyGrowthDirection'] ?? 'up',
    );
  }

  static WalletSummary empty() => const WalletSummary(
    totalEarnings: 0, thisWeek: 0, thisMonth: 0,
    totalTrips: 0, weeklyGrowthPercent: 0, weeklyGrowthDirection: 'up',
  );
}

// ══════════════════════════════════════════════════════
//  ANIMATED TAP
// ══════════════════════════════════════════════════════
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: ()  => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

// ══════════════════════════════════════════════════════
//  MY WALLET SCREEN — CONNECTED TO BACKEND
// ══════════════════════════════════════════════════════
class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});
  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen>
    with TickerProviderStateMixin {

  // ── State ──
  final DriverService _service = DriverService();

  int _selectedFilter = 0;
  // الـ filter values بتتطابق مع الـ API بالظبط
  final List<String> _filterLabels = ['All', 'This Week', 'This Month'];
  final List<String> _filterValues = ['all', 'this_week', 'this_month'];

  bool _isLoading = true;
  String? _errorMessage;
  WalletSummary _summary = WalletSummary.empty();
  List<WalletTrip> _trips = [];
  int _totalTripsCount = 0;

  // ── Animations ──
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<double>   _headerY;

  late AnimationController _cardCtrl;
  late Animation<double>   _cardScale;
  late Animation<double>   _cardFade;
  late Animation<double>   _cardY;

  late AnimationController _counterCtrl;
  late Animation<double>   _counterValue;

  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmerAnim;

  late AnimationController _statsCtrl;
  late List<Animation<double>> _statsFade;
  late List<Animation<double>> _statsY;

  late AnimationController _filterCtrl;
  late Animation<double>   _filterFade;
  late Animation<double>   _filterY;

  late AnimationController _listCtrl;
  List<Animation<double>> _cardFades = [];
  List<Animation<double>> _cardX     = [];

  late AnimationController _sectionCtrl;
  late Animation<double>   _sectionFade;
  late Animation<double>   _sectionY;

  static const int _kStatsCount = 3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _shimmerCtrl.repeat();
    _loadWalletData();
  }

  void _initAnimations() {
    _headerCtrl = AnimationController(vsync: this, duration: _kMed);
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerY    = Tween<double>(begin: -30.0, end: 0.0)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _cardCtrl  = AnimationController(vsync: this, duration: _kSlow);
    _cardScale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: _kEaseOutBack));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: _kEaseOutCubic);
    _cardY     = Tween<double>(begin: 30.0, end: 0.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: _kEaseOutCubic));

    _counterCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    // counterValue هيتحدث بعد ما يجي الـ response
    _counterValue = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _counterCtrl, curve: _kEaseOutCubic));

    _shimmerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    final statsTotalMs = 350 + _kStatsCount * _kStagger.inMilliseconds;
    _statsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: statsTotalMs));
    _statsFade = List.generate(_kStatsCount, (i) {
      final s = (i * _kStagger.inMilliseconds) / statsTotalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _statsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _statsY = List.generate(_kStatsCount, (i) {
      final s = (i * _kStagger.inMilliseconds) / statsTotalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 20.0, end: 0.0).animate(
          CurvedAnimation(parent: _statsCtrl,
              curve: Interval(s, e, curve: _kEaseOutBack)));
    });

    _filterCtrl = AnimationController(vsync: this, duration: _kMed);
    _filterFade = CurvedAnimation(parent: _filterCtrl, curve: _kEaseOutCubic);
    _filterY    = Tween<double>(begin: 10.0, end: 0.0)
        .animate(CurvedAnimation(parent: _filterCtrl, curve: _kEaseOutCubic));

    _sectionCtrl = AnimationController(vsync: this, duration: _kMed);
    _sectionFade = CurvedAnimation(parent: _sectionCtrl, curve: _kEaseOutCubic);
    _sectionY    = Tween<double>(begin: 10.0, end: 0.0)
        .animate(CurvedAnimation(parent: _sectionCtrl, curve: _kEaseOutCubic));

    // listCtrl هيتعمل في _buildListAnimations بعد ما نعرف عدد الـ trips
    _listCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
  }

  // ── بيبني animations الـ list بعد ما نعرف عدد الـ trips ──
  void _buildListAnimations(int count) {
    _listCtrl.dispose();
    final listTotalMs = 400 + count * _kStagger.inMilliseconds;
    _listCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: listTotalMs));
    _cardFades = List.generate(count, (i) {
      final s = (i * _kStagger.inMilliseconds) / listTotalMs;
      final e = (s + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _listCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _cardX = List.generate(count, (i) {
      final s = (i * _kStagger.inMilliseconds) / listTotalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: -25.0, end: 0.0).animate(
          CurvedAnimation(parent: _listCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
  }

  // ══════════════════════════════════════════════════════
  //  API CALL — GET /api/driver/wallet/screen
  // ══════════════════════════════════════════════════════
  Future<void> _loadWalletData({int filterIndex = 0}) async {
    if (!mounted) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    final filter = _filterValues[filterIndex];

    // الـ endpoint: GET /api/driver/wallet/screen?filter=all&page=1&pageSize=10
    final result = await _service.getWalletScreen(
      filter:   filter,
      page:     1,
      pageSize: 20,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data']?['data'] ?? result['data'] ?? {};

      // ── Parse Summary ──
      final summaryJson = data['summary'] as Map<String, dynamic>? ?? {};
      final summary     = WalletSummary.fromJson(summaryJson);

      // ── Parse Trips ──
      final recentTrips  = data['recentTrips'] as Map<String, dynamic>? ?? {};
      final tripsJson    = recentTrips['trips'] as List<dynamic>? ?? [];
      final trips        = tripsJson
          .map((t) => WalletTrip.fromJson(t as Map<String, dynamic>))
          .toList();
      final totalCount   = (recentTrips['totalCount'] as num?)?.toInt() ?? trips.length;

      // ── Rebuild list animations for new count ──
      _buildListAnimations(trips.length);

      setState(() {
        _summary        = summary;
        _trips          = trips;
        _totalTripsCount = totalCount;
        _isLoading      = false;
      });

      // ── Reset counter animation to new total ──
      _counterValue = Tween<double>(begin: 0, end: summary.totalEarnings)
          .animate(CurvedAnimation(parent: _counterCtrl, curve: _kEaseOutCubic));
      _counterCtrl.forward(from: 0);

      // ── Run entrance sequence ──
      _runSequence();
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load wallet data';
        _isLoading    = false;
      });
    }
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _statsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _filterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _sectionCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) _listCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardCtrl.dispose();
    _counterCtrl.dispose();
    _shimmerCtrl.dispose();
    _statsCtrl.dispose();
    _filterCtrl.dispose();
    _sectionCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // ── عند تغيير الـ filter — بيعمل API call جديد ──
  void _onFilterTap(int i) {
    if (_selectedFilter == i) return;
    setState(() => _selectedFilter = i);
    // reset animations
    _cardCtrl.forward(from: 0);
    _statsCtrl.forward(from: 0);
    _sectionCtrl.forward(from: 0);
    // fetch جديد بالـ filter الجديد
    _loadWalletData(filterIndex: i);
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark     = context.watch<ThemeProvider>().isDark;
    final kBg        = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFEFF4F8);
    final kCard      = isDark ? const Color(0xFF162535) : Colors.white;
    final kCardInner = isDark ? const Color(0xFF1C2F42) : const Color(0xFFF0F5FA);
    final kText      = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final kMuted     = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AnimatedBuilder(
              animation: _headerCtrl,
              builder: (_, child) => Opacity(
                opacity: _headerFade.value,
                child: Transform.translate(
                  offset: Offset(0, _headerY.value),
                  child: child,
                ),
              ),
              child: Row(children: [
                _Tap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: kCard, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: _kTeal, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Wallet', style: TextStyle(
                        color: kText, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Track your earnings and trip income',
                        style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                )),
                _Tap(
                  onTap: () => context.read<ThemeProvider>().toggleTheme(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: kCardInner, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 14, color: kMuted),
                      const SizedBox(width: 4),
                      Text(isDark ? 'Light' : 'Dark',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Body ──
          Expanded(child: _isLoading
              ? _buildLoading(kMuted)
              : _errorMessage != null
                  ? _buildError(kText, kMuted)
                  : _buildContent(isDark, kBg, kCard, kCardInner, kText, kMuted)),
        ]),
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoading(Color kMuted) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: _kTeal),
      const SizedBox(height: 12),
      Text('Loading wallet...', style: TextStyle(color: kMuted, fontSize: 14)),
    ]),
  );

  // ── Error ──
  Widget _buildError(Color kText, Color kMuted) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_outlined, color: kMuted, size: 48),
        const SizedBox(height: 12),
        Text(_errorMessage!, textAlign: TextAlign.center,
            style: TextStyle(color: kText, fontSize: 15)),
        const SizedBox(height: 20),
        _Tap(
          onTap: () => _loadWalletData(filterIndex: _selectedFilter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
                color: _kTeal, borderRadius: BorderRadius.circular(20)),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    ),
  );

  // ── Main Content ──
  Widget _buildContent(bool isDark, Color kBg, Color kCard,
      Color kCardInner, Color kText, Color kMuted) {
    final growthUp = _summary.weeklyGrowthDirection == 'up';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),

        // ── Main earnings card ──
        AnimatedBuilder(
          animation: _cardCtrl,
          builder: (_, child) => Opacity(
            opacity: _cardFade.value,
            child: Transform.translate(
              offset: Offset(0, _cardY.value),
              child: Transform.scale(scale: _cardScale.value, child: child),
            ),
          ),
          child: Stack(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Earnings',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                // ── Animated Counter — من الـ API ──
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('\$ ', style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  AnimatedBuilder(
                    animation: _counterValue,
                    builder: (_, __) => Text(
                      _counterValue.value.toInt().toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(' EGP', style: TextStyle(
                        color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 12),
                // ── Growth badge — من الـ API ──
                AnimatedBuilder(
                  animation: _cardFade,
                  builder: (_, child) => Opacity(opacity: _cardFade.value, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        growthUp ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white, size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${growthUp ? '+' : '-'}${_summary.weeklyGrowthPercent}% this week',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            // Shimmer
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(_shimmerAnim.value * 300, 0),
                  child: Container(
                    width: 80, height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.white12, Colors.transparent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Stats row — بيانات من الـ API ──
        Row(children: List.generate(_kStatsCount, (i) {
          final labels = ['This Week', 'This Month', 'Total Trips'];
          final values = [
            _summary.thisWeek.toStringAsFixed(0),
            _summary.thisMonth.toStringAsFixed(0),
            _summary.totalTrips.toString(),
          ];
          final units  = ['EGP', 'EGP', ''];
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: i < _kStatsCount - 1 ? 10 : 0),
            child: AnimatedBuilder(
              animation: _statsCtrl,
              builder: (_, child) => Opacity(
                opacity: _statsFade[i].value,
                child: Transform.translate(
                  offset: Offset(0, _statsY[i].value),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                    color: kCard, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(labels[i], style: TextStyle(color: kMuted, fontSize: 11)),
                  const SizedBox(height: 4),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: values[i], style: TextStyle(
                        color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (units[i].isNotEmpty)
                      TextSpan(text: ' ${units[i]}', style: TextStyle(
                          color: kMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ])),
                ]),
              ),
            ),
          ));
        })),
        const SizedBox(height: 16),

        // ── Filter tabs — بيعمل API call لما يتغير ──
        AnimatedBuilder(
          animation: _filterCtrl,
          builder: (_, child) => Opacity(
            opacity: _filterFade.value,
            child: Transform.translate(
              offset: Offset(0, _filterY.value),
              child: child,
            ),
          ),
          child: Row(children: [
            Icon(Icons.filter_list, color: kMuted, size: 18),
            const SizedBox(width: 10),
            ...List.generate(_filterLabels.length, (i) {
              final isSelected = _selectedFilter == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Tap(
                  onTap: () => _onFilterTap(i),
                  child: AnimatedContainer(
                    duration: _kFast,
                    curve: _kEaseOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? _kTeal : kCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_filterLabels[i], style: TextStyle(
                      color: isSelected ? Colors.black87 : kMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Section header — عدد الـ trips من الـ API ──
        AnimatedBuilder(
          animation: _sectionCtrl,
          builder: (_, child) => Opacity(
            opacity: _sectionFade.value,
            child: Transform.translate(
              offset: Offset(0, _sectionY.value),
              child: child,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Trips', style: TextStyle(
                  color: kText, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('$_totalTripsCount trips',
                  style: TextStyle(color: kMuted, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Trip cards — من الـ API ──
        if (_trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No trips found', style: TextStyle(color: kMuted, fontSize: 14)),
            ),
          )
        else
          ...List.generate(_trips.length, (i) {
            final trip = _trips[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: _listCtrl,
                builder: (_, child) => Opacity(
                  opacity: _cardFades[i].value,
                  child: Transform.translate(
                    offset: Offset(_cardX[i].value, 0),
                    child: child,
                  ),
                ),
                child: _Tap(
                  onTap: () {},
                  child: _TripCard(
                    trip: trip, isDark: isDark,
                    kCard: kCard, kText: kText, kMuted: kMuted,
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TRIP CARD
// ══════════════════════════════════════════════════════
class _TripCard extends StatelessWidget {
  final WalletTrip trip;
  final bool isDark;
  final Color kCard, kText, kMuted;
  const _TripCard({required this.trip, required this.isDark,
      required this.kCard, required this.kText, required this.kMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PulsingCheck(),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(trip.from, style: TextStyle(
                  color: kText, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, color: kMuted, size: 14)),
              Flexible(child: Text(trip.to, style: TextStyle(
                  color: kText, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.calendar_today_outlined, color: kMuted, size: 12),
              const SizedBox(width: 4),
              Text(trip.date, style: TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${trip.amount.toStringAsFixed(0)} EGP', style: const TextStyle(
                color: _kTeal, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(trip.status, style: const TextStyle(
                    color: _kTeal, fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ]),
        const SizedBox(height: 10),
        Text(trip.id, style: TextStyle(color: kMuted, fontSize: 11)),
      ]),
    );
  }
}

// ── Pulsing check icon ──
class _PulsingCheck extends StatefulWidget {
  @override
  State<_PulsingCheck> createState() => _PulsingCheckState();
}

class _PulsingCheckState extends State<_PulsingCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: _kTeal.withOpacity(0.12 * _a.value),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: _kTeal.withOpacity(0.2 * _a.value),
          blurRadius: 8,
        )],
      ),
      child: const Icon(Icons.check_circle_outline, color: _kTeal, size: 20),
    ),
  );
}