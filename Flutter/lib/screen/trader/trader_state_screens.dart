import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';
import '/screen/trader/trader_new_shipment_screen.dart';
import '/screen/trader/trader_driver_screens.dart';
import '/screen/trader/payment_screens.dart';

// ══════════════════════════════════════════════════════
//  FILE: lib/screen/trader/trader_state_screens.dart
//
//  يحتوي على:
//  1. ShipmentsStateScreen   — loading / empty / error  ✅ مربوط بالـ API
//  2. NotificationsStateScreen — loading / empty / error  ✅ مربوط بالـ API
//  3. OffersStateScreen       — loading / empty / error  ✅ مربوط بالـ API
//  4. PaymentStateScreen      — processing / success / failed  ✅ مربوط بالـ API
// ══════════════════════════════════════════════════════

// ── Shared colors ──
const Color _kTeal = Color(0xFF00D5BE);
const Color _kRed  = Color(0xFFEF4444);

const _kGrad = LinearGradient(
  colors: [Color(0xFF009689), Color(0xFF00B8DB)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── Theme helpers ──
Color _bg(bool d)     => d ? const Color(0xFF0D1B2A) : const Color(0xFFF9FAFB);
Color _text(bool d)   => d ? Colors.white : const Color(0xFF1A1A1A);
Color _sub(bool d)    => d ? Colors.white70 : Colors.black54;
Color _skBg(bool d)   => d ? const Color(0xFF1B263B) : Colors.white;
Color _skLine(bool d) => d ? Colors.white10 : Colors.black12;

// ── Glow Icon ──
Widget _glowIcon(IconData icon, Color color, bool isDark) => Container(
  width: 110, height: 110,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: isDark ? color.withOpacity(0.08) : Colors.white,
    boxShadow: [BoxShadow(
        color: color.withOpacity(0.15),
        blurRadius: 40, spreadRadius: 8)],
  ),
  child: Icon(icon, size: 65, color: color),
);

// ── Gradient Button ──
Widget _gradBtn(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: 260, height: 55,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: _kGrad,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(
          color: _kTeal.withOpacity(0.3),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Text(label, style: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
  ),
);

// ── Outline Button ──
Widget _outlineBtn(String label, Color textColor, VoidCallback onTap,
    bool isDark) =>
  GestureDetector(
    onTap: onTap,
    child: Container(
      width: 260, height: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? const Color(0xFF1B263B) : Colors.black12,
            width: 1.5),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
    ),
  );

// ══════════════════════════════════════════════════════
//  1. SHIPMENTS STATE SCREEN  ✅ مربوط بـ TraderProvider
// ══════════════════════════════════════════════════════
enum _ShipState { loading, empty, error }

class ShipmentsStateScreen extends StatefulWidget {
  /// لو عايزة تفلتر على status معين (مثلاً 'active') مريه هنا
  final String? statusFilter;
  const ShipmentsStateScreen({super.key, this.statusFilter});

  @override
  State<ShipmentsStateScreen> createState() => _ShipmentsStateScreenState();
}

class _ShipmentsStateScreenState extends State<ShipmentsStateScreen> {
  _ShipState _state = _ShipState.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _ShipState.loading);

    try {
      // ✅ بتجيب الشحنات من الباك عن طريق TraderProvider
      await context.read<TraderProvider>().loadShipments(
        status: widget.statusFilter,
      );

      if (!mounted) return;

      final provider = context.read<TraderProvider>();

      if (provider.error != null) {
        setState(() => _state = _ShipState.error);
      } else if (provider.shipments.isEmpty) {
        setState(() => _state = _ShipState.empty);
      } else {
        // في شحنات → الـ parent screen هو اللي هيعرضها
        // هنا بس بنعدي الـ state لـ empty أو error
        setState(() => _state = _ShipState.empty);
      }
    } catch (_) {
      if (mounted) setState(() => _state = _ShipState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _build(d),
      ),
    );
  }

  Widget _build(bool d) {
    switch (_state) {
      case _ShipState.loading: return _loading(d);
      case _ShipState.empty:   return _empty(d);
      case _ShipState.error:   return _error(d);
    }
  }

  Widget _loading(bool d) => Column(
    key: const ValueKey('sl'),
    children: [
      const SizedBox(height: 20),
      _skCard(120, 250, d),
      _skCard(100, 200, d),
    ],
  );

  Widget _skCard(double tw, double bw, bool d) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _skBg(d).withOpacity(d ? 0.4 : 1),
      borderRadius: BorderRadius.circular(15),
      boxShadow: d ? [] : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: tw, height: 12,
          decoration: BoxDecoration(color: _skLine(d),
              borderRadius: BorderRadius.circular(5))),
      const SizedBox(height: 15),
      Container(width: bw, height: 10,
          decoration: BoxDecoration(color: _skLine(d),
              borderRadius: BorderRadius.circular(5))),
      const SizedBox(height: 20),
      Container(width: double.infinity, height: 40,
          decoration: BoxDecoration(color: _skLine(d),
              borderRadius: BorderRadius.circular(10))),
    ]),
  );

  Widget _empty(bool d) => Center(
    key: const ValueKey('se'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _glowIcon(Icons.inventory_2_outlined, _kTeal, d),
      const SizedBox(height: 40),
      Text('No shipments yet', textAlign: TextAlign.center,
          style: TextStyle(color: _text(d), fontSize: 24,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      Text('Start by creating your first shipment',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub(d), fontSize: 16)),
      const SizedBox(height: 60),
      _gradBtn('Create Shipment', () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => const TraderNewShipmentScreen()))),
    ]),
  );

  Widget _error(bool d) {
    // بنجيب رسالة الـ error من الـ provider لو موجودة
    final errMsg = context.read<TraderProvider>().error
        ?? 'Unable to load your shipments. Please try again.';
    return Center(
      key: const ValueKey('serr'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _glowIcon(Icons.error_outline, _kRed, d),
        const SizedBox(height: 40),
        Text('Something went wrong', textAlign: TextAlign.center,
            style: TextStyle(color: _text(d), fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text(errMsg, textAlign: TextAlign.center,
            style: TextStyle(color: _sub(d), fontSize: 16)),
        const SizedBox(height: 50),
        _gradBtn('Retry', _load),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  2. NOTIFICATIONS STATE SCREEN  ✅ مربوط بـ TraderProvider
// ══════════════════════════════════════════════════════
enum _NotifState { loading, empty, error }

class NotificationsStateScreen extends StatefulWidget {
  const NotificationsStateScreen({super.key});
  @override
  State<NotificationsStateScreen> createState() =>
      _NotificationsStateScreenState();
}

class _NotificationsStateScreenState
    extends State<NotificationsStateScreen> {
  _NotifState _state = _NotifState.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _NotifState.loading);

    try {
      // ✅ بتجيب إعدادات الـ notifications من الباك
      // GET /api/trader/settings/notifications
      await context.read<TraderProvider>().loadNotificationSettings();

      if (!mounted) return;

      final provider = context.read<TraderProvider>();

      if (provider.error != null) {
        setState(() => _state = _NotifState.error);
      } else if (provider.notificationSettings == null ||
          provider.notificationSettings!.isEmpty) {
        setState(() => _state = _NotifState.empty);
      } else {
        setState(() => _state = _NotifState.empty);
      }
    } catch (_) {
      if (mounted) setState(() => _state = _NotifState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _build(d),
      ),
    );
  }

  Widget _build(bool d) {
    switch (_state) {
      case _NotifState.loading: return _loading(d);
      case _NotifState.empty:   return _empty(d);
      case _NotifState.error:   return _error(d);
    }
  }

  Widget _loading(bool d) => ListView.builder(
    key: const ValueKey('nl'),
    padding: const EdgeInsets.all(20),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: d
            ? const Color(0xFF1B263B).withOpacity(0.4)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 150, height: 10,
                decoration: BoxDecoration(color: _skLine(d),
                    borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 15),
            Container(width: 90, height: 10,
                decoration: BoxDecoration(color: _skLine(d),
                    borderRadius: BorderRadius.circular(5))),
          ],
        ),
      ),
    ),
  );

  Widget _empty(bool d) => Center(
    key: const ValueKey('ne'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _glowIcon(Icons.notifications_none_rounded, _kTeal, d),
      const SizedBox(height: 30),
      Text('No notifications yet', textAlign: TextAlign.center,
          style: TextStyle(color: _text(d), fontSize: 20,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text("You're all caught up! Check back later.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub(d), fontSize: 15)),
    ]),
  );

  Widget _error(bool d) {
    final errMsg = context.read<TraderProvider>().error
        ?? 'Failed to fetch notifications. Please try again.';
    return Center(
      key: const ValueKey('nerr'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _glowIcon(Icons.priority_high_rounded, _kRed, d),
        const SizedBox(height: 30),
        Text('Unable to load notifications', textAlign: TextAlign.center,
            style: TextStyle(color: _text(d), fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(errMsg, textAlign: TextAlign.center,
            style: TextStyle(color: _sub(d), fontSize: 15)),
        const SizedBox(height: 40),
        _gradBtn('Retry', _load),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  3. OFFERS STATE SCREEN  ✅ مربوط بـ TraderProvider
// ══════════════════════════════════════════════════════
enum _OffersState { loading, empty, error }

class OffersStateScreen extends StatefulWidget {
  /// shipmentId مطلوب عشان نجيب الـ offers بتاعت الشحنة دي
  /// GET /api/trader/mobile/shipments/{shipmentId}/offers
  final String shipmentId;
  final String tab; // 'pending' أو 'accepted' أو 'rejected'

  const OffersStateScreen({
    super.key,
    required this.shipmentId,
    this.tab = 'pending',
  });

  @override
  State<OffersStateScreen> createState() => _OffersStateScreenState();
}

class _OffersStateScreenState extends State<OffersStateScreen> {
  _OffersState _state = _OffersState.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _OffersState.loading);

    try {
      // ✅ بتجيب الـ offers من الباك
      await context.read<TraderProvider>().loadOffers(
        shipmentId: widget.shipmentId,
        tab: widget.tab,
      );

      if (!mounted) return;

      final provider = context.read<TraderProvider>();

      if (provider.error != null) {
        setState(() => _state = _OffersState.error);
      } else if (provider.offers.isEmpty) {
        setState(() => _state = _OffersState.empty);
      } else {
        // في offers → الـ parent هيعرضها
        setState(() => _state = _OffersState.empty);
      }
    } catch (_) {
      if (mounted) setState(() => _state = _OffersState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _build(d),
      ),
    );
  }

  Widget _build(bool d) {
    switch (_state) {
      case _OffersState.loading: return _loading(d);
      case _OffersState.empty:   return _empty(d);
      case _OffersState.error:   return _error(d);
    }
  }

  Widget _loading(bool d) => Center(
    key: const ValueKey('ol'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _skOfferCard(d),
      const SizedBox(height: 20),
      _skOfferCard(d),
    ]),
  );

  Widget _skOfferCard(bool d) => Container(
    width: 320, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _skBg(d).withOpacity(d ? 0.5 : 1),
      borderRadius: BorderRadius.circular(15),
      boxShadow: d ? [] : [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 5))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 150, height: 15, color: _skLine(d)),
      const SizedBox(height: 15),
      Container(width: 250, height: 10, color: _skLine(d)),
      const SizedBox(height: 20),
      Row(children: [
        Container(width: 80, height: 35,
            decoration: BoxDecoration(color: _skLine(d),
                borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 15),
        Container(width: 80, height: 35,
            decoration: BoxDecoration(color: _skLine(d),
                borderRadius: BorderRadius.circular(8))),
      ]),
    ]),
  );

  Widget _empty(bool d) => Center(
    key: const ValueKey('oe'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _glowIcon(Icons.local_shipping_outlined, _kTeal, d),
      const SizedBox(height: 40),
      Text('No drivers\navailable yet', textAlign: TextAlign.center,
          style: TextStyle(color: _text(d), fontSize: 24,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      Text('Please wait while we find\ndrivers for your shipment',
          textAlign: TextAlign.center,
          style: TextStyle(color: _sub(d), fontSize: 16)),
    ]),
  );

  Widget _error(bool d) {
    final errMsg = context.read<TraderProvider>().error
        ?? 'Unable to fetch available drivers. Please try again.';
    return Center(
      key: const ValueKey('oerr'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _glowIcon(Icons.error_outline, _kRed, d),
        const SizedBox(height: 40),
        Text('Failed to load\ndrivers', textAlign: TextAlign.center,
            style: TextStyle(color: _text(d), fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text(errMsg, textAlign: TextAlign.center,
            style: TextStyle(color: _sub(d), fontSize: 16)),
        const SizedBox(height: 50),
        _gradBtn('Retry', _load),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  4. PAYMENT STATE SCREEN  ✅ مربوط بـ TraderProvider
// ══════════════════════════════════════════════════════
enum _PayState { processing, success, failed }

class PaymentStateScreen extends StatefulWidget {
  final String driverName;
  final double price;

  /// ✅ دول مطلوبين للـ API
  /// POST /api/trader/invoices/{invoiceId}/pay
  final String invoiceId;
  final String paymentCardId;

  const PaymentStateScreen({
    super.key,
    this.driverName = '',
    this.price = 0,
    required this.invoiceId,
    required this.paymentCardId,
  });

  @override
  State<PaymentStateScreen> createState() => _PaymentStateScreenState();
}

class _PaymentStateScreenState extends State<PaymentStateScreen>
    with SingleTickerProviderStateMixin {
  _PayState _state = _PayState.processing;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _process();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    setState(() => _state = _PayState.processing);

    try {
      // ✅ بتدفع الـ invoice من الباك
      // POST /api/trader/invoices/{invoiceId}/pay
      final success = await context.read<TraderProvider>().payInvoice(
        invoiceId: widget.invoiceId,
        cardId: widget.paymentCardId,
      );

      if (!mounted) return;

      setState(() => _state = success ? _PayState.success : _PayState.failed);
    } catch (_) {
      if (mounted) setState(() => _state = _PayState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: _build(d),
      ),
    );
  }

  Widget _build(bool d) {
    switch (_state) {
      case _PayState.processing: return _processing(d);
      case _PayState.success:    return _success(d);
      case _PayState.failed:     return _failed(d);
    }
  }

  Widget _processing(bool d) => Center(
    key: const ValueKey('pp'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: 75, height: 75,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          color: _kTeal,
          backgroundColor: _kTeal.withOpacity(0.1),
        ),
      ),
      const SizedBox(height: 40),
      Text('Processing\nyour payment...', textAlign: TextAlign.center,
          style: TextStyle(color: _text(d), fontSize: 22,
              fontWeight: FontWeight.bold, height: 1.3)),
      const SizedBox(height: 15),
      Text('Please wait while we process', textAlign: TextAlign.center,
          style: TextStyle(color: _sub(d), fontSize: 14)),
    ]),
  );

  Widget _success(bool d) => Center(
    key: const ValueKey('ps'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: d ? _kTeal.withOpacity(0.08) : Colors.white,
          boxShadow: [BoxShadow(
              color: _kTeal.withOpacity(0.25),
              blurRadius: 40, spreadRadius: 8)],
        ),
        child: const Icon(Icons.check_circle_outline_rounded,
            size: 85, color: _kTeal),
      ),
      const SizedBox(height: 40),
      Text('Payment\nSuccessful', textAlign: TextAlign.center,
          style: TextStyle(color: _text(d), fontSize: 22,
              fontWeight: FontWeight.bold, height: 1.3)),
      const SizedBox(height: 15),
      Text('Your payment has been processed', textAlign: TextAlign.center,
          style: TextStyle(color: _sub(d), fontSize: 14)),
      const SizedBox(height: 55),
      _gradBtn('View Invoice', () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()))),
    ]),
  );

  Widget _failed(bool d) {
    final errMsg = context.read<TraderProvider>().error ?? 'Please try again.';
    return Center(
      key: const ValueKey('pf'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: d ? _kRed.withOpacity(0.08) : Colors.white,
            boxShadow: [BoxShadow(
                color: _kRed.withOpacity(0.25),
                blurRadius: 40, spreadRadius: 8)],
          ),
          child: const Icon(Icons.cancel_outlined, size: 85, color: _kRed),
        ),
        const SizedBox(height: 40),
        Text('Payment failed', textAlign: TextAlign.center,
            style: TextStyle(color: _text(d), fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text(errMsg, textAlign: TextAlign.center,
            style: TextStyle(color: _sub(d), fontSize: 14)),
        const SizedBox(height: 55),
        _gradBtn('Retry Payment', _process),
        const SizedBox(height: 12),
        _outlineBtn('Change Method', d ? Colors.white : Colors.black87,
            () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PaymentMethodsSelectScreen())),
            d),
      ]),
    );
  }
}