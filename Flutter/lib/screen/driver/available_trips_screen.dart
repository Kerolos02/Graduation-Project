import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/models/driver_models.dart';
import '/services/driver_service.dart';

// ─── Floating animated background blobs ───────────────────────────────────
class _FloatingBlobs extends StatefulWidget {
  const _FloatingBlobs();
  @override
  State<_FloatingBlobs> createState() => _FloatingBlobsState();
}

class _FloatingBlobsState extends State<_FloatingBlobs>
    with TickerProviderStateMixin {
  late AnimationController _tealCtrl;
  late AnimationController _amberCtrl;
  late Animation<Offset> _tealAnim;
  late Animation<Offset> _amberAnim;

  @override
  void initState() {
    super.initState();
    _tealCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _tealAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(30, -20))
        .animate(CurvedAnimation(parent: _tealCtrl, curve: Curves.easeInOut));

    _amberCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _amberAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-20, 30))
        .animate(CurvedAnimation(parent: _amberCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tealCtrl.dispose();
    _amberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(
        animation: _tealAnim,
        builder: (_, __) => Positioned(
          top: 80 + _tealAnim.value.dy,
          right: 40 + _tealAnim.value.dx,
          child: Container(
            width: 256, height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.05),
            ),
          ),
        ),
      ),
      AnimatedBuilder(
        animation: _amberAnim,
        builder: (_, __) => Positioned(
          top: 160 + _amberAnim.value.dy,
          left: 40 + _amberAnim.value.dx,
          child: Container(
            width: 192, height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withOpacity(0.05),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── Press-scale wrapper ───────────────────────────────────────────────────
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
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _anim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _anim, child: widget.child),
  );
}

// ─── Shimmer Accept button ─────────────────────────────────────────────────
class _ShimmerBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  const _ShimmerBtn({required this.label, required this.onTap, this.height = 46});

  @override
  State<_ShimmerBtn> createState() => _ShimmerBtnState();
}

class _ShimmerBtnState extends State<_ShimmerBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _x;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
    _x = Tween<double>(begin: -300, end: 300)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: widget.onTap,
      scale: 0.98,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF00B4A0)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: _x,
            builder: (_, __) => Transform.translate(
              offset: Offset(_x.value, 0),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(widget.label, style: const TextStyle(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  AVAILABLE TRIPS SCREEN
// ══════════════════════════════════════════════════════
class AvailableTripsBrowseScreen extends StatefulWidget {
  const AvailableTripsBrowseScreen({super.key});

  @override
  State<AvailableTripsBrowseScreen> createState() => _AvailableTripsBrowseScreenState();
}

class _AvailableTripsBrowseScreenState extends State<AvailableTripsBrowseScreen>
    with TickerProviderStateMixin {

  final DriverService _service = DriverService();
  bool _isLoading = false;

  // ── animation controllers ──
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;
  late Animation<double>   _listFade;

  final List<AnimationController> _cardCtrls  = [];
  final List<Animation<double>>   _cardFades  = [];
  final List<Animation<Offset>>   _cardSlides = [];

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..forward();
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _listCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _listFade = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _listCtrl.forward(); });

    // ── Load trips from API ──
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrips());
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    await context.read<DriverProvider>().loadAvailableTrips();
    if (mounted) {
      final count = context.read<DriverProvider>().availableTrips.length;
      _buildCardAnims(count);
      setState(() => _isLoading = false);
    }
  }

  void _buildCardAnims(int count) {
    for (final c in _cardCtrls) c.dispose();
    _cardCtrls.clear(); _cardFades.clear(); _cardSlides.clear();
    for (int i = 0; i < count; i++) {
      final c = AnimationController(vsync: this,
          duration: const Duration(milliseconds: 450));
      _cardCtrls.add(c);
      _cardFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _cardSlides.add(Tween<Offset>(
              begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 300 + i * 100),
          () { if (mounted) c.forward(); });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  // ── Accept: POST /api/driver/trips/requests/{requestId}/accept ──
  Future<void> _handleAccept(BuildContext context, AvailableTrip trip) async {
    final result = await context.read<DriverProvider>().acceptTrip(trip);
    if (!mounted) return;
    if (result) {
      Navigator.pushReplacementNamed(context, '/trip_assigned');
    } else {
      final err = context.read<DriverProvider>().error ?? 'Failed to accept trip';
      // 409 = already has active trip / race condition
      // 410 = expired or cancelled
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  // ── Reject: POST /api/driver/trips/requests/{requestId}/reject ──
  Future<void> _handleReject(BuildContext context, AvailableTrip trip) async {
    await context.read<DriverProvider>().rejectTrip(trip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Trip rejected'),
      backgroundColor: Color(0xFF5F7E97),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final driver = context.watch<DriverProvider>();
    final trips  = driver.availableTrips;
    final t      = themeProvider.theme;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          const _FloatingBlobs(),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Row(
                        children: [
                          _PressScale(
                            onTap: () => Navigator.pop(context),
                            scale: 0.88,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: t.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.border),
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: AppTheme.primary, size: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available Trips',
                                  style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                _isLoading
                                    ? 'Loading...'
                                    : '${trips.length} trips near you',
                                style: TextStyle(
                                    color: t.textMuted, fontSize: 13)),
                            ],
                          ),

                          const Spacer(),

                          // ── Refresh button ──
                          _PressScale(
                            onTap: _loadTrips,
                            scale: 0.88,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: t.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.border),
                              ),
                              child: _isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                          color: AppTheme.primary, strokeWidth: 2),
                                    )
                                  : Icon(Icons.refresh_rounded,
                                      color: AppTheme.primary, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── List ──
                Expanded(
                  child: FadeTransition(
                    opacity: _listFade,
                    child: _isLoading && trips.isEmpty
                        ? _loadingState(t)
                        : trips.isEmpty
                            ? _emptyState(t)
                            : RefreshIndicator(
                                color: AppTheme.primary,
                                onRefresh: _loadTrips,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: trips.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (ctx, i) {
                                    final fade  = i < _cardFades.length
                                        ? _cardFades[i]
                                        : const AlwaysStoppedAnimation(1.0);
                                    final slide = i < _cardSlides.length
                                        ? _cardSlides[i]
                                        : const AlwaysStoppedAnimation(Offset.zero);
                                    return FadeTransition(
                                      opacity: fade,
                                      child: SlideTransition(
                                        position: slide,
                                        child: _TripCard(
                                          trip: trips[i],
                                          theme: t,
                                          onAccept: () => _handleAccept(ctx, trips[i]),
                                          onReject: () => _handleReject(ctx, trips[i]),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState(AppTheme t) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
        const SizedBox(height: 16),
        Text('Finding trips near you...',
            style: TextStyle(color: t.textMuted, fontSize: 14)),
      ]),
    );
  }

  Widget _emptyState(AppTheme t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.1),
            ),
            child: Icon(Icons.inbox_outlined,
                color: AppTheme.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text('No trips available right now',
              style: TextStyle(color: t.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Check back soon for new shipments',
              style: TextStyle(color: t.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          _PressScale(
            onTap: _loadTrips,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: const Text('Refresh',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TRIP CARD
// ══════════════════════════════════════════════════════
class _TripCard extends StatefulWidget {
  final AvailableTrip trip;
  final AppTheme theme;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TripCard({
    required this.trip,
    required this.theme,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard>
    with TickerProviderStateMixin {
  bool _expanded = false;

  late AnimationController _expandCtrl;
  late Animation<double>   _expandAnim;

  late AnimationController _borderCtrl;
  late Animation<Color?>   _borderAnim;

  @override
  void initState() {
    super.initState();

    _expandCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeOutCubic);

    _borderCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3000))..repeat();
    _borderAnim = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(
              begin: AppTheme.primary.withOpacity(0.15),
              end: const Color(0xFFF59E0B).withOpacity(0.45)),
          weight: 50),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFFF59E0B).withOpacity(0.45),
              end: AppTheme.primary.withOpacity(0.15)),
          weight: 50),
    ]).animate(_borderCtrl);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.trip;
    final theme = widget.theme;

    return AnimatedBuilder(
      animation: _borderAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _borderAnim.value ?? AppTheme.primary.withOpacity(0.15),
              width: 0.8),
          boxShadow: theme.cardShadow,
        ),
        child: child,
      ),
      child: Column(
        children: [
          // ── Main Info ──
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _expandCtrl.forward();
              else _expandCtrl.reverse();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.id,
                          style: TextStyle(
                              color: theme.textMuted, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${t.price.toStringAsFixed(0)} EGP',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: AppTheme.primary)),
                        Container(width: 1.5, height: 32,
                            color: AppTheme.primary.withOpacity(0.3)),
                        Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Color(0xFF0E8FD4))),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.origin,
                                style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 14),
                            Text(t.destination,
                                style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _statChip(Icons.route_outlined, t.distance, theme),
                      const SizedBox(width: 8),
                      _statChip(Icons.access_time_outlined, t.estimatedTime, theme),
                      const SizedBox(width: 8),
                      _statChip(Icons.monitor_weight_outlined,
                          '${t.weightTons} ton', theme),
                    ],
                  ),

                  if (t.isFragile || t.isRefrigerated) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      if (t.isFragile) ...[
                        _tag(Icons.warning_amber_rounded, 'Fragile',
                            const Color(0xFFF59E0B), theme),
                        const SizedBox(width: 8),
                      ],
                      if (t.isRefrigerated)
                        _tag(Icons.thermostat_outlined, 'Refrigerated',
                            const Color(0xFF00D3F2), theme),
                    ]),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: theme.textMuted, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Details ──
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(children: [
              Divider(color: theme.border, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            t.traderName.isNotEmpty ? t.traderName.substring(0, 1) : '?',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Trader',
                            style: TextStyle(color: theme.textMuted, fontSize: 11)),
                        Text(t.traderName,
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const Spacer(),
                      Row(children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(t.traderRating,
                            style: TextStyle(color: theme.textPrimary, fontSize: 13)),
                      ]),
                    ]),

                    const SizedBox(height: 14),
                    Divider(color: theme.border, height: 1),
                    const SizedBox(height: 14),

                    _detailRow('Cargo', t.goodsType, theme),
                    const SizedBox(height: 8),
                    _detailRow('Scheduled',
                        '${t.scheduledDate} · ${t.scheduledTime}', theme),
                  ],
                ),
              ),
            ]),
          ),

          // ── Accept / Reject Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _PressScale(
                    onTap: widget.onReject,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: theme.cardDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      alignment: Alignment.center,
                      child: Text('Reject',
                          style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ShimmerBtn(
                    label: 'Accept Trip',
                    onTap: widget.onAccept,
                    height: 46,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11)),
      ]),
    );
  }

  Widget _tag(IconData icon, String label, Color color, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _detailRow(String label, String value, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 13)),
        Text(value, style: TextStyle(
            color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}