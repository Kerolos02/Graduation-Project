import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';
import '/screen/trader/trader_driver_screens.dart';

// ══════════════════════════════════════════════════════════════════════════
//  TRADER MY SHIPMENTS SCREEN
//  GET /api/trader/shipments
//  ✅ Filter tabs: All | Pending | In Transit | Delivered | Cancelled
// ══════════════════════════════════════════════════════════════════════════

class _ShipmentItem {
  final String id, date, from, to, driver, status;
  final double price;
  final int statusColor;
  const _ShipmentItem({
    required this.id, required this.date, required this.from, required this.to,
    required this.driver, required this.price,
    required this.status, required this.statusColor,
  });

  // ✅ تحويل من رد السيرفر — fallbacks لأكتر من اسم محتمل لكل حقل
  // (محتاج تأكيد بالـ console logs الفعلية لـ /api/trader/shipments)
  factory _ShipmentItem.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ??
        json['totalCost'] ??
        json['cost'] ??
        json['finalCost'] ??
        0;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    final rawStatus = (json['status'] ?? 'pending').toString().toLowerCase();
    String status;
    int statusColor;
    if (rawStatus.contains('transit')) {
      status = 'In Transit';
      statusColor = 0xFF3B82F6;
    } else if (rawStatus.contains('deliver')) {
      status = 'Delivered';
      statusColor = 0xFF00D5BE;
    } else if (rawStatus.contains('cancel')) {
      status = 'Cancelled';
      statusColor = 0xFFEF4444;
    } else {
      status = 'Pending';
      statusColor = 0xFFFFB800;
    }

    final driverObj = json['driver'];
    final driverName = json['driverName'] ??
        json['assignedDriverName'] ??
        (driverObj is Map ? driverObj['fullName'] ?? driverObj['name'] : null) ??
        'Not assigned';

    final rawDate = json['date'] ??
        json['scheduledDate'] ??
        json['createdAt'] ??
        json['pickupDate'];

    // ✅ shipmentId بيرجع فاضي "" من الباك إند حالياً، فبنستخدم
    // الـ id الرقمي بدالاً منه — هو ده اللي بيتبعت لكل endpoints التانية
    final numericId = json['id']?.toString() ?? '';
    final apiShipmentId = (json['shipmentId']?.toString().isNotEmpty == true)
        ? json['shipmentId'].toString()
        : numericId;

    return _ShipmentItem(
      id: apiShipmentId.isNotEmpty ? apiShipmentId : numericId,
      date: _formatDate(rawDate?.toString()),
      from: (json['originCity'] ?? json['origin'] ?? json['pickupLocation'] ?? json['from'] ?? '—').toString(),
      to: (json['destinationCity'] ?? json['destination'] ?? json['dropoffLocation'] ?? json['to'] ?? '—').toString(),
      driver: driverName.toString(),
      price: price,
      status: status,
      statusColor: statusColor,
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm   = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour12:$minute $ampm';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Filter tabs ──────────────────────────────────────────────────────────
const _kFilters = ['All', 'Pending', 'In Transit', 'Delivered', 'Cancelled'];

class TraderMyShipmentsScreen extends StatefulWidget {
  const TraderMyShipmentsScreen({super.key});

  @override
  State<TraderMyShipmentsScreen> createState() => _TraderMyShipmentsScreenState();
}

class _TraderMyShipmentsScreenState extends State<TraderMyShipmentsScreen>
    with TickerProviderStateMixin {

  int _filterIndex = 0; // 0 = All

  bool _isLoading = true;
  List<_ShipmentItem> _shipments = [];

  late final AnimationController _headerCtrl;
  late final AnimationController _filterCtrl;
  late final AnimationController _blobCtrl;
  late final AnimationController _listCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double> _filterFade;
  late final Animation<Offset>  _filterSlide;
  late final Animation<double> _blobX, _blobY;
  late final Animation<double> _listFade;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _filterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _filterFade  = CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOut);
    _filterSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOut));

    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _listFade = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);

    _blobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))
      ..repeat(reverse: true);
    _blobX = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));

    _runSequence();

    // ✅ تحميل الشحنات من الباك إند
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShipments());
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _filterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _listCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _filterCtrl.dispose();
    _listCtrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  LOAD SHIPMENTS FROM BACKEND
  //  GET /api/trader/shipments
  // ══════════════════════════════════════
  Future<void> _loadShipments() async {
    setState(() => _isLoading = true);

    final provider = context.read<TraderProvider>();
    await provider.loadShipments();

    if (!mounted) return;

    final raw = provider.shipments;
    setState(() {
      _shipments = raw
          .whereType<Map>()
          .map((e) => _ShipmentItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    });

    if (provider.error != null && _shipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error!),
        backgroundColor: const Color(0xFFFF476D),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── فلتر الشحنات حسب الـ tab (client-side) ──
  List<_ShipmentItem> get _filtered {
    if (_filterIndex == 0) return _shipments;
    final label = _kFilters[_filterIndex];
    return _shipments.where((s) => s.status == label).toList();
  }

  // ── عدد كل فئة ──
  int _count(String filter) {
    if (filter == 'All') return _shipments.length;
    return _shipments.where((s) => s.status == filter).length;
  }

  // ── إجمالي الصرف على الشحنات المُسلَّمة ──
  double get _totalSpent => _shipments
      .where((s) => s.status == 'Delivered')
      .fold<double>(0, (sum, s) => sum + s.price);

  void _switchFilter(int i) {
    if (i == _filterIndex) return;
    _listCtrl.reverse().then((_) {
      setState(() => _filterIndex = i);
      _listCtrl.forward();
    });
  }

  void _openDetails(_ShipmentItem s) {
    String statusKey;
    switch (s.status.toLowerCase()) {
      case 'in transit':  statusKey = 'inTransit';  break;
      case 'delivered':   statusKey = 'delivered';   break;
      case 'cancelled':   statusKey = 'cancelled';   break;
      default:            statusKey = 'pending';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShipmentDetailsScreen(
          shipmentId: s.id,
          pickup:     s.from,
          dropoff:    s.to,
          date:       s.date,
          time:       '12:00 PM',
          packages:   '1',
          weight:     '${(s.price / 20).round()} lbs',
          status:     statusKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF8F9FA);
    final kCard   = isDark ? const Color(0xFF112236) : Colors.white;
    final kText   = isDark ? Colors.white             : const Color(0xFF1A1A1A);
    final kMuted  = isDark ? const Color(0xFF5F7E97)  : const Color(0xFF6B7280);
    final kBorder = isDark ? const Color(0xFF1A3550)  : const Color(0xFFE0F7FA);
    final kAccent = isDark ? const Color(0xFF00A3C4)  : const Color(0xFF00A3C4);
    const kTeal   = Color(0xFF00D5BE);

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [

        // ── Background blobs ──
        AnimatedBuilder(
          animation: _blobCtrl,
          builder: (_, __) => Stack(children: [
            Positioned(
              top: 80 + _blobY.value, right: 10 + _blobX.value,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kTeal.withOpacity(0.03)))),
            Positioned(
              bottom: 80 - _blobY.value * 0.5, left: 20,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccent.withOpacity(0.03)))),
          ]),
        ),

        SafeArea(child: Column(children: [

          // ── Header ──
          SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  _TapScaleButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder)),
                      child: Icon(Icons.chevron_left,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          size: 24)),
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('My Shipments',
                        style: TextStyle(
                            color: kText, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('${_shipments.length} total shipments',
                        style: TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                ]),
              ),
            ),
          ),

          // ── Stat cards ──
          FadeTransition(
            opacity: _filterFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total', value: '${_shipments.length}',
                    isDark: isDark, kCard: kCard, kBorder: kBorder,
                    kMuted: kMuted, kText: kText, kTeal: kTeal)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                    icon: Icons.attach_money,
                    label: 'Total Spent',
                    value: '\$${(_totalSpent / 1000).toStringAsFixed(1)}K',
                    isDark: isDark, kCard: kCard, kBorder: kBorder,
                    kMuted: kMuted, kText: kAccent, kTeal: kTeal)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Filter Tabs ──────────────────────────────────────────────
          FadeTransition(
            opacity: _filterFade,
            child: SlideTransition(
              position: _filterSlide,
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _kFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final label  = _kFilters[i];
                    final active = _filterIndex == i;
                    final count  = _count(label);

                    // لون كل فئة
                    Color tabColor;
                    switch (label) {
                      case 'Pending':    tabColor = const Color(0xFFFFB800); break;
                      case 'In Transit': tabColor = const Color(0xFF3B82F6); break;
                      case 'Delivered':  tabColor = kTeal;                   break;
                      case 'Cancelled':  tabColor = const Color(0xFFEF4444); break;
                      default:           tabColor = kTeal;
                    }

                    return _TapScaleButton(
                      onTap: () => _switchFilter(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? tabColor : kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? tabColor : kBorder,
                            width: active ? 1.5 : 1.0,
                          ),
                          boxShadow: active ? [
                            BoxShadow(
                              color: tabColor.withOpacity(0.3),
                              blurRadius: 8, offset: const Offset(0, 3))
                          ] : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(label,
                              style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : kMuted,
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                          const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withOpacity(0.25)
                                  : kBorder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$count',
                                style: TextStyle(
                                    color: active ? Colors.white : kMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Shipment List ──
          Expanded(
            child: FadeTransition(
              opacity: _listFade,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kTeal))
                  : filtered.isEmpty
                      ? _EmptyState(
                          filter: _kFilters[_filterIndex],
                          isDark: isDark,
                          kText: kText,
                          kMuted: kMuted,
                        )
                      : RefreshIndicator(
                          color: kTeal,
                          onRefresh: _loadShipments,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              return _TapScaleButton(
                                onTap: () => _openDetails(item),
                                child: _ShipCard(
                                    item: item, isDark: isDark,
                                    kCard: kCard, kText: kText,
                                    kMuted: kMuted, kBorder: kBorder),
                              );
                            },
                          ),
                        ),
            ),
          ),

        ])),
      ]),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final bool isDark;
  final Color kText, kMuted;
  const _EmptyState({
    required this.filter, required this.isDark,
    required this.kText, required this.kMuted,
  });

  IconData get _icon {
    switch (filter) {
      case 'Pending':    return Icons.hourglass_empty_rounded;
      case 'In Transit': return Icons.local_shipping_outlined;
      case 'Delivered':  return Icons.check_circle_outline_rounded;
      case 'Cancelled':  return Icons.cancel_outlined;
      default:           return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00D5BE).withOpacity(0.1)),
        child: Icon(_icon, color: const Color(0xFF00D5BE), size: 38)),
      const SizedBox(height: 20),
      Text(filter == 'All' ? 'No Shipments Yet' : 'No $filter Shipments',
          style: TextStyle(
              color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('No shipments in this category yet',
          style: TextStyle(color: kMuted, fontSize: 14)),
    ]),
  );
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  final Color kCard, kBorder, kMuted, kText, kTeal;
  const _StatCard({
    required this.icon, required this.label, required this.value,
    required this.isDark, required this.kCard, required this.kBorder,
    required this.kMuted, required this.kText, required this.kTeal,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(
            color: const Color(0xFF00D5BE).withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: kTeal.withOpacity(isDark ? 0.15 : 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kTeal, size: 20)),
      const SizedBox(height: 12),
      Text(label, style: TextStyle(color: kMuted, fontSize: 13)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          color: kText, fontSize: 26, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ── Ship Card ──────────────────────────────────────────────────────────────
class _ShipCard extends StatelessWidget {
  final _ShipmentItem item;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder;
  const _ShipCard({
    required this.item, required this.isDark,
    required this.kCard, required this.kText,
    required this.kMuted, required this.kBorder,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 1.5),
          boxShadow: isDark ? [] : [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(item.date, style: TextStyle(color: kMuted, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(item.status, style: TextStyle(
                color: statusColor, fontSize: 12,
                fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF00A3C4), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(item.from, overflow: TextOverflow.ellipsis, style: TextStyle(
              color: kText, fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: kMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(item.to, overflow: TextOverflow.ellipsis, style: TextStyle(
              color: kText, fontSize: 16, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Driver: ${item.driver}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: kMuted, fontSize: 13))),
          Text('\$${item.price.toStringAsFixed(0)}', style: const TextStyle(
              color: Color(0xFF00A3C4), fontSize: 18,
              fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// ── Tap Scale Button ───────────────────────────────────────────────────────
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: ()  => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}