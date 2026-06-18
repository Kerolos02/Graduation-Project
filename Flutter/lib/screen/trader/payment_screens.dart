import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';
import '/screen/trader/trader_rating_screen.dart';

// ══════════════════════════════════════════════════════
//  COLORS & DURATIONS
// ══════════════════════════════════════════════════════
const Color _kTeal = Color(0xFF00D5BE);
const Color _kTeal2 = Color(0xFF00B8DB);
const Color _kGreen = Color(0xFF009689);
const Color _kGreen2 = Color(0xFF00BBA7);
const Color _kRed = Color(0xFFEF4444);

const Duration _kFast = Duration(milliseconds: 300);
const Duration _kMed = Duration(milliseconds: 500);
const Duration _kSlow = Duration(milliseconds: 700);
const Duration _kStagger = Duration(milliseconds: 80);

const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack = Curves.easeOutBack;
const Curve _kSpring = Curves.elasticOut;

Color _bg(bool d) => d ? const Color(0xFF0A1628) : const Color(0xFFF5F8FA);
Color _card(bool d) =>
    d ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
Color _text(bool d) => d ? const Color(0xFFF0FDFA) : const Color(0xFF1A2A3A);
Color _muted(bool d) => d ? const Color(0xFF8A9BB0) : const Color(0xFF8A9BB0);
Color _border(bool d) =>
    d ? const Color(0xFF00D5BE).withOpacity(0.15) : const Color(0xFFE2EAF0);
Color _sub(bool d) => d ? const Color(0xFF0D1F30) : const Color(0xFFF0F4F8);

// ══════════════════════════════════════════════════════
//  SHARED: Animated press
// ══════════════════════════════════════════════════════
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) {
      _c.reverse();
      widget.onTap?.call();
    },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

// ══════════════════════════════════════════════════════
//  SHARED: Gradient button
// ══════════════════════════════════════════════════════
class _GradBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => _Press(
      onTap: onTap,
      child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kGreen, _kGreen2, _kTeal2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: _kGreen2.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ])));
}

// ══════════════════════════════════════════════════════
//  SHARED: Outline button
// ══════════════════════════════════════════════════════
class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
  final Color bgColor;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor = _kTeal,
    this.textColor = const Color(0xFFF0FDFA),
    this.borderColor = const Color(0x26D5BE00),
    this.bgColor = const Color(0x990A1628),
  });
  @override
  Widget build(BuildContext context) => _Press(
      onTap: onTap,
      child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withOpacity(0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ])));
}

// ══════════════════════════════════════════════════════
//  SHARED: Back button
// ══════════════════════════════════════════════════════
class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _BackBtn({required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => _Press(
      onTap: onTap,
      child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0A1628).withOpacity(0.7)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kTeal.withOpacity(0.25))),
          child:
          const Icon(Icons.chevron_left_rounded, color: _kTeal, size: 24)));
}

// ══════════════════════════════════════════════════════
//  SHARED: Row label/value
// ══════════════════════════════════════════════════════
class _Row extends StatelessWidget {
  final String label, value;
  final Color kt, km;
  const _Row(
      {required this.label,
        required this.value,
        required this.kt,
        required this.km});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: km, fontSize: 14)),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: kt, fontSize: 14, fontWeight: FontWeight.w600))),
      ]);
}

// ══════════════════════════════════════════════════════
//  1. PAYMENT PROCESSING
//  ✅ بيعمل API call حقيقي لـ payInvoice
// ══════════════════════════════════════════════════════
class PaymentProcessingScreen extends StatefulWidget {
  final String driverName;
  final String driverInitials;
  final double amount;
  final String invoiceId; // ✅ جديد — required للـ API call
  final String? cardId; // ✅ جديد — الكارد المختار

  const PaymentProcessingScreen({
    super.key,
    this.driverName = 'Ahmed Hassan',
    this.driverInitials = 'AH',
    this.amount = 240,
    this.invoiceId = '', // فاضي = demo mode
    this.cardId,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingState();
}

class _PaymentProcessingState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spin, _pulse, _text;
  late Animation<double> _pulseScale, _pulseOpacity, _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _spin =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.4)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(begin: 0.25, end: 0.6)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _text = AnimationController(vsync: this, duration: _kMed);
    _textFade = CurvedAnimation(parent: _text, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _text, curve: _kEaseOutCubic));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _text.forward();
    });

    // ✅ بعد شوية animation، نعمل الـ API call
    Future.delayed(const Duration(milliseconds: 800), _processPayment);
  }

  // ✅ الـ function الجديدة اللي بتكلم الـ API
  Future<void> _processPayment() async {
    if (!mounted) return;

    final provider = context.read<TraderProvider>();
    bool success = false;

    if (widget.invoiceId.isNotEmpty) {
      // ✅ API call حقيقي — POST /api/trader/invoices/{invoiceId}/pay
      success = await provider.payInvoice(
        invoiceId: widget.invoiceId,
        cardId: widget.cardId ?? '',
      );
    } else {
      // Demo mode — simulate delay بس
      await Future.delayed(const Duration(milliseconds: 1500));
      success = true;
    }

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
          context,
          _fadeRoute(PaymentSuccessScreen(
            driverName: widget.driverName,
            driverInitials: widget.driverInitials,
            amount: widget.amount,
          )));
    } else {
      // ✅ لو الـ API فشل، روح لـ Failed screen
      Navigator.pushReplacement(
          context, _fadeRoute(const PaymentFailedScreen()));
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _text.dispose();
    super.dispose();
  }

  Color _textColor(bool d) =>
      d ? const Color(0xFFF0FDFA) : const Color(0xFF1A2A3A);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(isDark),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: Listenable.merge([_spin, _pulse]),
              builder: (_, __) => SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(alignment: Alignment.center, children: [
                    Opacity(
                        opacity: _pulseOpacity.value,
                        child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF34D399)
                                        .withOpacity(0.3))))),
                    Transform.rotate(
                        angle: _spin.value * 2 * pi,
                        child: CustomPaint(
                            painter: _ArcPainter(), size: const Size(80, 80))),
                  ])),
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                  position: _textSlide,
                  child: Column(children: [
                    Text('Processing\nyour payment...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _textColor(isDark),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3)),
                    const SizedBox(height: 16),
                    Text('Please wait while we process',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted(isDark), fontSize: 15)),
                  ])),
            ),
          ])),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        -pi / 2,
        pi * 1.5,
        false,
        Paint()
          ..shader = const LinearGradient(colors: [_kGreen, _kTeal])
              .createShader(Rect.fromLTWH(0, 0, 80, 80))
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ══════════════════════════════════════════════════════
//  2. PAYMENT SUCCESS
// ══════════════════════════════════════════════════════
class PaymentSuccessScreen extends StatefulWidget {
  final String driverName;
  final String driverInitials;
  final double amount;

  const PaymentSuccessScreen({
    super.key,
    this.driverName = 'Ahmed Hassan',
    this.driverInitials = 'AH',
    this.amount = 240,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessState();
}

class _PaymentSuccessState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _icon, _amount, _receipt, _btns;
  late Animation<double> _iconScale,
      _iconFade,
      _iconRotate,
      _amountVal,
      _receiptFade;
  late Animation<Offset> _receiptSlide;
  late AnimationController _glow;
  late Animation<double> _glowScale, _glowOpacity;
  late List<Animation<double>> _btnFades;
  late List<Animation<Offset>> _btnSlides;

  String get _txnId {
    const c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return 'TXN-' + List.generate(8, (_) => c[r.nextInt(c.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    _icon = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _icon, curve: _kSpring));
    _iconFade = CurvedAnimation(parent: _icon, curve: _kEaseOutCubic);
    _iconRotate = Tween<double>(begin: -0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _icon, curve: _kSpring));

    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowScale = Tween<double>(begin: 1.0, end: 1.4)
        .animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.25, end: 0.55)
        .animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));

    _amount = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _amountVal = Tween<double>(begin: 0, end: widget.amount)
        .animate(CurvedAnimation(parent: _amount, curve: _kEaseOutCubic));

    _receipt = AnimationController(vsync: this, duration: _kSlow);
    _receiptFade = CurvedAnimation(parent: _receipt, curve: _kEaseOutCubic);
    _receiptSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(CurvedAnimation(parent: _receipt, curve: _kEaseOutCubic));

    const totalMs = 350 + 3 * 80;
    _btns = AnimationController(
        vsync: this, duration: const Duration(milliseconds: totalMs));
    _btnFades = List.generate(3, (i) {
      final s = (i * 80) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _btns, curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _btnSlides = List.generate(3, (i) {
      final s = (i * 80) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
          parent: _btns, curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _icon.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _amount.forward();
      _receipt.forward();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _btns.forward();
  }

  @override
  void dispose() {
    _icon.dispose();
    _glow.dispose();
    _amount.dispose();
    _receipt.dispose();
    _btns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kT = _text(isDark), kM = _muted(isDark), kB = _border(isDark);
    final now = DateTime.now();
    final txn = _txnId;
    final dateStr = _fmt(now);

    final btns = <Map<String, dynamic>>[
      {
        'label': 'Rate Your Experience',
        'icon': Icons.star_outline_rounded,
        'onTap': () => Navigator.push(
            context,
            _slideUpRoute(RateDriverScreen(
              driverName: widget.driverName,
              driverInitials: widget.driverInitials,
            ))),
      },
      {
        'label': 'Download Invoice',
        'icon': Icons.download_rounded,
        'onTap': () =>
            Navigator.push(context, _slideUpRoute(const InvoiceScreen())),
      },
      {
        'label': 'Return to Home',
        'icon': Icons.home_outlined,
        'onTap': () => Navigator.of(context).popUntil((r) => r.isFirst),
      },
    ];

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: Listenable.merge([_icon, _glow]),
              builder: (_, __) => SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    Opacity(
                        opacity: _glowOpacity.value * _iconFade.value,
                        child: Transform.scale(
                            scale: _glowScale.value,
                            child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF34D399)
                                        .withOpacity(0.25))))),
                    Transform.scale(
                      scale: _iconScale.value,
                      child: RotationTransition(
                        turns: _iconRotate,
                        child: Opacity(
                          opacity: _iconFade.value.clamp(0.0, 1.0),
                          child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF34D399),
                                        Color(0xFF10B981)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF34D399)
                                            .withOpacity(0.55),
                                        blurRadius: 30,
                                        spreadRadius: 4)
                                  ]),
                              child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 58)),
                        ),
                      ),
                    ),
                  ])),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _iconFade,
              child: Column(children: [
                Text('Payment Successful!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kT, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Your payment has been processed successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kM, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _receiptFade,
              child: SlideTransition(
                position: _receiptSlide,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: _card(isDark),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kB),
                      boxShadow: isDark
                          ? []
                          : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(children: [
                    Text('Amount Paid',
                        style: TextStyle(color: kM, fontSize: 14)),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                        animation: _amountVal,
                        builder: (_, __) => const Text(
                            '\$150',
                            style: const TextStyle(
                                color: _kTeal,
                                fontSize: 42,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(height: 20),
                    Divider(color: kB),
                    const SizedBox(height: 16),
                    _Row(label: 'Transaction ID', value: txn, kt: kT, km: kM),
                    const SizedBox(height: 12),
                    _Row(label: 'Date & Time', value: "Jun 25, 2026 • 10:00 AM", kt: kT, km: kM),
                    const SizedBox(height: 12),
                    _Row(
                        label: 'Payment Method',
                        value: 'Visa **** 4444',
                        kt: kT,
                        km: kM),
                    const SizedBox(height: 12),
                    _Row(
                        label: 'Driver',
                        value: widget.driverName,
                        kt: kT,
                        km: kM),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _receiptFade,
              child: SlideTransition(
                position: _receiptSlide,
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF34D399).withOpacity(0.3))),
                    child: const Text('A receipt has been sent to your email',
                        textAlign: TextAlign.center,
                        style:
                        TextStyle(color: Color(0xFF34D399), fontSize: 14))),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(3, (i) {
              final label = btns[i]['label'] as String;
              final icon = btns[i]['icon'] as IconData;
              final onTap = btns[i]['onTap'] as VoidCallback;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeTransition(
                  opacity: _btnFades[i],
                  child: SlideTransition(
                    position: _btnSlides[i],
                    child: i == 0
                        ? _GradBtn(label: label, icon: icon, onTap: onTap)
                        : _OutlineBtn(
                        label: label,
                        icon: icon,
                        onTap: onTap,
                        iconColor: _kTeal,
                        textColor: isDark
                            ? const Color(0xFFF0FDFA)
                            : const Color(0xFF1A2A3A),
                        bgColor: isDark
                            ? const Color(0xFF0A1628).withOpacity(0.6)
                            : Colors.white,
                        borderColor: _kTeal.withOpacity(0.3)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '${months[t.month - 1]} ${t.day}, ${t.year} • '
        '$h:${t.minute.toString().padLeft(2, '0')} $ampm';
  }
}

// ══════════════════════════════════════════════════════
//  3. INVOICE SCREEN
//  ✅ بتجيب بيانات الـ invoice من الـ API لو في invoiceId
//  ✅ زيادة: Download PDF من /api/trader/invoices/{id}/pdf
//  ✅ زيادة: Share Invoice من /api/trader/invoices/{id}/share
// ══════════════════════════════════════════════════════
class InvoiceScreen extends StatefulWidget {
  final String? invoiceId; // ✅ جديد — لو null = demo data

  // Fallback/demo values
  final String shipmentId,
      pickup,
      dropoff,
      date,
      driver,
      vehicle,
      plate,
      paymentMethod;
  final double basePrice, serviceFee, tax;

  const InvoiceScreen({
    super.key,
    this.invoiceId,
    this.shipmentId = 'TM-2I8KIDJ70',
    this.pickup = 'Fayum', // ✅
    this.dropoff = 'Cairo', // ✅
    this.date = 'Jun 25, 2026 • 10:00 AM', // ✅
    this.driver = 'Ahmed Hassan',
    this.vehicle = 'Pickup Truck',
    this.plate = 'ABC-1234',
    this.basePrice = 200,
    this.serviceFee = 20,
    this.tax = 20,
    this.paymentMethod = 'Visa ** 4532',
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceState();
}

class _InvoiceState extends State<InvoiceScreen> with TickerProviderStateMixin {
  late AnimationController _pageCtrl,
      _headerCtrl,
      _iconCtrl,
      _cardCtrl,
      _btnsCtrl;
  late Animation<double> _pageFade,
      _headerFade,
      _iconScale,
      _iconFade,
      _cardFade,
      _btnsFade;
  late Animation<Offset> _pageSlide, _headerSlide, _cardSlide, _btnsSlide;

  // ✅ الـ data اللي هتيجي من الـ API
  Map<String, dynamic>? _invoiceData;
  bool _loadingInvoice = false;

  // Helpers للـ display — بتاخد من API لو موجود، fallback للـ widget params
  String get _pickup =>
      _invoiceData?['route']?['pickupLocation'] ?? widget.pickup;
  String get _dropoff =>
      _invoiceData?['route']?['dropoffLocation'] ?? widget.dropoff;
  String get _driver => "محمود ناصر";
  String get _vehicle =>
      _invoiceData?['driver']?['vehicleType'] ?? widget.vehicle;
  String get _plate => _invoiceData?['driver']?['licensePlate'] ?? widget.plate;
  String get _payMethod =>
      _invoiceData?['paymentMethod'] ?? widget.paymentMethod;
  String get _shipId => _invoiceData?['shipmentId'] ?? widget.shipmentId;
  String get _date => _invoiceData?['createdAt'] ?? widget.date;
  double get _basePrice =>
      (_invoiceData?['baseAmount'] as num?)?.toDouble() ?? widget.basePrice;
  double get _serviceFeeVal =>
      (_invoiceData?['serviceFee'] as num?)?.toDouble() ?? widget.serviceFee;
  double get _taxVal =>
      (_invoiceData?['taxAmount'] as num?)?.toDouble() ?? widget.tax;
  double get _total =>
      (_invoiceData?['totalAmount'] as num?)?.toDouble() ??
          (_basePrice + _serviceFeeVal + _taxVal);

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));
    _headerCtrl = AnimationController(vsync: this, duration: _kMed)..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);
    _cardCtrl = AnimationController(vsync: this, duration: _kMed);
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: _kEaseOutCubic);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: _kEaseOutCubic));
    _btnsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _btnsFade = CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut);
    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _btnsCtrl.forward();
    });

    // ✅ لو في invoiceId، جيب البيانات من الـ API
    if (widget.invoiceId != null && widget.invoiceId!.isNotEmpty) {
      _loadInvoice();
    }
  }

  // ✅ GET /api/trader/invoices/{invoiceId}
  Future<void> _loadInvoice() async {
    setState(() => _loadingInvoice = true);
    final provider = context.read<TraderProvider>();
    final data = await provider.loadInvoice(invoiceId: widget.invoiceId!);
    if (mounted) {
      setState(() {
        _invoiceData = data;
        _loadingInvoice = false;
      });
    }
  }

  // ✅ GET /api/trader/invoices/{invoiceId}/pdf
  Future<void> _downloadPdf() async {
    if (widget.invoiceId == null || widget.invoiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No invoice to download'), backgroundColor: _kRed));
      return;
    }
    final provider = context.read<TraderProvider>();
    final success =
    await provider.downloadInvoicePdf(invoiceId: widget.invoiceId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'PDF downloaded!' : 'Download failed'),
          backgroundColor: success ? _kTeal : _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  // ✅ POST /api/trader/invoices/{invoiceId}/share
  Future<void> _shareInvoice() async {
    if (widget.invoiceId == null || widget.invoiceId!.isEmpty) return;
    final provider = context.read<TraderProvider>();
    await provider.shareInvoice(invoiceId: widget.invoiceId!);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerCtrl.dispose();
    _iconCtrl.dispose();
    _cardCtrl.dispose();
    _btnsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kT = _text(isDark), kM = _muted(isDark), kB = _border(isDark);
    final kDiv = isDark ? const Color(0xFF1C3449) : const Color(0xFFE2EAF0);
    final kPaid = isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF0FAFA);

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F8FA),
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                            position: _headerSlide,
                            child: Row(children: [
                              _BackBtn(
                                  onTap: () => Navigator.pop(context),
                                  isDark: isDark),
                              const Spacer(),
                              Text('Invoice',
                                  style: TextStyle(
                                      color: kT,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              // ✅ Loading indicator لو بيجيب البيانات
                              if (_loadingInvoice)
                                const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                        child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: _kTeal,
                                                strokeWidth: 2))))
                              else
                                const SizedBox(width: 48),
                            ]))),
                    const SizedBox(height: 24),
                    FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: _card(isDark),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: kB),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                    BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                        child: ScaleTransition(
                                            scale: _iconScale,
                                            child: FadeTransition(
                                                opacity: _iconFade,
                                                child: Container(
                                                    width: 64,
                                                    height: 64,
                                                    decoration: const BoxDecoration(
                                                        gradient: LinearGradient(
                                                            colors: [
                                                              _kTeal,
                                                              _kTeal2
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight),
                                                        shape: BoxShape.circle),
                                                    child: const Icon(
                                                        Icons
                                                            .inventory_2_outlined,
                                                        color: Colors.white,
                                                        size: 30))))),
                                    const SizedBox(height: 16),
                                    Center(
                                        child: Text('TruckMate Invoice',
                                            style: TextStyle(
                                                color: kT,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold))),
                                    const SizedBox(height: 4),
                                    Center(
                                        child: Text('INV-2026-0414-001',
                                            style: TextStyle(
                                                color: kM,
                                                fontSize: 13,
                                                letterSpacing: 1.2))),
                                    Divider(color: kDiv, height: 32),
                                    _Row(
                                        label: 'Invoice Date',
                                        value: _date,
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 12),
                                    _Row(
                                        label: 'Shipment ID',
                                        value: _shipId,
                                        kt: kT,
                                        km: kM),
                                    Divider(color: kDiv, height: 32),
                                    Text('Route Information',
                                        style: TextStyle(
                                            color: kT,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    _routePt(isDark,
                                        isPickup: true,
                                        label: 'Pickup',
                                        val: _pickup),
                                    const SizedBox(height: 12),
                                    _routePt(isDark,
                                        isPickup: false,
                                        label: 'Drop-off',
                                        val: _dropoff),
                                    Divider(color: kDiv, height: 32),
                                    Text('Shipment Details',
                                        style: TextStyle(
                                            color: kT,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    _Row(
                                        label: 'Distance',
                                        value: _invoiceData?['route']
                                        ?['distanceFormatted'] ??
                                            '12.5 km',
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'Packages',
                                        value: _invoiceData?['cargo']
                                        ?['itemsCount']
                                            ?.toString() ??
                                            '3 items',
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'Total Weight',
                                        value: _invoiceData?['cargo']
                                        ?['totalWeight'] ??
                                            '500 lbs',
                                        kt: kT,
                                        km: kM),
                                    Divider(color: kDiv, height: 32),
                                    Text('Driver Information',
                                        style: TextStyle(
                                            color: kT,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    _Row(
                                        label: 'Driver',
                                        value: _driver,
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'Vehicle',
                                        value: _vehicle,
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'License Plate',
                                        value: _plate,
                                        kt: kT,
                                        km: kM),
                                    Divider(color: kDiv, height: 32),
                                    _Row(
                                        label: 'Base Price',
                                        value: '\$${_basePrice.toInt()}',
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'Service Fee',
                                        value: '\$${_serviceFeeVal.toInt()}',
                                        kt: kT,
                                        km: kM),
                                    const SizedBox(height: 8),
                                    _Row(
                                        label: 'Tax',
                                        value: '\$${_taxVal.toInt()}',
                                        kt: kT,
                                        km: kM),
                                    Divider(color: kDiv, height: 32),
                                    Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total Amount',
                                              style: TextStyle(
                                                  color: kT,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600)),
                                          Text('\$${_total.toInt()}',
                                              style: const TextStyle(
                                                  color: _kTeal,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: kPaid,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                              color: _kTeal.withOpacity(0.25))),
                                      child: Row(children: [
                                        const Icon(Icons.credit_card_rounded,
                                            color: _kTeal, size: 24),
                                        const SizedBox(width: 12),
                                        Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text('Paid with',
                                                  style: TextStyle(
                                                      color: kM, fontSize: 12)),
                                              Text(_payMethod,
                                                  style: TextStyle(
                                                      color: kT,
                                                      fontSize: 14,
                                                      fontWeight:
                                                      FontWeight.w600)),
                                            ]),
                                      ]),
                                    ),
                                  ])),
                        )),
                    const SizedBox(height: 20),
                    FadeTransition(
                        opacity: _btnsFade,
                        child: SlideTransition(
                            position: _btnsSlide,
                            child: Column(children: [
                              // ✅ Download PDF — GET /api/trader/invoices/{id}/pdf
                              _GradBtn(
                                  label: 'Download PDF',
                                  icon: Icons.download_rounded,
                                  onTap: _downloadPdf),
                              const SizedBox(height: 12),
                              // ✅ Share Invoice — POST /api/trader/invoices/{id}/share
                              _OutlineBtn(
                                  label: 'Share Invoice',
                                  icon: Icons.share_rounded,
                                  onTap: _shareInvoice,
                                  iconColor: _kTeal,
                                  textColor: _kTeal,
                                  bgColor: isDark
                                      ? const Color(0xFF0F2A3A)
                                      : Colors.white,
                                  borderColor: _kTeal.withOpacity(0.35)),
                            ]))),
                    const SizedBox(height: 24),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _routePt(bool isDark,
      {required bool isPickup, required String label, required String val}) {
    final color = isPickup ? _kTeal : _kTeal2;
    return Row(children: [
      Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.35)),
              shape: BoxShape.circle),
          child: isPickup
              ? Center(
              child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color)))
              : Icon(Icons.location_on_rounded, color: color, size: 16)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: _muted(isDark), fontSize: 12)),
        Text(val,
            style: TextStyle(
                color: _text(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════
//  4. PAYMENT METHODS LIST
//  ✅ بتجيب الكروت من الـ API عبر TraderProvider
// ══════════════════════════════════════════════════════
class PaymentMethodsListScreen extends StatefulWidget {
  const PaymentMethodsListScreen({super.key});
  @override
  State<PaymentMethodsListScreen> createState() => _PaymentMethodsListState();
}

class _PaymentMethodsListState extends State<PaymentMethodsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _header, _btn;
  late Animation<double> _headerFade, _btnFade;
  late Animation<Offset> _headerSlide, _btnSlide;

  @override
  void initState() {
    super.initState();
    _header = AnimationController(vsync: this, duration: _kMed)..forward();
    _headerFade = CurvedAnimation(parent: _header, curve: _kEaseOutCubic);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: _header, curve: _kEaseOutCubic));
    _btn = AnimationController(vsync: this, duration: _kMed);
    _btnFade = CurvedAnimation(parent: _btn, curve: _kEaseOutCubic);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btn, curve: _kEaseOutCubic));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _btn.forward();
    });

    // ✅ جيب الكروت من الـ API — GET /api/trader/wallet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraderProvider>().loadWallet();
    });
  }

  @override
  void dispose() {
    _header.dispose();
    _btn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final provider = context.watch<TraderProvider>();
    final kT = _text(isDark), kM = _muted(isDark), kB = _border(isDark);

    // ✅ جيب الكروت من الـ walletData
    final cards = (provider.walletData?['savedCards'] as List? ??
        provider.walletData?['cards'] as List? ??
        []);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 20),
              FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                      position: _headerSlide,
                      child: Row(children: [
                        _BackBtn(
                            onTap: () => Navigator.pop(context), isDark: isDark),
                        const SizedBox(width: 16),
                        Text('Payment Methods',
                            style: TextStyle(
                                color: kT,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ]))),
              const SizedBox(height: 28),
              FadeTransition(
                  opacity: _btnFade,
                  child: SlideTransition(
                      position: _btnSlide,
                      child: _GradBtn(
                          label: '+ Add New Card',
                          icon: Icons.add_rounded,
                          onTap: () async {
                            await Navigator.push(
                                context, _slideUpRoute(const AddCardScreen()));
                            // ✅ بعد إضافة الكارت، refresh الـ wallet
                            if (mounted)
                              context.read<TraderProvider>().loadWallet();
                          }))),
              const SizedBox(height: 28),
              Text('Saved Cards',
                  style: TextStyle(
                      color: kM, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // ✅ Loading state
              if (provider.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator(color: _kTeal)))
              else if (cards.isEmpty)
                Expanded(
                    child: Center(
                        child: Text('No cards saved yet',
                            style: TextStyle(color: kM, fontSize: 15))))
              else
                Expanded(
                    child: _StaggeredCards(
                      count: cards.length,
                      itemBuilder: (_, i) {
                        final card = cards[i] as Map<String, dynamic>;
                        final cardId = (card['cardId'] ?? card['id'])?.toString() ?? '';
                        final brand = card['cardBrand'] ?? card['brand'] ?? 'Card';
                        final last4 = card['last4Digits'] ?? card['last4'] ?? '****';
                        final expiry = card['expiryMonth'] != null
                            ? '${card['expiryMonth']}/${card['expiryYear']}'
                            : '**/**';
                        final isDefault = card['isDefault'] == true;
                        final isMasterCard = brand.toLowerCase().contains('master');

                        return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CardTile(
                              data: _CardData(
                                  brand: brand,
                                  last4: last4,
                                  expiry: expiry,
                                  isDefault: isDefault,
                                  color: isMasterCard
                                      ? const Color(0xFFF6801C)
                                      : const Color(0xFF244EEE)),
                              isDark: isDark, kT: kT, kM: kM, kB: kB,
                              // ✅ DELETE /api/trader/wallet/cards/{cardId}
                              onDelete: () async {
                                final ok = await context
                                    .read<TraderProvider>()
                                    .deleteCard(cardId: cardId);
                                if (mounted && !ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                          context.read<TraderProvider>().error ??
                                              'Error'),
                                      backgroundColor: _kRed));
                                }
                              },
                              // ✅ PATCH /api/trader/wallet/cards/{cardId}/set-default
                              onSetDefault: isDefault
                                  ? null
                                  : () async {
                                await context
                                    .read<TraderProvider>()
                                    .setDefaultCard(cardId: cardId);
                              },
                            ));
                      },
                    )),
            ]),
          )),
    );
  }
}

class _StaggeredCards extends StatefulWidget {
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  const _StaggeredCards({required this.count, required this.itemBuilder});
  @override
  State<_StaggeredCards> createState() => _StaggeredCardsState();
}

class _StaggeredCardsState extends State<_StaggeredCards>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;
  @override
  void initState() {
    super.initState();
    final total =
    Duration(milliseconds: 350 + widget.count * _kStagger.inMilliseconds);
    _ctrl = AnimationController(vsync: this, duration: total);
    _fades = List.generate(widget.count, (i) {
      final s = (i * 80) / total.inMilliseconds;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _ctrl, curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _slides = List.generate(widget.count, (i) {
      final s = (i * 80) / total.inMilliseconds;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(
          parent: _ctrl, curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
      children: List.generate(
          widget.count,
              (i) => FadeTransition(
              opacity: _fades[i],
              child: SlideTransition(
                  position: _slides[i],
                  child: widget.itemBuilder(context, i)))));
}

// ══════════════════════════════════════════════════════
//  5. ADD CARD SCREEN
//  ✅ بتعمل POST /api/trader/wallet/cards
// ══════════════════════════════════════════════════════
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardState();
}

class _AddCardState extends State<AddCardScreen> with TickerProviderStateMixin {
  final _numCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  String _num = '', _name = '', _exp = '';
  bool _saving = false; // ✅ loading state

  late AnimationController _header, _cardAnim, _form;
  late Animation<double> _headerFade, _cardScale, _cardFade, _formFade;
  late Animation<Offset> _headerSlide, _formSlide;

  @override
  void initState() {
    super.initState();
    _header = AnimationController(vsync: this, duration: _kMed)..forward();
    _headerFade = CurvedAnimation(parent: _header, curve: _kEaseOutCubic);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: _header, curve: _kEaseOutCubic));
    _cardAnim = AnimationController(vsync: this, duration: _kSlow);
    _cardScale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _cardAnim, curve: _kEaseOutBack));
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: _kEaseOutCubic);
    _form = AnimationController(vsync: this, duration: _kMed);
    _formFade = CurvedAnimation(parent: _form, curve: _kEaseOutCubic);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _form, curve: _kEaseOutCubic));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _cardAnim.forward();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _form.forward();
    });
    _numCtrl.addListener(() => setState(() => _num = _numCtrl.text));
    _nameCtrl.addListener(() => setState(() => _name = _nameCtrl.text));
    _expCtrl.addListener(() => setState(() => _exp = _expCtrl.text));
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _nameCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _header.dispose();
    _cardAnim.dispose();
    _form.dispose();
    super.dispose();
  }

  // ✅ POST /api/trader/wallet/cards
  Future<void> _addCard() async {
    final raw = _numCtrl.text.replaceAll(' ', '');
    final name = _nameCtrl.text.trim();
    final expParts = _expCtrl.text.split('/');
    final cvv = _cvvCtrl.text.trim();

    // Validation بسيطة
    if (raw.length < 16 ||
        name.isEmpty ||
        expParts.length != 2 ||
        cvv.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields correctly'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<TraderProvider>();
    print('addCard: $raw $name $expParts $cvv');
    final yearVal = int.tryParse(expParts[1]) ?? 2025;
    final finalYear = yearVal < 100 ? yearVal + 2000 : yearVal;

    final ok = await provider.addCard(
      cardHolderName: name,
      cardNumber: raw,
      expiryMonth: int.tryParse(expParts[0]) ?? 1,
      expiryYear: finalYear,
      cvv: cvv,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Card added successfully!'),
          backgroundColor: _kTeal,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Failed to add card'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kT = _text(isDark), kM = _muted(isDark), kB = _border(isDark);
    final kField = isDark ? const Color(0xFF112030) : const Color(0xFFF0F4F8);
    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                        position: _headerSlide,
                        child: Row(children: [
                          _BackBtn(
                              onTap: () => Navigator.pop(context), isDark: isDark),
                          const SizedBox(width: 16),
                          Text('Add New Card',
                              style: TextStyle(
                                  color: kT,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ])))),
            const SizedBox(height: 24),
            Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    ScaleTransition(
                        scale: _cardScale,
                        child: FadeTransition(
                            opacity: _cardFade,
                            child:
                            _CardPreview(number: _num, name: _name, expiry: _exp))),
                    const SizedBox(height: 28),
                    FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                            position: _formSlide,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _lbl('Card Number', kT),
                                  _fld(_numCtrl, '1234 5678 9012 3456',
                                      TextInputType.number, kT, kM, kField, kB,
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _CardFmt()
                                      ]),
                                  const SizedBox(height: 18),
                                  _lbl('Cardholder Name', kT),
                                  _fld(_nameCtrl, 'FULL NAME', TextInputType.name, kT,
                                      kM, kField, kB,
                                      capitalize: TextCapitalization.characters),
                                  const SizedBox(height: 18),
                                  Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              _lbl('Expiry Date', kT),
                                              _fld(
                                                  _expCtrl,
                                                  'MM/YY',
                                                  TextInputType.datetime,
                                                  kT,
                                                  kM,
                                                  kField,
                                                  kB,
                                                  formatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    _ExpiryFmt()
                                                  ]),
                                            ])),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              _lbl('CVV', kT),
                                              _fld(_cvvCtrl, '•••', TextInputType.number,
                                                  kT, kM, kField, kB,
                                                  obscure: true,
                                                  formatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    LengthLimitingTextInputFormatter(3)
                                                  ]),
                                            ])),
                                  ]),
                                  const SizedBox(height: 28),
                                  // ✅ بيكلم الـ API
                                  _saving
                                      ? Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [_kGreen, _kGreen2, _kTeal2],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight),
                                          borderRadius: BorderRadius.circular(14)),
                                      child: const Center(
                                          child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))))
                                      : _GradBtn(label: 'Add Card', onTap: _addCard),
                                  const SizedBox(height: 20),
                                ]))),
                  ]),
                )),
          ])),
    );
  }

  Widget _lbl(String t, Color c) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style:
          TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500)));

  Widget _fld(TextEditingController ctrl, String hint, TextInputType type,
      Color kT, Color kM, Color kField, Color kB,
      {bool obscure = false,
        List<TextInputFormatter>? formatters,
        TextCapitalization capitalize = TextCapitalization.none}) =>
      TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          inputFormatters: formatters,
          textCapitalization: capitalize,
          style: TextStyle(color: kT, fontSize: 14),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: kM, fontSize: 14),
              filled: true,
              fillColor: kField,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kB)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kTeal, width: 1.5))));
}

// ══════════════════════════════════════════════════════
//  6. PAYMENT METHODS SELECT
//  ✅ بتجيب الكروت من TraderProvider
//  ✅ بتمرر invoiceId + cardId للـ Processing screen
// ══════════════════════════════════════════════════════
class PaymentMethodsSelectScreen extends StatefulWidget {
  final String driverName;
  final String driverInitials;
  final double price;
  final String invoiceId; // ✅ جديد — required

  const PaymentMethodsSelectScreen({
    super.key,
    this.driverName = 'Ahmed Hassan',
    this.driverInitials = 'AH',
    this.price = 240,
    this.invoiceId = '', // فاضي = demo
  });
  @override
  State<PaymentMethodsSelectScreen> createState() =>
      _PaymentMethodsSelectState();
}

class _PaymentMethodsSelectState extends State<PaymentMethodsSelectScreen>
    with TickerProviderStateMixin {
  int _sel = 0;
  late AnimationController _header, _btn;
  late Animation<double> _headerFade, _btnFade;
  late Animation<Offset> _headerSlide, _btnSlide;

  @override
  void initState() {
    super.initState();
    _header = AnimationController(vsync: this, duration: _kMed)..forward();
    _headerFade = CurvedAnimation(parent: _header, curve: _kEaseOutCubic);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: _header, curve: _kEaseOutCubic));
    _btn = AnimationController(vsync: this, duration: _kMed);
    _btnFade = CurvedAnimation(parent: _btn, curve: _kEaseOutCubic);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btn, curve: _kEaseOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _btn.forward();
    });

    // ✅ جيب الكروت — GET /api/trader/wallet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TraderProvider>().loadWallet();
    });
  }

  @override
  void dispose() {
    _header.dispose();
    _btn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final provider = context.watch<TraderProvider>();
    final kT = _text(isDark), kM = _muted(isDark), kB = _border(isDark);

    // ✅ الكروت من الـ API
    final cards = (provider.walletData?['savedCards'] as List? ??
        provider.walletData?['cards'] as List? ??
        []);

    // بنبني الـ methods list من الـ API cards
    final methods = [
      ...cards.map((c) {
        final brand = c['cardBrand'] ?? c['brand'] ?? 'Card';
        final last4 = c['last4Digits'] ?? c['last4'] ?? '****';
        final isDefault = c['isDefault'] == true;
        return _PayMethod(
          icon: Icons.credit_card_rounded,
          name: brand,
          sub: '**** **** **** $last4',
          isDefault: isDefault,
          cardId: (c['cardId'] ?? c['id'])?.toString() ?? '',
        );
      }),
      // Wallet option ثابت
      const _PayMethod(
        icon: Icons.account_balance_wallet_outlined,
        name: 'TruckMate Wallet',
        sub: 'Available balance',
        isDefault: false,
        cardId: '',
      ),
    ];

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                        position: _headerSlide,
                        child: Row(children: [
                          _BackBtn(
                              onTap: () => Navigator.pop(context), isDark: isDark),
                          const SizedBox(width: 16),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Methods',
                                    style: TextStyle(
                                        color: kT,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${widget.driverName} · \$${widget.price.toInt()}',
                                    style: TextStyle(color: kM, fontSize: 13)),
                              ]),
                        ])))),
            const SizedBox(height: 24),
            if (provider.isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator(color: _kTeal)))
            else
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _StaggeredCards(
                        count: methods.length + 1,
                        itemBuilder: (_, i) {
                          // آخر item = Add New Card
                          if (i == methods.length) {
                            return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(context,
                                          _slideUpRoute(const AddCardScreen()));
                                      if (mounted)
                                        context.read<TraderProvider>().loadWallet();
                                    },
                                    child: Container(
                                        height: 64,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: kB)),
                                        child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add,
                                                  color: _kTeal, size: 20),
                                              SizedBox(width: 10),
                                              Text('Add New Payment Method',
                                                  style: TextStyle(
                                                      color: _kTeal,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600)),
                                            ]))));
                          }

                          final m = methods[i];
                          final sel = _sel == i;
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: GestureDetector(
                                  onTap: () => setState(() => _sel = i),
                                  child: AnimatedContainer(
                                      duration: _kFast,
                                      curve: _kEaseOutCubic,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                          color: _card(isDark),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                              color: sel ? _kTeal : kB,
                                              width: sel ? 1.5 : 1.0)),
                                      child: Row(children: [
                                        Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                                color: m.name
                                                    .toLowerCase()
                                                    .contains('master')
                                                    ? const Color(0xFFF6801C)
                                                    : const Color(0xFF244EEE),
                                                borderRadius:
                                                BorderRadius.circular(12)),
                                            child: Icon(m.icon,
                                                color: const Color(0xFFFCFDFF),
                                                size: 22)),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    Text(m.name,
                                                        style: TextStyle(
                                                            color: kT,
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.w600)),
                                                    if (m.isDefault) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3),
                                                          decoration: BoxDecoration(
                                                              color: _kTeal
                                                                  .withOpacity(0.15),
                                                              borderRadius:
                                                              BorderRadius.circular(
                                                                  20),
                                                              border: Border.all(
                                                                  color: _kTeal
                                                                      .withOpacity(
                                                                      0.4))),
                                                          child: const Text('Default',
                                                              style: TextStyle(
                                                                  color: _kTeal,
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight
                                                                      .w600))),
                                                    ],
                                                  ]),
                                                  const SizedBox(height: 4),
                                                  Text(m.sub,
                                                      style: TextStyle(
                                                          color: kM, fontSize: 13)),
                                                ])),
                                        if (sel)
                                          Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: _kTeal, width: 2),
                                                  color: _kTeal.withOpacity(0.12)),
                                              child: const Icon(Icons.check_rounded,
                                                  color: _kTeal, size: 16)),
                                      ]))));
                        },
                      ))),
            SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                    opacity: _btnFade,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        child: _GradBtn(
                            label: 'Confirm Payment Method',
                            // ✅ بيمرر invoiceId + cardId الصح للـ Processing screen
                            onTap: () {
                              final selectedCardId = (_sel < methods.length)
                                  ? methods[_sel].cardId
                                  : '';
                              Navigator.pushReplacement(
                                  context,
                                  _fadeRoute(PaymentProcessingScreen(
                                    driverName: widget.driverName,
                                    driverInitials: widget.driverInitials,
                                    amount: widget.price,
                                    invoiceId: widget.invoiceId,
                                    cardId: selectedCardId,
                                  )));
                            })))),
          ])),
    );
  }
}

// ══════════════════════════════════════════════════════
//  CARD PREVIEW (unchanged)
// ══════════════════════════════════════════════════════
class _CardPreview extends StatelessWidget {
  final String number, name, expiry;
  const _CardPreview(
      {required this.number, required this.name, required this.expiry});

  String _maskNumber(String raw) {
    final d = raw.replaceAll(' ', '');
    if (d.isEmpty) return '• • • •   • • • •   • • • •   • • • •';
    final buf = StringBuffer();
    for (int i = 0; i < d.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write('   ');
      buf.write(d[i]);
    }
    final remaining = 16 - d.length;
    if (remaining > 0) {
      final groups = remaining ~/ 4;
      final leftover = remaining % 4;
      buf.write(d.length % 4 != 0 ? '  ' : '   ');
      for (int g = 0; g < groups; g++) {
        buf.write('• • • •');
        if (g < groups - 1 || leftover > 0) buf.write('   ');
      }
      if (leftover > 0) {
        buf.write(List.generate(leftover, (_) => '•').join(' '));
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      height: 195,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_kGreen, _kTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kTeal.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ]),
      child: Stack(children: [
        Positioned(
            top: -30,
            left: -30,
            child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)))),
        Positioned(
            bottom: -20,
            right: -20,
            child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)))),
        Padding(
            padding: const EdgeInsets.all(24),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                    width: 46,
                    height: 34,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6))),
                const Icon(Icons.credit_card_rounded,
                    color: Colors.white, size: 28),
              ]),
              const SizedBox(height: 20),
              Text(_maskNumber(number),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2)),
              const Spacer(),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARDHOLDER NAME',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 10,
                                  letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(name.isEmpty ? 'FULL NAME' : name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                        ]),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('EXPIRES',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 10,
                                  letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(expiry.isEmpty ? 'MM/YY' : expiry,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ]),
            ])),
      ]));
}

// ══════════════════════════════════════════════════════
//  CARD TILE — زيادة onSetDefault
// ══════════════════════════════════════════════════════
class _CardTile extends StatelessWidget {
  final _CardData data;
  final bool isDark;
  final Color kT, kM, kB;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault; // ✅ جديد
  const _CardTile(
      {required this.data,
        required this.isDark,
        required this.kT,
        required this.kM,
        required this.kB,
        required this.onDelete,
        this.onSetDefault});
  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: _card(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kB),
                boxShadow: isDark
                    ? []
                    : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: data.gradient == null ? data.color : null,
                      gradient: data.gradient,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.credit_card_rounded,
                      color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.brand,
                            style: TextStyle(
                                color: kT,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('•••• •••• •••• ${data.last4}',
                            style: TextStyle(color: kM, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Expires ${data.expiry}',
                            style: TextStyle(color: kM, fontSize: 13)),
                        // ✅ Set as default button
                        if (onSetDefault != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                              onTap: onSetDefault,
                              child: Text('Set as default',
                                  style: TextStyle(
                                      color: _kTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))),
                        ],
                      ])),
              _Press(
                  onTap: onDelete,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kRed.withOpacity(0.12)),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: _kRed, size: 20))),
            ])),
        if (data.isDefault)
          Positioned(
              top: -1,
              right: -1,
              child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: const BoxDecoration(
                      color: _kTeal,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(12))),
                  child: const Text('Default',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)))),
      ]);
}

// ══════════════════════════════════════════════════════
//  INPUT FORMATTERS
// ══════════════════════════════════════════════════════
class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(' ', '');
    if (d.length > 16) return o;
    final buf = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll('/', '');
    if (d.length > 4) return o;
    String f = d;
    if (d.length >= 3)
      f = '${d.substring(0, 2)}/${d.substring(2)}';
    else if (d.length == 2 && o.text.length == 1) f = '$d/';
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

// ══════════════════════════════════════════════════════
//  ROUTE HELPERS
// ══════════════════════════════════════════════════════
Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMed,
  reverseTransitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic)),
      child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: _kEaseOutCubic),
          child: child)),
);

Route<T> _fadeRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);

// ══════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════
class _CardData {
  final String brand, last4, expiry;
  final bool isDefault;
  final Color color;
  final Gradient? gradient;
  _CardData(
      {required this.brand,
        required this.last4,
        required this.expiry,
        required this.isDefault,
        required this.color,
        this.gradient});
}

class _PayMethod {
  final IconData icon;
  final String name, sub, cardId; // ✅ زيادة cardId
  final bool isDefault;
  const _PayMethod(
      {required this.icon,
        required this.name,
        required this.sub,
        required this.isDefault,
        required this.cardId});
}

// ══════════════════════════════════════════════════════
//  PAYMENT FAILED SCREEN
// ══════════════════════════════════════════════════════
class PaymentFailedScreen extends StatefulWidget {
  final String invoiceId; // ✅ جديد — عشان نقدر نعمل retry
  const PaymentFailedScreen({super.key, this.invoiceId = ''});
  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedState();
}

class _PaymentFailedState extends State<PaymentFailedScreen>
    with TickerProviderStateMixin {
  late AnimationController _icon, _text, _btn;
  late Animation<double> _iconScale, _iconFade, _textFade, _btnFade;
  late Animation<Offset> _textSlide, _btnSlide;

  @override
  void initState() {
    super.initState();
    _icon = AnimationController(vsync: this, duration: _kSlow);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _icon, curve: _kEaseOutBack));
    _iconFade = CurvedAnimation(parent: _icon, curve: _kEaseOutCubic);
    _text = AnimationController(vsync: this, duration: _kMed);
    _textFade = CurvedAnimation(parent: _text, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _text, curve: _kEaseOutCubic));
    _btn = AnimationController(vsync: this, duration: _kMed);
    _btnFade = CurvedAnimation(parent: _btn, curve: _kEaseOutCubic);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btn, curve: _kEaseOutCubic));
    _icon.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _text.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _btn.forward();
    });
  }

  @override
  void dispose() {
    _icon.dispose();
    _text.dispose();
    _btn.dispose();
    super.dispose();
  }

  Color _textColor(bool d) =>
      d ? const Color(0xFFF0FDFA) : const Color(0xFF1A2A3A);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kM = _muted(isDark), kB = _border(isDark);
    return Scaffold(
      backgroundColor: _bg(isDark),
      body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ScaleTransition(
                  scale: _iconScale,
                  child: FadeTransition(
                      opacity: _iconFade,
                      child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kRed,
                              boxShadow: [
                                BoxShadow(
                                    color: _kRed.withOpacity(0.45),
                                    blurRadius: 30,
                                    spreadRadius: 5)
                              ]),
                          child: const Icon(Icons.cancel_outlined,
                              color: Colors.white, size: 52)))),
              const SizedBox(height: 40),
              FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                      position: _textSlide,
                      child: Column(children: [
                        Text('Payment Failed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _textColor(isDark),
                                fontSize: 30,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        Text('Please try again',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kM, fontSize: 16)),
                      ]))),
              const SizedBox(height: 60),
              SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                      opacity: _btnFade,
                      child: Column(children: [
                        // ✅ Retry بيمرر الـ invoiceId
                        _GradBtn(
                            label: 'Retry Payment',
                            onTap: () => Navigator.pushReplacement(
                                context,
                                _fadeRoute(PaymentProcessingScreen(
                                  invoiceId: widget.invoiceId,
                                )))),
                        const SizedBox(height: 14),
                        _OutlineBtn(
                            label: 'Change Method',
                            onTap: () => Navigator.push(
                                context,
                                _slideUpRoute(PaymentMethodsSelectScreen(
                                  invoiceId: widget.invoiceId,
                                ))),
                            iconColor: _kTeal,
                            textColor: _textColor(isDark),
                            bgColor: _card(isDark),
                            borderColor: kB),
                      ]))),
            ]),
          )),
    );
  }
}
