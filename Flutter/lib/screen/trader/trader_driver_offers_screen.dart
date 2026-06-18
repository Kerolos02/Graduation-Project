import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TRADER DRIVER OFFERS SCREEN — trader_driver_offers_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

enum OffersState { withOffers, empty, loading, error }

const Duration _kFast = Duration(milliseconds: 250);
const Duration _kMed  = Duration(milliseconds: 450);
const Cubic _kEaseSpring = Cubic(0.22, 1.0, 0.36, 1.0);

// ── Tap scale 0.96 ────────────────────────────────────────────────────────────
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override State<_Tap> createState() => _TapState();
}
class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: ()  => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width, height, radius;
  const _Shimmer({required this.width, required this.height, this.radius = 8});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF00D5BE).withOpacity(0.12),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

// ── Skeleton card ─────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1628).withOpacity(0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: const Color(0xFF00D5BE).withOpacity(0.2), width: 0.8),
    ),
    child: Column(children: [
      Row(children: [
        const _Shimmer(width: 44, height: 44, radius: 12),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Shimmer(width: 120, height: 14, radius: 6),
            SizedBox(height: 8),
            _Shimmer(width: 180, height: 11, radius: 5),
          ],
        )),
      ]),
      const SizedBox(height: 12),
      const _Shimmer(width: double.infinity, height: 52, radius: 12),
      const SizedBox(height: 12),
      Row(children: const [
        _Shimmer(width: 44, height: 40, radius: 12),
        SizedBox(width: 10),
        Expanded(child: _Shimmer(width: double.infinity, height: 40, radius: 12)),
      ]),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TraderDriverOffersScreen extends StatefulWidget {
  // ✅ shipmentId required للـ API calls
  final String shipmentId;
  final String shipmentFrom, shipmentTo, shipmentInfo;

  const TraderDriverOffersScreen({
    super.key,
    required this.shipmentId,           // ✅ required — UUID من الـ shipment
    this.shipmentFrom = 'Maadi',
    this.shipmentTo   = 'Nasr City',
    this.shipmentInfo = '2.5 tons · Flatbed Truck',
  });

  @override
  State<TraderDriverOffersScreen> createState() =>
      _TraderDriverOffersScreenState();
}

class _TraderDriverOffersScreenState
    extends State<TraderDriverOffersScreen> with TickerProviderStateMixin {

  // ✅ الـ offers هتيجي من الـ API عبر provider
  List<dynamic> _localOffers = []; // نسخة محلية عشان نعمل dismiss animation

  // page entry
  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  // header
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  // banner
  late AnimationController _bannerCtrl;
  late Animation<double>   _bannerFade;
  late Animation<double>   _bannerScale;

  // cards stagger
  final List<AnimationController> _cardCtrls  = [];
  final List<Animation<double>>   _cardFades  = [];
  final List<Animation<Offset>>   _cardSlides = [];

  // per-card dismiss
  final Map<String, AnimationController> _dismissCtrls = {};
  final Map<String, Animation<double>>   _dismissFades = {};
  final Map<String, Animation<double>>   _dismissSizes = {};

  @override
  void initState() {
    super.initState();

    // Page entry
    _pageCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    // Header
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100),
        () { if (mounted) _headerCtrl.forward(); });

    // Banner
    _bannerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _bannerFade  = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut);
    _bannerScale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _bannerCtrl, curve: _kEaseSpring));
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _bannerCtrl.forward(); });

    // ✅ جيب الـ offers من الـ API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffers();
    });
  }

  // ✅ GET /api/trader/mobile/shipments/{shipmentId}/offers
  Future<void> _loadOffers() async {
    final provider = context.read<TraderProvider>();
    await provider.loadOffers(
      shipmentId: widget.shipmentId,
      tab: 'pending',
    );
    if (mounted) {
      _syncOffersFromProvider();
    }
  }

  // ✅ بنسخ الـ offers من الـ provider للـ local list وبنعمل controllers ليهم
  void _syncOffersFromProvider() {
    final provider = context.read<TraderProvider>();
    final newOffers = List<dynamic>.from(provider.offers);

    // عمل controllers للـ offers الجديدة بس
    for (final offer in newOffers) {
      final id = _getOfferId(offer);
      if (!_dismissCtrls.containsKey(id)) {
        final c = AnimationController(vsync: this,
            duration: const Duration(milliseconds: 300));
        _dismissCtrls[id] = c;
        _dismissFades[id] = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut));
        _dismissSizes[id] = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut));
      }
    }

    // عمل card animation controllers
    _cardCtrls.clear();
    _cardFades.clear();
    _cardSlides.clear();
    for (int i = 0; i < newOffers.length; i++) {
      final c = AnimationController(vsync: this,
          duration: const Duration(milliseconds: 500));
      _cardCtrls.add(c);
      _cardFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
      _cardSlides.add(Tween<Offset>(
              begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: _kEaseSpring)));
      Future.delayed(Duration(milliseconds: 300 + i * 80),
          () { if (mounted) c.forward(); });
    }

    setState(() => _localOffers = newOffers);
  }

  // ✅ helper — بيجيب الـ id من الـ offer map
  String _getOfferId(dynamic offer) {
    return (offer['offerId'] ?? offer['id'] ?? '').toString();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _bannerCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    for (final c in _dismissCtrls.values) c.dispose();
    super.dispose();
  }

  // ✅ Reject — POST /api/trader/mobile/offers/{offerId}/reject
  Future<void> _rejectOffer(String offerId) async {
    // animate out الأول
    await _dismissCtrls[offerId]?.forward();
    if (!mounted) return;

    final provider = context.read<TraderProvider>();
    final ok = await provider.rejectOffer(offerId: offerId);

    if (mounted) {
      if (ok) {
        setState(() => _localOffers.removeWhere(
            (o) => _getOfferId(o) == offerId));
      } else {
        // لو الـ API فشل، رجّع الـ animation
        _dismissCtrls[offerId]?.reverse();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.error ?? 'Failed to reject offer'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  // ✅ Accept — POST /api/trader/mobile/offers/{offerId}/accept
  Future<void> _acceptOffer(String offerId) async {
    // animate out الأول
    await _dismissCtrls[offerId]?.forward();
    if (!mounted) return;

    final provider = context.read<TraderProvider>();
    final ok = await provider.acceptOffer(offerId: offerId);

    if (mounted) {
      if (ok) {
        setState(() => _localOffers.removeWhere(
            (o) => _getOfferId(o) == offerId));
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.pushNamed(context, '/map');
      } else {
        // لو الـ API فشل، رجّع الـ animation
        _dismissCtrls[offerId]?.reverse();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.error ?? 'Failed to accept offer'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final provider = context.watch<TraderProvider>();

    const kBg     = Color(0xFF0A1A24);
    const kTeal   = Color(0xFF00D5BE);
    final kCard   = const Color(0xFF0A1628).withOpacity(0.6);
    final kBorder = kTeal.withOpacity(0.2);
    const kText   = Color(0xFFF0FDF9);
    final kMuted  = const Color(0xFFCBFBF1).withOpacity(0.5);

    // ✅ نحدد الـ state من الـ provider
    final OffersState currentState;
    if (provider.isLoading && _localOffers.isEmpty) {
      currentState = OffersState.loading;
    } else if (provider.error != null && _localOffers.isEmpty) {
      currentState = OffersState.error;
    } else if (_localOffers.isEmpty) {
      currentState = OffersState.empty;
    } else {
      currentState = OffersState.withOffers;
    }

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Row(children: [
                      _Tap(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1628).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder, width: 0.8),
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: Color(0xFF00D5BE), size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Driver Offers',
                              style: TextStyle(color: kText, fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${_localOffers.length} driver${_localOffers.length != 1 ? "s" : ""} available',
                            style: TextStyle(color: kMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Shipment banner ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _bannerFade,
                  child: ScaleTransition(
                    scale: _bannerScale,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kTeal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Shipment',
                              style: TextStyle(color: kMuted, fontSize: 11)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text(widget.shipmentFrom,
                                style: const TextStyle(
                                    color: kText, fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Color(0xFF00D5BE), size: 16),
                            const SizedBox(width: 8),
                            Text(widget.shipmentTo,
                                style: const TextStyle(
                                    color: kText, fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Text(widget.shipmentInfo,
                              style: TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Body ──
              Expanded(
                child: _buildBody(
                  state: currentState,
                  kCard: kCard, kBorder: kBorder,
                  kText: kText, kMuted: kMuted,
                  kTeal: kTeal, isDark: isDark,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required OffersState state,
    required Color kCard, required Color kBorder,
    required Color kText, required Color kMuted,
    required Color kTeal, required bool isDark,
  }) {
    switch (state) {
      case OffersState.loading:
        return _buildLoading();
      case OffersState.empty:
        return _buildEmpty(kText: kText, kMuted: kMuted, kTeal: kTeal);
      case OffersState.error:
        return _buildError(kText: kText, kMuted: kMuted, kTeal: kTeal);
      case OffersState.withOffers:
        return _buildOffers(
          kCard: kCard, kBorder: kBorder,
          kText: kText, kMuted: kMuted,
          kTeal: kTeal, isDark: isDark,
        );
    }
  }

  Widget _buildLoading() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: 4,
    itemBuilder: (_, __) => const _SkeletonCard(),
  );

  Widget _buildEmpty({
    required Color kText, required Color kMuted, required Color kTeal,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: kTeal.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: kTeal.withOpacity(0.2)),
          ),
          child: Icon(Icons.check, color: kTeal.withOpacity(0.5), size: 32),
        ),
        const SizedBox(height: 20),
        Text('All offers reviewed',
            style: TextStyle(color: kText, fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Check your active shipments or create a new one',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
        _Tap(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kTeal, const Color(0xFF009689)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Go to Home',
                style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildError({
    required Color kText, required Color kMuted, required Color kTeal,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 32),
        ),
        const SizedBox(height: 20),
        Text('Failed to load offers',
            style: TextStyle(color: kText, fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Please try again later',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14)),
        const SizedBox(height: 24),
        // ✅ Retry بيكلم الـ API
        _Tap(
          onTap: _loadOffers,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kTeal, const Color(0xFF009689)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildOffers({
    required Color kCard, required Color kBorder,
    required Color kText, required Color kMuted,
    required Color kTeal, required bool isDark,
  }) {
    if (_localOffers.isEmpty) {
      return _buildEmpty(kText: kText, kMuted: kMuted, kTeal: kTeal);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: _localOffers.length,
      itemBuilder: (_, i) {
        final offer  = _localOffers[i] as Map<String, dynamic>;
        final id     = _getOfferId(offer);

        // ✅ Map الـ API data للـ card fields
        final name      = offer['driverName']    ?? offer['name']     ?? 'Driver';
        final initials  = _getInitials(name);
        final truckType = offer['vehicleType']   ?? offer['truckType'] ?? 'Truck';
        final rating    = (offer['driverRating'] ?? offer['rating']   ?? 0.0) is num
            ? (offer['driverRating'] ?? offer['rating'] ?? 0.0).toDouble()
            : 0.0;
        final trips     = (offer['totalTrips']   ?? offer['trips']    ?? 0) as int;
        final price     = (offer['price']        ?? offer['amount']   ?? 0) is num
            ? (offer['price'] ?? offer['amount'] ?? 0).toInt()
            : 0;

        final fade  = i < _cardFades.length
            ? _cardFades[i]
            : const AlwaysStoppedAnimation(1.0);
        final slide = i < _cardSlides.length
            ? _cardSlides[i]
            : const AlwaysStoppedAnimation(Offset.zero);

        final dismissCtrl = _dismissCtrls[id];
        final dismissFade = _dismissFades[id];
        final dismissSize = _dismissSizes[id];

        if (dismissCtrl == null) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: dismissCtrl,
          builder: (_, child) => SizeTransition(
            sizeFactor: dismissSize!,
            axisAlignment: -1,
            child: FadeTransition(opacity: dismissFade!, child: child),
          ),
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OfferCard(
                  offerId:  id,
                  name:     name,
                  initials: initials,
                  truckType: truckType,
                  rating:   rating,
                  trips:    trips,
                  price:    price,
                  kCard:    kCard,
                  kBorder:  kBorder,
                  kText:    kText,
                  kMuted:   kMuted,
                  kTeal:    kTeal,
                  onReject: () => _rejectOffer(id),
                  onAccept: () => _acceptOffer(id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ helper لعمل initials من الاسم
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '??';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OFFER CARD WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _OfferCard extends StatefulWidget {
  final String offerId, name, initials, truckType;
  final double rating;
  final int trips, price;
  final Color kCard, kBorder, kText, kMuted, kTeal;
  final VoidCallback onReject, onAccept;

  const _OfferCard({
    required this.offerId,
    required this.name,    required this.initials,
    required this.truckType, required this.rating,
    required this.trips,   required this.price,
    required this.kCard,   required this.kBorder,
    required this.kText,   required this.kMuted,
    required this.kTeal,
    required this.onReject, required this.onAccept,
  });

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _pressed = true),
      onExit:  (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _kFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? widget.kTeal.withOpacity(0.4)
                : widget.kTeal.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Column(children: [

          // ── Driver info ──
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D5BE), Color(0xFF009689)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF00D5BE).withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: Text(widget.initials,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: TextStyle(color: widget.kText, fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(widget.truckType,
                      style: TextStyle(color: widget.kMuted, fontSize: 11)),
                  const SizedBox(width: 6),
                  Container(width: 3, height: 3,
                      decoration: BoxDecoration(
                          color: widget.kMuted, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 13),
                  const SizedBox(width: 2),
                  Text('${widget.rating}',
                      style: TextStyle(color: widget.kMuted, fontSize: 11)),
                  const SizedBox(width: 6),
                  Container(width: 3, height: 3,
                      decoration: BoxDecoration(
                          color: widget.kMuted, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${widget.trips} trips',
                      style: TextStyle(color: widget.kMuted, fontSize: 11)),
                ]),
              ],
            )),
          ]),
          const SizedBox(height: 12),

          // ── Price box ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D5BE).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF00D5BE).withOpacity(0.2),
                  width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Price', style: TextStyle(
                      color: widget.kMuted, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('\$${widget.price}',
                      style: const TextStyle(
                          color: Color(0xFF00D5BE), fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Delivery', style: TextStyle(
                      color: widget.kMuted, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('4-5 hrs', style: TextStyle(
                      color: widget.kText, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Action buttons ──
          Row(children: [
            // Reject
            _Tap(
              onTap: widget.onReject,
              child: Container(
                width: 44, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      width: 0.8),
                ),
                child: const Icon(Icons.close,
                    color: Color(0xFFEF4444), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            // Accept
            Expanded(child: _Tap(
              onTap: widget.onAccept,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009689), Color(0xFF00BBA7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF00D5BE).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Accept',
                        style: TextStyle(color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}