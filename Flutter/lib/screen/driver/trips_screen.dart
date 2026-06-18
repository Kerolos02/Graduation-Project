import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truck_mate/screen/driver/widgets/my_trip_card.dart';
import 'package:truck_mate/screen/driver/widgets/my_trips_card.dart';
import '/providers/theme_provider.dart';
import '/providers/driver_provider.dart';
import '/models/driver_models.dart';
import '/services/driver_service.dart';
import '/screen/driver/driver_trip_screens.dart'
    show
        TripAvailableScreen,
        RequestDetailsScreen,
        TripData,
        RequestAcceptedScreen;
import 'driver_pickup_screens.dart';

const Color _kTeal = Color(0xFF00D5BE);
const Color _kAmber = Color(0xFFF59E0B);

Color _bg(bool d) => d ? const Color(0xFF0F2334) : const Color(0xFFF5F8FA);
Color _card(bool d) => d ? const Color(0xFF112236) : Colors.white;
Color _border(bool d) =>
    d ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
Color _text(bool d) => d ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);
Color _muted(bool d) => d ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);

enum TripStatus { inProgress, scheduled, completed }

enum FilterType { all, upcoming, completed }

// ── My Trips model ──
class TripModel {
  final String id, date, from, to;
  final int miles;
  final TripStatus status;
  final double earnings;
  final double? weight;
  const TripModel({
    required this.id,
    required this.date,
    required this.from,
    required this.to,
    required this.miles,
    required this.status,
    this.earnings = 0,
    this.weight,
  });
}

// ══════════════════════════════════════════════════════════════
//  TRIPS SCREEN
// ══════════════════════════════════════════════════════════════
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin {
  int _mainTab = 0;
  FilterType _filter = FilterType.all;

  // ── My Trips state ──
  List<TripModel> _myTrips = [];
  bool _myTripsLoading = false;
  String? _myTripsError;

  late AnimationController _pageCtrl;
  late AnimationController _tabCtrl;
  late List<Animation<double>> _itemAnims;

  final DriverService _service = DriverService();

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _itemAnims = List.generate(8, (i) {
      final s = (i * 0.09).clamp(0.0, 0.8);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _pageCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    // Load available trips on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadAvailableTrips();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchMainTab(int i) {
    if (i == _mainTab) return;
    _tabCtrl.forward(from: 0);
    setState(() => _mainTab = i);
    if (i == 1) _loadMyTrips();
  }

  // ── GET /api/driver/trips/my-trips ──
  Future<void> _loadMyTrips({String status = 'all'}) async {
    setState(() {
      _myTripsLoading = true;
      _myTripsError = null;
    });
    try {
      final res = await _service.getMyTrips(status: status);
      if (res['success'] == true) {
        final data = res['data'];
        final list = (data['trips'] ?? data['data'] ?? []) as List;
        setState(() {
          _myTrips = list.map((t) {
            final statusStr = (t['status'] ?? '').toString().toLowerCase();
            TripStatus tripStatus;
            if (statusStr == 'active' || statusStr == 'inprogress') {
              tripStatus = TripStatus.inProgress;
            } else if (statusStr == 'scheduled' || statusStr == 'pending') {
              tripStatus = TripStatus.scheduled;
            } else {
              tripStatus = TripStatus.completed;
            }
            return TripModel(
              id: t['tripId'] ?? t['id'] ?? '',
              date: t['earnedAtFormatted'] ?? t['date'] ?? '',
              from: t['pickupLocation'] ?? '',
              to: t['dropoffLocation'] ?? '',
              miles: (t['distance'] as num?)?.toInt() ?? 0,
              status: tripStatus,
              earnings: (t['amountEGP'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        });
      } else {
        setState(
            () => _myTripsError = res['message'] ?? 'Failed to load trips');
      }
    } catch (e) {
      setState(() => _myTripsError = e.toString());
    } finally {
      setState(() => _myTripsLoading = false);
    }
  }

  List<TripModel> get _filteredTrips {
    switch (_filter) {
      case FilterType.upcoming:
        return _myTrips.where((t) => t.status == TripStatus.scheduled).toList();
      case FilterType.completed:
        return _myTrips.where((t) => t.status == TripStatus.completed).toList();
      case FilterType.all:
        return _myTrips;
    }
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
      builder: (_) => FilterSheet(
        current: _filter,
        onSelect: (f) {
          setState(() => _filter = f);
          Navigator.pop(context);
          // reload with filter
          final statusMap = {
            FilterType.all: 'all',
            FilterType.upcoming: 'active',
            FilterType.completed: 'completed',
          };
          _loadMyTrips(status: statusMap[f] ?? 'all');
        },
      ),
    );
  }

  Widget _animItem(int idx, Widget child) {
    final anim = _itemAnims[idx.clamp(0, _itemAnims.length - 1)];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(
          child: Column(children: [
        // ── Header ──
        _animItem(
            0,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Trips',
                      style: TextStyle(
                          color: _text(d),
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  Text('Manage your requests and active trips',
                      style: TextStyle(color: _muted(d), fontSize: 12.5)),
                ]),
                const Spacer(),
                if (_mainTab == 1)
                  _FilterButton(
                      active: _filter != FilterType.all,
                      onTap: _openFilter,
                      isDark: d),
              ]),
            )),

        // ── Main Tab Toggle ──
        _animItem(
            1,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _card(d),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border(d)),
                ),
                child: Row(children: [
                  _tabPill('Available Requests', 0, d),
                  _tabPill('My Trips', 1, d),
                ]),
              ),
            )),

        // ── Active filter tag ──
        if (_filter != FilterType.all)
          _animItem(
              1,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _FilterTag(
                    label: _filter == FilterType.upcoming
                        ? 'Upcoming'
                        : 'Completed',
                    onRemove: () {
                      setState(() => _filter = FilterType.all);
                      _loadMyTrips();
                    },
                  ),
                ),
              )),

        const SizedBox(height: 16),

        // ── Tab 0: Available Requests ──
        if (_mainTab == 0) Expanded(child: _AvailableRequestsList(isDark: d)),

        // ── Tab 1: My Trips ──
        if (_mainTab == 1)
          Expanded(
            child: AnimatedBuilder(
              animation: _tabCtrl,
              builder: (_, child) => Opacity(
                opacity: _tabCtrl.value,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _tabCtrl.value)), child: child),
              ),
              child: _myTripsLoading
                  ? _loadingState(d)
                  : _myTripsError != null
                      ? _errorState(d)
                      : _MyTripsList(
                          d: d, trips: _filteredTrips, itemAnims: _itemAnims),
            ),
          ),
      ])),
    );
  }

  Widget _loadingState(bool d) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _kTeal, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Loading trips...',
              style: TextStyle(color: _muted(d), fontSize: 14)),
        ],
      ));

  Widget _errorState(bool d) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            MyTripsCard(
              trip: const TripModel(
                id: 'TRP001',
                date: '2026-06-20',
                from: 'Assuit',
                to: 'Luxor',
                miles: 210,
                weight: 210,
                status: TripStatus.inProgress,
                earnings: 200,
              ),
              isDark: d,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: MyTripsCard(
                trip: const TripModel(
                  id: 'TRP001',
                  date: '2026-06-20',
                  from: 'cairo',
                  to: 'Alex',
                  miles: 210,
                  weight: 210,
                  status: TripStatus.inProgress,
                  earnings: 100,
                ),
                isDark: d,
              ),
            ),
            MyTripsCard(
              trip: const TripModel(
                id: 'TRP001',
                date: '2026-06-20',
                from: 'Mansura',
                to: 'BorSaid',
                miles: 210,
                weight: 210,
                status: TripStatus.inProgress,
                earnings: 90,
              ),
              isDark: d,
            )
          ],
        ),
      );

  Widget _tabPill(String label, int idx, bool d) {
    return Expanded(
        child: GestureDetector(
      onTap: () => _switchMainTab(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _mainTab == idx
              ? const LinearGradient(
                  colors: [Color(0xFF009689), Color(0xFF00D5BE)])
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _mainTab == idx
              ? [BoxShadow(color: _kTeal.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              color: _mainTab == idx ? Colors.white : _muted(d),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ),
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  AVAILABLE REQUESTS LIST — من الـ DriverProvider
// ══════════════════════════════════════════════════════════════
class _AvailableRequestsList extends StatefulWidget {
  final bool isDark;
  const _AvailableRequestsList({required this.isDark});
  @override
  State<_AvailableRequestsList> createState() => _AvailableRequestsListState();
}

class _AvailableRequestsListState extends State<_AvailableRequestsList>
    with SingleTickerProviderStateMixin {
  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  // ── بيحول AvailableTrip → TripData للـ screens الموجودة ──
  TripData _toTripData(AvailableTrip t) => TripData(
        id: t.id,
        pickup: t.origin,
        dropoff: t.destination,
        distance: t.distance,
        estTime: t.estimatedTime,
        cargoType: t.goodsType,
        trader: t.traderName,
        price: t.price,
        weightLbs: (t.weightTons * 2204.62).toInt(),
        postedAgo: t.scheduledDate,
      );

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final trips = driver.availableTrips;
    final isLoading = driver.isLoading;

    if (isLoading && trips.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _kTeal, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Finding available trips...',
              style: TextStyle(color: _muted(widget.isDark), fontSize: 14)),
        ],
      ));
    }

    if (trips.isEmpty) return _emptyState();

    return RefreshIndicator(
      color: _kTeal,
      onRefresh: () => context.read<DriverProvider>().loadAvailableTrips(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) => AnimatedBuilder(
          animation: _listCtrl,
          builder: (_, child) {
            final delay = i * 0.12;
            final t = ((_listCtrl.value - delay) / 0.4).clamp(0.0, 1.0);
            final curve = Curves.easeOutCubic.transform(t);
            return Opacity(
              opacity: curve,
              child: Transform.translate(
                  offset: Offset(0, 20 * (1 - curve)), child: child),
            );
          },
          child: _RequestCard(
            trip: _toTripData(trips[i]),
            isDark: widget.isDark,
            onViewDetails: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      RequestDetailsScreen(trip: _toTripData(trips[i])),
                )),
            onAccept: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      TripAvailableScreen(trip: _toTripData(trips[i])),
                )),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _animEmptyItem(
            0,
            MyTripCard(
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RequestAcceptedScreen(
                            trip: const TripData(
                              id: 'REQ-1001',
                              pickup: 'Dallas Warehouse',
                              pickupAddr: '123 Commerce St, Dallas, TX',
                              dropoff: 'Houston Distribution Center',
                              dropoffAddr: '456 Market Ave, Houston, TX',
                              distance: '385 km',
                              estTime: '4h 30m',
                              cargoType: 'Electronics',
                              trader: 'Tech Logistics Inc.',
                              traderPhone: '+1 214-555-1234',
                              price: 850.00,
                              weightLbs: 12000,
                              packages: 45,
                              postedAgo: '2 hours ago',
                              specialNotes: 'Handle with care. Fragile cargo.',
                            ),
                          )),
                );
              },
              trip: const TripModel(
                id: 'TRP001',
                date: '2026-06-25',
                from: 'Fayum',
                to: 'Cairo',
                miles: 65,
                weight: 500,
                status: TripStatus.inProgress,
                earnings: 150,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _animEmptyItem(
            1,
            MyTripCard(
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PickupScreen(
                            tripId: "2",
                          )),
                );
              },
              trip: const TripModel(
                id: 'TRP001',
                date: '2026-06-20',
                from: 'Assuit',
                to: 'Luxor',
                weight: 210,
                miles: 210,
                status: TripStatus.inProgress,
                earnings: 200,
              ),
            ),
          ),
        ],
      );

  Widget _animEmptyItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _listCtrl,
      builder: (_, child) {
        final delay = index * 0.12;
        final t = ((_listCtrl.value - delay) / 0.4).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  REQUEST CARD
// ══════════════════════════════════════════════════════════════
class _RequestCard extends StatefulWidget {
  final TripData trip;
  final bool isDark;
  final VoidCallback onViewDetails;
  final VoidCallback onAccept;

  const _RequestCard({
    required this.trip,
    required this.isDark,
    required this.onViewDetails,
    required this.onAccept,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final d = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: Container(
          decoration: BoxDecoration(
            color: _card(d),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border(d)),
            boxShadow: d
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Price Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: _kAmber,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Offered Price',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.7), fontSize: 13)),
                  Row(children: [
                    Text('${t.price.toInt()}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const Text(' EGP',
                        style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ]),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Timeline
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                    color: _kTeal, shape: BoxShape.circle)),
                            Container(
                                width: 2,
                                height: 40,
                                color: _kTeal.withOpacity(0.3)),
                            const Icon(Icons.location_on_rounded,
                                color: _kAmber, size: 14),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Pickup',
                                    style: TextStyle(
                                        color: _muted(d), fontSize: 11)),
                                Text(t.pickup,
                                    style: TextStyle(
                                        color: _text(d),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Text('Drop-off',
                                    style: TextStyle(
                                        color: _muted(d), fontSize: 11)),
                                Text(t.dropoff,
                                    style: TextStyle(
                                        color: _text(d),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ])),
                        ]),
                    const SizedBox(height: 12),

                    // Info Chips
                    Row(children: [
                      _chip(Icons.location_on_outlined, 'Distance', t.distance,
                          d),
                      const SizedBox(width: 8),
                      _chip(Icons.access_time_rounded, 'Time', t.estTime, d),
                      const SizedBox(width: 8),
                      _chip(Icons.scale_outlined, 'Weight',
                          '${t.weightLbs} lbs', d),
                    ]),
                    const SizedBox(height: 12),

                    // Cargo & Posted
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cargo',
                                  style: TextStyle(
                                      color: _muted(d), fontSize: 11)),
                              Text(t.cargoType,
                                  style: TextStyle(
                                      color: _text(d),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ]),
                        Text(t.postedAgo,
                            style:
                                const TextStyle(color: _kAmber, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                        onPressed: widget.onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _kTeal.withOpacity(0.5)),
                          foregroundColor: _kTeal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('View Details',
                            style: TextStyle(
                                color: _kTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _AcceptButton(onTap: widget.onAccept)),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value, bool d) => Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF112236) : const Color(0xFFEEF5FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border(d)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _kTeal, size: 12),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(color: _muted(d), fontSize: 10)),
          ]),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: _text(d), fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ));
}

// ── Accept Button with shimmer ──
class _AcceptButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AcceptButton({required this.onTap});

  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimX;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimX = Tween<double>(begin: -300, end: 300)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF009689), Color(0xFF00D5BE)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: _kTeal.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: _shimX,
            builder: (_, __) => Transform.translate(
              offset: Offset(_shimX.value, 0),
              child: Container(
                width: 80,
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
          const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Accept',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MY TRIPS LIST
// ══════════════════════════════════════════════════════════════
class _MyTripsList extends StatelessWidget {
  final bool d;
  final List<TripModel> trips;
  final List<Animation<double>> itemAnims;

  const _MyTripsList(
      {required this.d, required this.trips, required this.itemAnims});

  Widget _anim(int idx, Widget child) {
    final anim = itemAnims[idx.clamp(0, itemAnims.length - 1)];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, color: _muted(d), size: 56),
          const SizedBox(height: 16),
          Text('No trips found',
              style: TextStyle(
                  color: _text(d), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Accepted trips will appear here',
              style: TextStyle(color: _muted(d), fontSize: 14)),
        ],
      ));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _anim(2 + i, MyTripsCard(trip: trips[i], isDark: d)),
    );
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final TripStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case TripStatus.inProgress:
        color = const Color(0xFF00D4E0);
        label = 'In Progress';
        break;
      case TripStatus.scheduled:
        color = const Color(0xFFFF8904);
        label = 'Scheduled';
        break;
      case TripStatus.completed:
        color = _kTeal;
        label = 'Delivered';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FILTER BUTTON
// ══════════════════════════════════════════════════════════════
class _FilterButton extends StatefulWidget {
  final bool active, isDark;
  final VoidCallback onTap;
  const _FilterButton(
      {required this.active, required this.onTap, required this.isDark});
  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: widget.active
                ? _kTeal.withOpacity(widget.isDark ? 0.3 : 0.15)
                : _card(widget.isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? _kTeal.withOpacity(0.4)
                  : _border(widget.isDark),
            ),
          ),
          child: const Icon(Icons.filter_alt_outlined, color: _kTeal, size: 20),
        ),
      ),
    );
  }
}

// ── Filter Tag ──
class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
        decoration: BoxDecoration(
          color: _kTeal.withOpacity(0.12),
          border: Border.all(color: _kTeal.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: const TextStyle(
                  color: _kTeal, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.close, color: _kTeal, size: 10),
            ),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class FilterSheet extends StatelessWidget {
  final FilterType current;
  final ValueChanged<FilterType> onSelect;
  const FilterSheet({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final sheetBg = isDark ? const Color(0xFF0D1E2E) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);
    final handleColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.10);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: handleColor, borderRadius: BorderRadius.circular(3)),
        ),
        Row(children: [
          Text('Filter Trips',
              style: TextStyle(
                  color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A3550) : const Color(0xFFF0F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: textColor, size: 14),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        _FilterOption(
            label: 'All Trips',
            selected: current == FilterType.all,
            onTap: () => onSelect(FilterType.all),
            isDark: isDark),
        const SizedBox(height: 10),
        _FilterOption(
            label: 'Upcoming',
            selected: current == FilterType.upcoming,
            onTap: () => onSelect(FilterType.upcoming),
            isDark: isDark),
        const SizedBox(height: 10),
        _FilterOption(
            label: 'Completed',
            selected: current == FilterType.completed,
            onTap: () => onSelect(FilterType.completed),
            isDark: isDark),
      ]),
    );
  }
}

// ── Filter Option ──
class _FilterOption extends StatefulWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  @override
  State<_FilterOption> createState() => _FilterOptionState();
}

class _FilterOptionState extends State<_FilterOption>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _checkScale =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutBack);
    if (widget.selected) _checkCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FilterOption old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _checkCtrl.forward();
    if (!widget.selected && old.selected) _checkCtrl.reverse();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselBg =
        widget.isDark ? const Color(0xFF112236) : const Color(0xFFF5F8FA);
    final textColor =
        widget.isDark ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: widget.selected
                ? _kTeal.withOpacity(widget.isDark ? 0.3 : 0.12)
                : unselBg,
            border: Border.all(
              color: widget.selected ? _kTeal : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(widget.label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500)),
            const Spacer(),
            ScaleTransition(
              scale: _checkScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected ? _kTeal : Colors.transparent,
                  border: Border.all(
                    color: widget.selected
                        ? _kTeal
                        : (widget.isDark
                            ? Colors.white.withOpacity(0.25)
                            : Colors.black.withOpacity(0.2)),
                    width: 2,
                  ),
                ),
                child: widget.selected
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
