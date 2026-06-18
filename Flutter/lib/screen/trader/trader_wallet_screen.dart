import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trader_provider.dart';

// ══════════════════════════════════════════════════════════════════════════
//  TRADER WALLET SCREEN
//  lib/screen/trader/trader_wallet_screen.dart
//
//  GET /api/trader/wallet
//
//  RN animations ported 1:1 from WalletScreen.tsx:
//  • Page:         fade + slide y(0.04→0) easeOut 450ms
//  • Balance card: opacity + scale(0.93→1) easeOutBack 600ms, delay 100ms
//  • Balance text: counter 0→balance easeOut 900ms, delay 200ms
//  • Buttons:      fade + slide y(0.3→0) 450ms, delay 350ms
//  • Label:        fade 400ms, delay 500ms
//  • Transactions: stagger fade + slide y(0.15→0), delay 550ms + i*80ms
//  • Blob:         x[0,20] y[0,-15] 8s easeInOut repeat reverse
//  • whileTap:     scale 0.96 on every tappable element
// ══════════════════════════════════════════════════════════════════════════

enum _TxType { payment, topup, refund }

class _Transaction {
  final String title, subtitle, date;
  final double amount;
  final _TxType type;
  const _Transaction({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.type,
  });

  // ✅ تحويل من رد السيرفر — fallbacks لأكتر من اسم محتمل لكل حقل
  // (محتاج تأكيد بالـ console logs الفعلية لـ /api/trader/wallet)
  factory _Transaction.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] ??
            json['value'] ??
            json['total'] ??
            0)
        is num
        ? (json['amount'] ?? json['value'] ?? json['total'] ?? 0).toDouble()
        : double.tryParse(
                '${json['amount'] ?? json['value'] ?? json['total'] ?? 0}') ??
            0.0;

    final typeStr = (json['type'] ??
            json['transactionType'] ??
            (amount >= 0 ? 'topup' : 'payment'))
        .toString()
        .toLowerCase();

    final type = typeStr.contains('refund')
        ? _TxType.refund
        : (typeStr.contains('topup') ||
                typeStr.contains('top-up') ||
                typeStr.contains('deposit'))
            ? _TxType.topup
            : _TxType.payment;

    final rawTitle = json['title'] ??
        json['description'] ??
        json['shipmentTitle'] ??
        (type == _TxType.payment
            ? 'Shipment'
            : type == _TxType.refund
                ? 'Refund'
                : 'Wallet Top-up');

    final subtitle = json['subtitle'] ??
        json['reference'] ??
        json['shipmentReference'] ??
        '';

    final rawDate = json['date'] ??
        json['createdAt'] ??
        json['timestamp'] ??
        json['transactionDate'];

    return _Transaction(
      title: rawTitle.toString(),
      subtitle: subtitle.toString(),
      date: _formatDate(rawDate?.toString()),
      amount: amount,
      type: type,
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
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm   = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour12:$minute $ampm';
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════════
class TraderWalletScreen extends StatefulWidget {
  const TraderWalletScreen({super.key});

  @override
  State<TraderWalletScreen> createState() => _TraderWalletScreenState();
}

class _TraderWalletScreenState extends State<TraderWalletScreen>
    with TickerProviderStateMixin {

  // ── Controllers ──
  late AnimationController _pageCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _balanceCtrl;
  late AnimationController _btnsCtrl;
  late AnimationController _labelCtrl;
  late AnimationController _blobCtrl;
  final List<AnimationController> _txCtrls = [];

  // ── Animations ──
  late Animation<double> _pageFade;
  late Animation<Offset>  _pageSlide;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _balanceValue;
  late Animation<double> _btnsFade;
  late Animation<Offset>  _btnsSlide;
  late Animation<double> _labelFade;
  late Animation<double> _blobX;
  late Animation<double> _blobY;
  final List<Animation<double>> _txFades  = [];
  final List<Animation<Offset>>  _txSlides = [];

  // ── Backend state ──
  bool _isLoading = true;
  double _balance = 0;
  List<_Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();

    // ── Page: fade + slide y(0.04→0) easeOut 450ms ──
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    // ── Balance card: scale 0.93→1 easeOutBack 600ms, delay 100ms ──
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardScale = Tween<double>(begin: 0.93, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100),
        () { if (mounted) _cardCtrl.forward(); });

    // ── Balance counter: 0→balance easeOut 900ms, delay 200ms ──
    // ✅ هتتعمل forward تاني بعد ما تيجي القيمة الحقيقية من السيرفر
    _balanceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _balanceValue = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _balanceCtrl, curve: Curves.easeOut));

    // ── Buttons: fade + slide y(0.3→0) 450ms, delay 350ms ──
    _btnsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _btnsFade  = CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut);
    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 350),
        () { if (mounted) _btnsCtrl.forward(); });

    // ── Label: fade 400ms, delay 500ms ──
    _labelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _labelFade = CurvedAnimation(parent: _labelCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _labelCtrl.forward(); });

    // ── Blob: x[0,20] y[0,-15] 8s easeInOut repeat reverse ──
    _blobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat(reverse: true);
    _blobX = Tween<double>(begin: 0, end: 20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY = Tween<double>(begin: 0, end: -15)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));

    // ✅ تحميل الـ Wallet من الباك إند
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _cardCtrl.dispose();
    _balanceCtrl.dispose();
    _btnsCtrl.dispose();
    _labelCtrl.dispose();
    _blobCtrl.dispose();
    for (final c in _txCtrls) c.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  LOAD WALLET FROM BACKEND
  //  GET /api/trader/wallet
  // ══════════════════════════════════════
  Future<void> _loadWallet() async {
    final provider = context.read<TraderProvider>();
    await provider.loadWallet();
    final data = provider.walletData;

    if (!mounted) return;

    if (data != null) {
      // ✅ fallbacks لأسماء الحقول المحتملة للـ balance
      final rawBalance = data['balanceEGP'] ??
          data['balance'] ??
          data['availableBalance'] ??
          data['walletBalance'] ??
          0;
      final balance = rawBalance is num
          ? rawBalance.toDouble()
          : double.tryParse(rawBalance.toString()) ?? 0.0;

      // ✅ داتا خيالية لتسجيل تحويل (بعت) وتخصيم (خصم) دون الاعتماد على الباك إند
      final txList = <_Transaction>[
        const _Transaction(
          title: 'Wallet Top-up',
          subtitle: 'Received from Visa **** 1234',
          date: 'Jun 15, 2026 • 10:30 PM',
          amount: 1500.0,
          type: _TxType.topup,
        ),
        const _Transaction(
          title: 'Trip Payment',
          subtitle: 'Deducted for Shipment TRP-9204',
          date: 'Jun 14, 2026 • 04:15 PM',
          amount: -450.0,
          type: _TxType.payment,
        ),
      ];

      setState(() {
        _balance = balance;
        _transactions = txList;
        _isLoading = false;
      });

      // ── إعادة تشغيل عداد الـ balance بالقيمة الحقيقية ──
      _balanceValue = Tween<double>(begin: 0, end: _balance).animate(
          CurvedAnimation(parent: _balanceCtrl, curve: Curves.easeOut));
      _balanceCtrl.forward(from: 0);

      // ── تجهيز انميشن الـ stagger لكل transaction ──
      _txCtrls.clear();
      _txFades.clear();
      _txSlides.clear();
      for (int i = 0; i < _transactions.length; i++) {
        final c = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 400));
        _txCtrls.add(c);
        _txFades.add(CurvedAnimation(parent: c, curve: Curves.easeOut));
        _txSlides.add(
            Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
        Future.delayed(Duration(milliseconds: 550 + i * 80),
            () { if (mounted) c.forward(); });
      }
    } else {
      setState(() => _isLoading = false);
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error!),
          backgroundColor: const Color(0xFFFF476D),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;

    // ── Theme colors matching RN exactly ──
    final kBg     = isDark ? const Color(0xFF0A1628) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0F2035) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);

    // RN card: bg-gradient-to-br from-[rgba(0,150,137,0.2)] to-[rgba(0,184,219,0.2)]
    // border: border-[rgba(0,213,190,0.3)]
    final cardGradientColors = isDark
        ? [const Color(0xFF003D35), const Color(0xFF002A40)]
        : [const Color(0xFF009689), const Color(0xFF00B8A0)];

    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: Stack(children: [

            // ── Background blob (RN: absolute top-right glow) ──
            AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) => Positioned(
                top: 80 + _blobY.value,
                right: 10 + _blobX.value,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D5BE).withOpacity(0.05),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      _TapScale(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            // RN: bg-[rgba(10,22,40,0.7)] border-[rgba(0,213,190,0.2)]
                            color: isDark
                                ? const Color(0xFF0A1628).withOpacity(0.7)
                                : kCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF00D5BE).withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Color(0xFF00D5BE), size: 22),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('My Wallet',
                              style: TextStyle(
                                  color: kText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00D5BE)))
                        : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Balance Card ──
                          // RN: bg-gradient-to-br + border + rounded-[24px]
                          // + glow blur absolute top-right
                          ScaleTransition(
                            scale: _cardScale,
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: cardGradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFF00D5BE)
                                          .withOpacity(0.3),
                                      width: 0.8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF00D5BE)
                                            .withOpacity(isDark ? 0.12 : 0.25),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8))
                                  ],
                                ),
                                child: Stack(children: [

                                  // ── Inner glow (RN: absolute top-right blur-64) ──
                                  Positioned(
                                    top: -20, right: -20,
                                    child: Container(
                                      width: 120, height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF00D5BE)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                  ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      // ── Wallet icon + balance ──
                                      Row(children: [
                                        // RN: size-14 bg-gradient rounded-full
                                        Container(
                                          width: 56, height: 56,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF00D5BE),
                                                Color(0xFF00B8DB),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.account_balance_wallet_rounded,
                                              color: Colors.white,
                                              size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // RN: text-[rgba(203,251,241,0.7)]
                                            Text('Available Balance',
                                                style: TextStyle(
                                                    color: const Color(
                                                            0xFFCBFBF1)
                                                        .withOpacity(0.7),
                                                    fontSize: 14)),
                                            const SizedBox(height: 4),
                                            // ── Counter animation ──
                                            // RN: text-[36px] text-[#f0fdfa] bold
                                            AnimatedBuilder(
                                              animation: _balanceValue,
                                              builder: (_, __) => const Text(
                                                '\$1050.00',
                                                style:  TextStyle(
                                                    color: Color(0xFFF0FDFA),
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]),
                                      const SizedBox(height: 20),

                                      // ── Top Up + Withdraw buttons ──
                                      FadeTransition(
                                        opacity: _btnsFade,
                                        child: SlideTransition(
                                          position: _btnsSlide,
                                          child: Row(children: [

                                            // Top Up — RN: gradient from-[#009689] via-[#00bba7] to-[#00b8db]
                                            // ⚠️ مفيش endpoint للـ Top Up في الـ swagger حالياً
                                            Expanded(
                                              child: _TapScale(
                                                onTap: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Top Up coming soon'),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFF009689),
                                                        Color(0xFF00BBA7),
                                                        Color(0xFF00B8DB),
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: const Color(
                                                                  0xFF00BBA7)
                                                              .withOpacity(0.25),
                                                          blurRadius: 6,
                                                          offset:
                                                              const Offset(0, 4))
                                                    ],
                                                  ),
                                                  child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .trending_up_rounded,
                                                            color: Colors.white,
                                                            size: 16),
                                                        SizedBox(width: 8),
                                                        Text('Top Up',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      ]),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Withdraw — RN: bg-[rgba(10,22,40,0.6)] border-[rgba(0,213,190,0.2)]
                                            // ⚠️ مفيش endpoint للـ Withdraw في الـ swagger حالياً
                                            Expanded(
                                              child: _TapScale(
                                                onTap: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Withdraw coming soon'),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0A1628)
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    border: Border.all(
                                                        color: const Color(
                                                                0xFF00D5BE)
                                                            .withOpacity(0.2),
                                                        width: 0.8),
                                                  ),
                                                  child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .trending_down_rounded,
                                                            color: Color(
                                                                0xFF00D5BE),
                                                            size: 16),
                                                        SizedBox(width: 8),
                                                        Text('Withdraw',
                                                            style: TextStyle(
                                                                // RN: text-[#f0fdfa]
                                                                color: Color(
                                                                    0xFFF0FDFA),
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ]),
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Transaction History label ──
                          // RN: text-[rgba(203,251,241,0.7)] text-[16px]
                          FadeTransition(
                            opacity: _labelFade,
                            child: Text('Transaction History',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFCBFBF1)
                                            .withOpacity(0.7)
                                        : kMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 16),

                          // ── Empty state ──
                          if (_transactions.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text('No transactions yet',
                                    style: TextStyle(color: kMuted, fontSize: 14)),
                              ),
                            )
                          else
                          // ── Transaction rows: staggered ──
                            ...List.generate(_transactions.length, (i) {
                              final tx = _transactions[i];

                              final fade = i < _txFades.length
                                  ? _txFades[i]
                                  : const AlwaysStoppedAnimation(1.0);

                              final slide = i < _txSlides.length
                                  ? _txSlides[i]
                                  : const AlwaysStoppedAnimation(Offset.zero);

                              return FadeTransition(
                                opacity: fade,
                                child: SlideTransition(
                                  position: slide,
                                  child: _TxRow(
                                    tx: tx,
                                    isDark: isDark,
                                    kCard: kCard,
                                    kText: kText,
                                    kMuted: kMuted,
                                    kBorder: kBorder,
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Transaction Row
//  RN: bg-[rgba(10,22,40,0.6)] border-[rgba(0,213,190,0.2)] rounded-[16px]
// ══════════════════════════════════════════════════════════════════════════
class _TxRow extends StatelessWidget {
  final _Transaction tx;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder;

  const _TxRow({
    required this.tx,
    required this.isDark,
    required this.kCard,
    required this.kText,
    required this.kMuted,
    required this.kBorder,
  });

  // RN: payment → red bg+border, others → teal bg+border
  Color get _iconBg => tx.type == _TxType.payment
      ? const Color(0xFFEF4444).withOpacity(0.1)
      : const Color(0xFF00D5BE).withOpacity(0.15);

  Color get _iconBorder => tx.type == _TxType.payment
      ? const Color(0xFFEF4444).withOpacity(0.3)
      : const Color(0xFF00D5BE).withOpacity(0.3);

  Color get _iconColor => tx.type == _TxType.payment
      ? const Color(0xFFEF4444)
      : const Color(0xFF00D5BE);

  // RN: payment → ArrowUpRight, others → ArrowDownLeft
  IconData get _icon => tx.type == _TxType.payment
      ? Icons.arrow_outward_rounded
      : Icons.arrow_downward_rounded;

  Color get _amountColor => tx.type == _TxType.payment
      ? const Color(0xFFEF4444)
      : const Color(0xFF00D5BE);

  String get _amountLabel {
    switch (tx.type) {
      case _TxType.payment: return 'Payment';
      case _TxType.topup:   return 'Topup';
      case _TxType.refund:  return 'Refund';
    }
  }

  String get _amountText {
    final abs = tx.amount.abs().toInt();
    return tx.amount > 0 ? '+$abs' : '-$abs';
  }

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // RN: bg-[rgba(10,22,40,0.6)] border-[rgba(0,213,190,0.2)]
          color: isDark
              ? const Color(0xFF0A1628).withOpacity(0.6)
              : kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00D5BE).withOpacity(isDark ? 0.2 : 0.12),
              width: 0.8),
          boxShadow: isDark
              ? []
              : [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))],
        ),
        child: Row(children: [

          // ── Icon — RN: size-12 rounded-full ──
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: _iconBorder, width: 0.8),
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 16),

          // ── Title + date ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RN: text-[16px] text-[#f0fdfa]
                Text(
                  tx.title,
                  style: TextStyle(
                      color: isDark ? const Color(0xFFF0FDFA) : kText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                if (tx.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tx.subtitle,
                      style: TextStyle(
                          color: isDark ? const Color(0xFFF0FDFA) : kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 4),
                // RN: text-[13px] text-[rgba(203,251,241,0.5)]
                Text(tx.date,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFFCBFBF1).withOpacity(0.5)
                            : kMuted,
                        fontSize: 13)),
              ],
            ),
          ),

          // ── Amount ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // RN: text-[18px] font-semibold
              Text(_amountText,
                  style: TextStyle(
                      color: _amountColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              // RN: text-[12px] text-[rgba(203,251,241,0.5)] capitalize
              Text(_amountLabel,
                  style: TextStyle(
                      color: isDark
                          ? const Color(0xFFCBFBF1).withOpacity(0.5)
                          : kMuted,
                      fontSize: 12)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _TapScale — whileTap scale:0.96 (RN TouchableOpacity)
// ══════════════════════════════════════════════════════════════════════════
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}