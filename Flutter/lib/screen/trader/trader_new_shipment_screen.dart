import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/services/trader_service.dart'; // ✅
import '/screen/trader/trader_driver_screens.dart';

// RN animations ported:
// • initial={{ opacity:0, x:-20 }} → header
// • initial={{ opacity:0, y:20 }} → cards staggered (delay 0.1/0.2/0.3s)
// • whileTap scale:0.98 → _TapScaleButton
// • Shimmer x[-300→300] 2s linear infinite → active button
// • Background blobs x[0,30,0] y[0,-20,0] 8s easeInOut infinite
// • AnimatedSize for refrigerated (RN layout animation)
//
// ✅ API CONNECTED:
//   POST /api/Shipment/estimate  → cost & time preview
//   POST /api/Shipment           → create shipment → SuggestedDriversScreen

class TraderNewShipmentScreen extends StatefulWidget {
  const TraderNewShipmentScreen({super.key});
  @override
  State<TraderNewShipmentScreen> createState() => _TraderNewShipmentScreenState();
}

class _TraderNewShipmentScreenState extends State<TraderNewShipmentScreen>
    with TickerProviderStateMixin {

  final _pickupCtrl  = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _packageCtrl = TextEditingController(text: '1');
  final _weightCtrl  = TextEditingController(text: '11');
  final _tempMinCtrl = TextEditingController(text: '2');
  final _tempMaxCtrl = TextEditingController(text: '8');
  bool _fragile = false, _refrigerated = false, _filled = false;
  String _selectedDate = '', _selectedTime = '';
  bool _prevFilled = false;

  // ✅ بيانات الـ estimate الحقيقية من الباك
  final TraderService _traderService = TraderService();
  bool _isEstimating = false;
  bool _isCreating   = false;
  String _distance = '--', _estTime = '--', _cost = '--';

  late final AnimationController _headerCtrl;
  late final AnimationController _card1Ctrl, _card2Ctrl, _card3Ctrl;
  late final AnimationController _btnSpringCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _blobCtrl;

  late final Animation<double> _headerFade, _card1Fade, _card2Fade, _card3Fade;
  late final Animation<Offset> _headerSlide, _card1Slide, _card2Slide, _card3Slide;
  late final Animation<double> _btnScale, _shimmerX, _blobX, _blobY;

  @override
  void initState() {
    super.initState();

    // Header: opacity+x -20→0, easeOut 500ms
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // Cards: opacity+y 20→0, easeOut 500ms
    _card1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card1Fade  = CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOut);
    _card1Slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOut));

    _card2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card2Fade  = CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOut);
    _card2Slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOut));

    _card3Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card3Fade  = CurvedAnimation(parent: _card3Ctrl, curve: Curves.easeOut);
    _card3Slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card3Ctrl, curve: Curves.easeOut));

    // Button spring on first enable
    _btnSpringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnScale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _btnSpringCtrl, curve: Curves.elasticOut));

    // Shimmer: x[-300→300] 2s linear infinite
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(_shimmerCtrl);

    // Background blobs: 8s easeInOut infinite
    _blobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat(reverse: true);
    _blobX = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _card1Ctrl.forward(); });
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _card2Ctrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _card3Ctrl.forward(); });
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _card1Ctrl.dispose(); _card2Ctrl.dispose();
    _card3Ctrl.dispose(); _btnSpringCtrl.dispose(); _shimmerCtrl.dispose();
    _blobCtrl.dispose();
    _pickupCtrl.dispose(); _dropoffCtrl.dispose(); _packageCtrl.dispose();
    _weightCtrl.dispose(); _tempMinCtrl.dispose(); _tempMaxCtrl.dispose();
    super.dispose();
  }

  void _checkFilled() {
    final now = _pickupCtrl.text.trim().isNotEmpty &&
        _dropoffCtrl.text.trim().isNotEmpty &&
        _selectedDate.isNotEmpty && _selectedTime.isNotEmpty;
    if (now && !_prevFilled) { _btnSpringCtrl.reset(); _btnSpringCtrl.forward(); }
    _prevFilled = now;
    setState(() => _filled = now);

    // ✅ لو البيانات كاملة، جيب الـ estimate الحقيقي من الباك
    if (now) {
      _fetchEstimate();
    } else {
      setState(() { _distance = '--'; _estTime = '--'; _cost = '--'; });
    }
  }

  // ✅ POST /api/Shipment/estimate
  Future<void> _fetchEstimate() async {
    setState(() => _isEstimating = true);

    final result = await _traderService.estimateShipment(
      pickupLocation: _pickupCtrl.text.trim(),
      dropOffLocation: _dropoffCtrl.text.trim(),
      scheduledDate: _scheduledDateIso(),
      scheduledTime: _scheduledTimeSpan(),
      packageCount: int.tryParse(_packageCtrl.text.trim()) ?? 1,
      weight: double.tryParse(_weightCtrl.text.trim()) ?? 1,
      isFragile: _fragile,
      isRefrigerated: _refrigerated,
      minTemperature: _refrigerated ? double.tryParse(_tempMinCtrl.text.trim()) : null,
      maxTemperature: _refrigerated ? double.tryParse(_tempMaxCtrl.text.trim()) : null,
    );

    if (!mounted) return;
    setState(() => _isEstimating = false);

    if (result['success'] == true) {
      final data = result['data'];
      final map = (data is Map && data['data'] is Map) ? data['data'] : data;
      final distanceMiles = map?['distanceMiles'];
      final estimatedTime = map?['estimatedTime'];
      final minCost = map?['minCost'];
      final maxCost = map?['maxCost'];

      setState(() {
        _distance = distanceMiles != null ? '${(distanceMiles as num).toStringAsFixed(0)} miles' : '--';
        _estTime  = estimatedTime?.toString() ?? '--';
        _cost     = (minCost != null && maxCost != null)
            ? '\$${(minCost as num).toStringAsFixed(0)} - \$${(maxCost as num).toStringAsFixed(0)}'
            : '--';
      });
    } else {
      setState(() { _distance = '--'; _estTime = '--'; _cost = '--'; });
    }
  }

  // ✅ تحويل الـ date المختار لصيغة ISO date-time
  String _scheduledDateIso() {
    if (_selectedDate.isEmpty) return '';
    return '${_selectedDate}T00:00:00';
  }

  // ✅ تحويل الـ time المختار لصيغة date-span "HH:mm:ss"
  String _scheduledTimeSpan() {
    if (_selectedTime.isEmpty) return '';
    return '$_selectedTime:00';
  }

  Future<void> _pickDate(bool d) async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: d
            ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00D5BE), onPrimary: Colors.white, surface: Color(0xFF0A1628)))
            : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(
                primary: Color(0xFF00D5BE), onPrimary: Colors.white)),
        child: child!));
    if (picked != null) {
      _selectedDate = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      _checkFilled();
    }
  }

  Future<void> _pickTime(bool d) async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: d
            ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00D5BE), onPrimary: Colors.white, surface: Color(0xFF0A1628)))
            : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(
                primary: Color(0xFF00D5BE), onPrimary: Colors.white)),
        child: child!));
    if (picked != null) {
      _selectedTime = '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
      _checkFilled();
    }
  }

  // ✅ POST /api/Shipment — إنشاء الشحنة ثم الانتقال لشاشة السواقين
  Future<void> _createShipmentAndProceed() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final result = await _traderService.createShipment(
      pickupLocation: _pickupCtrl.text.trim(),
      dropOffLocation: _dropoffCtrl.text.trim(),
      scheduledDate: _scheduledDateIso(),
      scheduledTime: _scheduledTimeSpan(),
      packageCount: int.tryParse(_packageCtrl.text.trim()) ?? 1,
      weight: double.tryParse(_weightCtrl.text.trim()) ?? 1,
      isFragile: _fragile,
      isRefrigerated: _refrigerated,
      minTemperature: _refrigerated ? double.tryParse(_tempMinCtrl.text.trim()) : null,
      maxTemperature: _refrigerated ? double.tryParse(_tempMaxCtrl.text.trim()) : null,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (result['success'] == true) {
      final data = result['data'];
      final map = (data is Map && data['data'] is Map) ? data['data'] : data;
      final shipmentId = (map?['shipmentId'] ?? map?['id'])?.toString() ?? '';

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => SuggestedDriversScreen(
            shipmentId: shipmentId,
            pickup: _pickupCtrl.text.trim(), dropoff: _dropoffCtrl.text.trim(),
            date: _selectedDate, time: _selectedTime,
            packages: _packageCtrl.text.trim(), weight: _weightCtrl.text.trim())));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed to create shipment'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    final kBg      = d ? const Color(0xFF0D1B2A) : const Color(0xFFF5F8FA);
    final kCard    = d ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
    final kBorder  = d ? const Color(0xFF00D5BE).withOpacity(0.2) : const Color(0xFFE2EAF0);
    final kText    = d ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted   = d ? Colors.white.withOpacity(0.4) : const Color(0xFF8A9BB0);
    final kFieldBg = d ? const Color(0xFF0A1628).withOpacity(0.5) : const Color(0xFFF0F4F8);
    final kToggle  = d ? const Color(0xFF0A1628).withOpacity(0.3) : const Color(0xFFF0F4F8);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kBg,
      body: Stack(children: [

        // Animated background blobs (x[0,30,0] y[0,-20,0] 8s easeInOut)
        AnimatedBuilder(
          animation: _blobCtrl,
          builder: (_, __) => Stack(children: [
            Positioned(
              top: 80 + _blobY.value, right: 10 + _blobX.value,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF00D5BE).withOpacity(0.04)))),
            Positioned(
              bottom: 100 - _blobY.value, left: 10 - _blobX.value * 0.7,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF0E8FD4).withOpacity(0.04)))),
          ]),
        ),

        SafeArea(child: Column(children: [

          // Header: x -20→0 + opacity (easeOut 500ms)
          SlideTransition(position: _headerSlide, child: FadeTransition(
            opacity: _headerFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                _TapScaleButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder)),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF00D5BE), size: 20))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create Shipment', style: TextStyle(
                      color: kText, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Set up your delivery details',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ]),
            ),
          )),
          const SizedBox(height: 20),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Step 1: y 20→0, delay 100ms
              SlideTransition(position: _card1Slide, child: FadeTransition(
                opacity: _card1Fade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _hdr('1', 'Route Setup', kText),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                        boxShadow: d ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 10, offset: const Offset(0,3))]),
                    child: Column(children: [
                      _loc('Pickup Location', const Color(0xFF00D5BE), _pickupCtrl, kText, kMuted),
                      Divider(color: kBorder, height: 1),
                      _loc('Drop-off Location', const Color(0xFF0E8FD4), _dropoffCtrl, kText, kMuted),
                      Divider(color: kBorder, height: 1),
                      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Date', style: TextStyle(color: kMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          _TapScaleButton(
                            onTap: () => _pickDate(d),
                            child: Container(height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: kFieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: kBorder)),
                              child: Row(children: [
                                const Icon(Icons.calendar_month_outlined,
                                    color: Color(0xFF00D5BE), size: 14),
                                const SizedBox(width: 6),
                                Text(_selectedDate.isEmpty ? 'Select' : _selectedDate,
                                    style: TextStyle(
                                        color: _selectedDate.isEmpty ? kMuted : kText,
                                        fontSize: 12)),
                              ])),
                          ),
                        ])),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Time', style: TextStyle(color: kMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          _TapScaleButton(
                            onTap: () => _pickTime(d),
                            child: Container(height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: kFieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: kBorder)),
                              alignment: Alignment.centerLeft,
                              child: Text(_selectedTime.isEmpty ? 'Select' : _selectedTime,
                                  style: TextStyle(
                                      color: _selectedTime.isEmpty ? kMuted : kText,
                                      fontSize: 12))),
                          ),
                        ])),
                      ])),
                    ]),
                  ),
                ]),
              )),
              const SizedBox(height: 24),

              // Step 2: y 20→0, delay 200ms
              SlideTransition(position: _card2Slide, child: FadeTransition(
                opacity: _card2Fade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _hdr('2', 'Shipment Details', kText),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                        boxShadow: d ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 10, offset: const Offset(0,3))]),
                    child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                      Row(children: [
                        Expanded(child: _inp('Package Count', _packageCtrl,
                            Icons.widgets_outlined, TextInputType.number,
                            kText, kMuted, kFieldBg, kBorder)),
                        const SizedBox(width: 12),
                        Expanded(child: _inp('Weight (Kg)', _weightCtrl,
                            Icons.monitor_weight_outlined, TextInputType.number,
                            kText, kMuted, kFieldBg, kBorder)),
                      ]),
                      const SizedBox(height: 16),
                      _toggle(Icons.widgets_outlined, const Color(0xFFE6A817),
                          'Fragile Items', 'Handle with care', _fragile, const Color(0xFF00D5BE),
                          (v) { setState(() => _fragile = v); _checkFilled(); }, kText, kMuted, kToggle),
                      const SizedBox(height: 12),
                      _toggle(Icons.thermostat_outlined, const Color(0xFF00D3F2),
                          'Refrigerated', 'Temperature controlled', _refrigerated, const Color(0xFF00D3F2),
                          (v) { setState(() => _refrigerated = v); _checkFilled(); }, kText, kMuted, kToggle),
                      // AnimatedSize = RN layout animation
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: _refrigerated
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF00D3F2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Temperature Range (°C)',
                                      style: TextStyle(color: Color(0xFF00D3F2), fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(child: _tmp('Min', _tempMinCtrl, kText, kMuted, kFieldBg)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _tmp('Max', _tempMaxCtrl, kText, kMuted, kFieldBg)),
                                  ]),
                                ]),
                              ))
                          : const SizedBox.shrink(),
                      ),
                    ])),
                  ),
                ]),
              )),
              const SizedBox(height: 24),

              // Step 3: y 20→0, delay 300ms
              SlideTransition(position: _card3Slide, child: FadeTransition(
                opacity: _card3Fade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _hdr('3', 'Cost & Time Preview', kText),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kBorder),
                        boxShadow: d ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 10, offset: const Offset(0,3))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text('Estimated values - final price after driver selection',
                              style: TextStyle(
                                  color: const Color(0xFF00D5BE).withOpacity(0.8), fontSize: 11)),
                        ),
                        if (_isEstimating)
                          const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D5BE))),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        _prev('Distance', _distance, kText, kMuted),
                        _prev('Time',     _estTime,   kText, kMuted),
                        _prev('Cost',     _cost,      kText, kMuted),
                      ]),
                    ]),
                  ),
                ]),
              )),
              const SizedBox(height: 24),

              _filled
                ? ScaleTransition(scale: _btnScale, child: _activeBtn())
                : _disabledBtn(d, kMuted),
              const SizedBox(height: 30),
            ]),
          )),
        ])),
      ]),
    );
  }

  Widget _activeBtn() => _TapScaleButton(
    onTap: _isCreating ? () {} : _createShipmentAndProceed,
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF17D4B4), Color(0xFF0E8FD4)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0,6))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(alignment: Alignment.center, children: [
          // Shimmer sweep x[-300→300] linear infinite
          AnimatedBuilder(
            animation: _shimmerX,
            builder: (_, __) => Positioned(
              left: _shimmerX.value - 40, top: 0, bottom: 0,
              child: Container(width: 80,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ]))),
            ),
          ),
          _isCreating
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Find Drivers', style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
        ]),
      ),
    ),
  );

  Widget _disabledBtn(bool d, Color kMuted) => Container(
    width: double.infinity, height: 52,
    decoration: BoxDecoration(
      color: d ? const Color(0xFF00D5BE).withOpacity(0.15) : const Color(0xFFE2EAF0),
      borderRadius: BorderRadius.circular(16)),
    child: ElevatedButton.icon(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      icon: Icon(Icons.search, color: kMuted, size: 20),
      label: Text('Find Drivers',
          style: TextStyle(color: kMuted, fontSize: 16, fontWeight: FontWeight.bold))));

  Widget _hdr(String n, String t, Color c) => Row(children: [
    Container(width: 28, height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00D5BE), width: 2)),
      child: Center(child: Text(n, style: const TextStyle(
          color: Color(0xFF00D5BE), fontSize: 13, fontWeight: FontWeight.bold)))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.bold)),
  ]);

  Widget _loc(String label, Color ic, TextEditingController ctrl,
      Color kText, Color kMuted) =>
    Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: ic.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.location_on_outlined, color: ic, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl, onChanged: (_) => _checkFilled(),
          style: TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration.collapsed(hintText: 'Enter location',
              hintStyle: TextStyle(color: kMuted, fontSize: 14))),
      ])),
      Icon(Icons.chevron_right, color: kMuted, size: 20),
    ]));

  Widget _inp(String lbl, TextEditingController ctrl, IconData icon, TextInputType type,
      Color kText, Color kMuted, Color kBg, Color kBdr) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: TextStyle(color: kMuted, fontSize: 12)),
      const SizedBox(height: 6),
      Container(height: 40, padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBdr)),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF00D5BE), size: 16),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: ctrl, keyboardType: type,
            onChanged: (_) => _checkFilled(),
            style: TextStyle(color: kText, fontSize: 13),
            decoration: const InputDecoration.collapsed(hintText: ''))),
        ])),
    ]);

  Widget _tmp(String lbl, TextEditingController ctrl, Color kText, Color kMuted, Color kBg) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: TextStyle(color: kMuted, fontSize: 11)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
        child: TextField(controller: ctrl, keyboardType: TextInputType.number,
          onChanged: (_) => _checkFilled(),
          style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: const InputDecoration.collapsed(hintText: '0'))),
    ]);

  Widget _toggle(IconData icon, Color ic, String title, String sub, bool val,
      Color activeC, ValueChanged<bool> onChange, Color kText, Color kMuted, Color kBg) =>
    Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: ic.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: ic, size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: TextStyle(
                color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ]),
        Switch(value: val, onChanged: onChange,
          activeThumbColor: Colors.white, activeTrackColor: activeC,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: kMuted.withOpacity(0.3)),
      ]));

  Widget _prev(String lbl, String val, Color kText, Color kMuted) =>
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: TextStyle(color: kMuted, fontSize: 12)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(
          color: val == '--' ? kMuted : kText, fontSize: 13, fontWeight: FontWeight.bold)),
    ]));
}

// whileTap scale:0.98 (exact RN pattern)
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
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}