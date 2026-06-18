import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '/services/geocoding_service.dart';

// ══════════════════════════════════════════════════════════
//  APP MAP WIDGET  —  الخريطة الموحّدة للتطبيق كله
//  ✅ Dark Theme + Cyan Glow — نفس الشكل والستايل
//
//  Trader (تتبع الشحنة):
//    AppMapWidget(
//      pickupLocation: shipment.origin,
//      dropoffLocation: shipment.destination,
//      driverName: shipment.driverName,
//      status: shipmentStatusLabel(shipment.status),
//      onTap: () => openLiveTracking(shipment),
//    )
//
//  Driver (التنقل لحد التسليم):
//    AppMapWidget(
//      pickupLocation: order.pickup,
//      dropoffLocation: order.dropoff,
//      showLiveTracking: true,
//      showMyLocationButton: true,
//      height: null,
//    )
// ══════════════════════════════════════════════════════════

// ─── Colors ───────────────────────────────────────────────
const _kCyan  = Color(0xFF00D5BE);
const _kCyan2 = Color(0xFF00BBA7);
const _kBg    = Color(0xFF0F2334);
const _kMuted = Color(0xFFCBFBF1);

class AppMapWidget extends StatefulWidget {
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? driverName;
  final String? status;
  final VoidCallback? onTap;
  final bool showLiveTracking;
  final bool showMyLocationButton;
  final double? height;
  final String emptyStateLabel;

  const AppMapWidget({
    super.key,
    this.pickupLocation,
    this.dropoffLocation,
    this.driverName,
    this.status,
    this.onTap,
    this.showLiveTracking = false,
    this.showMyLocationButton = false,
    this.height = 200,
    this.emptyStateLabel = 'No active shipment',
  });

  @override
  State<AppMapWidget> createState() => _AppMapWidgetState();
}

class _AppMapWidgetState extends State<AppMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(30.0444, 31.2357);

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  LatLng? _currentPosition;
  bool _loading = true;

  LatLng? _truckPosition;
  Timer? _liveTimer;
  double _liveProgress = 0;

  // ── Pulse animation للـ markers المتوهجة ──
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadCoordinates();
  }

  @override
  void didUpdateWidget(AppMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.dropoffLocation != widget.dropoffLocation) {
      _liveTimer?.cancel();
      _loadCoordinates();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoordinates() async {
    setState(() => _loading = true);

    if (widget.pickupLocation == null ||
        widget.pickupLocation!.isEmpty ||
        widget.dropoffLocation == null ||
        widget.dropoffLocation!.isEmpty) {
      // ✅ Fallback to default route: Fayoum to Cairo
      setState(() {
        _pickupLatLng = const LatLng(29.3084, 30.8428); // Fayoum
        _dropoffLatLng = const LatLng(30.0444, 31.2357); // Cairo
        _loading = false;
      });
      _moveCameraToFitRoute();
      if (widget.showLiveTracking) _startLiveTracking();
      return;
    }

    final results = await Future.wait([
      GeocodingService.getCoordinates(widget.pickupLocation!),
      GeocodingService.getCoordinates(widget.dropoffLocation!),
    ]);

    if (!mounted) return;

    setState(() {
      _pickupLatLng = results[0] != null
          ? LatLng(results[0]![0], results[0]![1])
          : null;
      _dropoffLatLng = results[1] != null
          ? LatLng(results[1]![0], results[1]![1])
          : null;
      _loading = false;
    });

    if (_pickupLatLng != null && _dropoffLatLng != null) {
      _moveCameraToFitRoute();
      if (widget.showLiveTracking) _startLiveTracking();
    }
  }

  void _moveCameraToFitRoute() {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;
    final centerLat = (_pickupLatLng!.latitude + _dropoffLatLng!.latitude) / 2;
    final centerLng = (_pickupLatLng!.longitude + _dropoffLatLng!.longitude) / 2;

    double zoom = 12.0;
    try {
      final distance = Geolocator.distanceBetween(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _dropoffLatLng!.latitude,
        _dropoffLatLng!.longitude,
      );
      if (distance > 150000) {
        zoom = 8.0;
      } else if (distance > 80000) {
        zoom = 9.0;
      } else if (distance > 30000) {
        zoom = 10.5;
      } else if (distance > 10000) {
        zoom = 12.0;
      } else {
        zoom = 13.5;
      }
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _mapController.move(LatLng(centerLat, centerLng), zoom);
    });
  }

  void _startLiveTracking() {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;
    _liveTimer?.cancel();
    setState(() => _truckPosition = _pickupLatLng);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween  = Tween<double>(begin: _mapController.camera.center.latitude,  end: destLocation.latitude);
    final lngTween  = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom,             end: destZoom);
    final controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    controller.addListener(() => _mapController.move(
      LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
      zoomTween.evaluate(animation),
    ));
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
      _animatedMapMove(_currentPosition!, 15.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasShipment = widget.pickupLocation != null &&
        widget.pickupLocation!.isNotEmpty &&
        widget.dropoffLocation != null &&
        widget.dropoffLocation!.isNotEmpty;

    final mapBody = ClipRRect(
      borderRadius: BorderRadius.circular(widget.height == null ? 0 : 24),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [

          // ── الخريطة ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickupLatLng ?? _defaultCenter,
              initialZoom: 12.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag,
              ),
            ),
            children: [
              // ✅ CartoDB Light — بيضاء ومجانية
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.truckmate.app',
              ),

              // ── Route: glow layer + main line ──
              if (_pickupLatLng != null && _dropoffLatLng != null)
                PolylineLayer(polylines: [
                  // Glow
                  Polyline(
                    points: [_pickupLatLng!, _dropoffLatLng!],
                    color: _kCyan.withOpacity(0.3),
                    strokeWidth: 12.0,
                  ),
                  // Main
                  Polyline(
                    points: [_pickupLatLng!, _dropoffLatLng!],
                    color: _kCyan,
                    strokeWidth: 4.0,
                  ),
                ]),

              // ── Markers ──
              MarkerLayer(markers: [
                if (_pickupLatLng != null)
                  Marker(
                    point: _pickupLatLng!,
                    width: 48, height: 48,
                    child: _buildPickupMarker(),
                  ),
                if (_dropoffLatLng != null)
                  Marker(
                    point: _dropoffLatLng!,
                    width: 48, height: 48,
                    child: _buildDropoffMarker(),
                  ),
                if (widget.showLiveTracking && _truckPosition != null)
                  Marker(
                    point: _truckPosition!,
                    width: 56, height: 56,
                    child: _buildTruckMarker(),
                  ),
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!,
                    width: 48, height: 48,
                    child: _buildMyLocationMarker(),
                  ),
              ]),
            ],
          ),

          // ── Loading ──
          if (_loading)
            Container(
              color: _kBg.withOpacity(0.75),
              child: const Center(
                child: CircularProgressIndicator(color: _kCyan, strokeWidth: 2),
              ),
            ),

          // ── Info card (للتريدر) ──
          if (hasShipment && !widget.showLiveTracking)
            Positioned(
              top: 12, left: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kBg.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCyan.withOpacity(0.35)),
                  boxShadow: [BoxShadow(
                      color: _kCyan.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _kCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping, color: _kCyan, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.pickupLocation} → ${widget.dropoffLocation}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.driverName != null &&
                            widget.driverName!.isNotEmpty)
                          Text(
                            'Driver: ${widget.driverName}',
                            style: TextStyle(
                                color: _kMuted.withOpacity(0.6), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  if (widget.status != null && widget.status!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kCyan.withOpacity(0.4)),
                      ),
                      child: Text(
                        widget.status!,
                        style: const TextStyle(
                            color: _kCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ]),
              ),
            ),

          // ── Empty state ──
          if (!hasShipment && !_loading)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kBg.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kCyan.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        color: _kCyan.withOpacity(0.7), size: 16),
                    const SizedBox(width: 8),
                    Text(widget.emptyStateLabel,
                        style: TextStyle(
                            color: _kMuted.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
            ),

          // ── Track Live button (للتريدر) ──
          if (hasShipment && widget.onTap != null)
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kCyan, _kCyan2]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: _kCyan.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Track Live',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),

          // ── My Location button (للدرايفر) ──
          if (widget.showMyLocationButton)
            Positioned(
              bottom: 12, right: 12,
              child: GestureDetector(
                onTap: _getCurrentLocation,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kBg.withOpacity(0.95),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kCyan.withOpacity(0.4)),
                    boxShadow: [BoxShadow(
                        color: _kCyan.withOpacity(0.2), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.my_location, color: _kCyan, size: 20),
                ),
              ),
            ),
        ]),
      ),
    );

    if (widget.onTap == null) return mapBody;
    return GestureDetector(onTap: widget.onTap, child: mapBody);
  }

  // ── Pickup marker: نقطة cyan متوهجة ──
  Widget _buildPickupMarker() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kCyan.withOpacity(0.2 * _pulseAnim.value),
        boxShadow: [BoxShadow(
          color: _kCyan.withOpacity(0.6 * _pulseAnim.value),
          blurRadius: 16 * _pulseAnim.value,
          spreadRadius: 2,
        )],
      ),
      child: Center(
        child: Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: _kCyan,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ),
    ),
  );

  // ── Dropoff marker: حلقة cyan ──
  Widget _buildDropoffMarker() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kCyan.withOpacity(0.15 * _pulseAnim.value),
        boxShadow: [BoxShadow(
          color: _kCyan.withOpacity(0.4 * _pulseAnim.value),
          blurRadius: 12 * _pulseAnim.value,
        )],
      ),
      child: Center(
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBg,
            border: Border.all(color: _kCyan, width: 2.5),
          ),
          child: const Center(
            child: Icon(Icons.circle, color: _kCyan, size: 8),
          ),
        ),
      ),
    ),
  );

  // ── Truck marker: navigation icon متوهج ──
  Widget _buildTruckMarker() => AnimatedBuilder(
    animation: _pulseAnim,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kCyan.withOpacity(0.25 * _pulseAnim.value),
        boxShadow: [BoxShadow(
          color: _kCyan.withOpacity(0.7 * _pulseAnim.value),
          blurRadius: 20 * _pulseAnim.value,
          spreadRadius: 3,
        )],
      ),
      child: Center(
        child: Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: _kCyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.navigation_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    ),
  );

  // ── My location marker ──
  Widget _buildMyLocationMarker() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue.withOpacity(0.2),
      boxShadow: [BoxShadow(
          color: Colors.blue.withOpacity(0.4), blurRadius: 12)],
    ),
    child: Center(
      child: Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )],
        ),
      ),
    ),
  );
}

// ── Cyan grid painter ─────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D5BE).withOpacity(0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}