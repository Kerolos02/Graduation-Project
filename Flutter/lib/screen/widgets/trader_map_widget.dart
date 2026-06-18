import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/services/geocoding_service.dart';

// ══════════════════════════════════════════════════════════
//  TRADER MAP WIDGET
//  بيعرض الخريطة مع الشحنة الحالية لو موجودة
// ══════════════════════════════════════════════════════════
class TraderMapWidget extends StatefulWidget {
  final String? shipmentId;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? driverName;
  final String? status;
  final VoidCallback? onTap; // لما تضغط على الخريطة

  const TraderMapWidget({
    super.key,
    this.shipmentId,
    this.pickupLocation,
    this.dropoffLocation,
    this.driverName,
    this.status,
    this.onTap,
  });

  @override
  State<TraderMapWidget> createState() => _TraderMapWidgetState();
}

class _TraderMapWidgetState extends State<TraderMapWidget> {
  final MapController _mapController = MapController();

  // Cairo center كـ default
  static const LatLng _defaultCenter = LatLng(30.0444, 31.2357);

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  @override
  void didUpdateWidget(TraderMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لو الشحنة اتغيرت، نعمل reload
    if (oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.dropoffLocation != widget.dropoffLocation) {
      _loadCoordinates();
    }
  }

  Future<void> _loadCoordinates() async {
    setState(() => _loading = true);

    // لو مفيش شحنة، نعرض الخريطة بدون route
    if (widget.pickupLocation == null || widget.dropoffLocation == null) {
      setState(() => _loading = false);
      return;
    }

    // جيب الـ coordinates للـ pickup و dropoff بالتوازي
    final results = await Future.wait([
      GeocodingService.getCoordinates(widget.pickupLocation!),
      GeocodingService.getCoordinates(widget.dropoffLocation!),
    ]);

    if (!mounted) return;

    setState(() {
      _pickupLatLng  = results[0] != null
          ? LatLng(results[0]![0], results[0]![1]) : null;
      _dropoffLatLng = results[1] != null
          ? LatLng(results[1]![0], results[1]![1]) : null;
      _loading = false;
    });

    // انتقل للـ route لو الاتنين موجودين
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      final centerLat = (_pickupLatLng!.latitude  + _dropoffLatLng!.latitude)  / 2;
      final centerLng = (_pickupLatLng!.longitude + _dropoffLatLng!.longitude) / 2;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _mapController.move(LatLng(centerLat, centerLng), 11.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasShipment = widget.pickupLocation != null &&
                        widget.dropoffLocation != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 200,
          child: Stack(children: [

            // ── الخريطة ──
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pickupLatLng ?? _defaultCenter,
                initialZoom: hasShipment ? 11.0 : 12.0,
                interactionOptions: const InteractionOptions(
                  // نمنع الـ scroll عشان مش يتعارض مع الـ page scroll
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                // ── Tiles (OpenStreetMap) ──
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.truckmate.app',
                ),

                // ── Route Line ──
                if (_pickupLatLng != null && _dropoffLatLng != null)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: [_pickupLatLng!, _dropoffLatLng!],
                      color: const Color(0xFF00D5BE),
                      strokeWidth: 4.0,
                    ),
                  ]),

                // ── Markers ──
                MarkerLayer(markers: [
                  // Pickup marker
                  if (_pickupLatLng != null)
                    Marker(
                      point: _pickupLatLng!,
                      width: 40, height: 40,
                      child: _buildMarker(
                        icon: Icons.circle,
                        color: const Color(0xFF00D5BE),
                      ),
                    ),
                  // Dropoff marker
                  if (_dropoffLatLng != null)
                    Marker(
                      point: _dropoffLatLng!,
                      width: 40, height: 40,
                      child: _buildMarker(
                        icon: Icons.location_on,
                        color: const Color(0xFFFF8904),
                      ),
                    ),
                ]),
              ],
            ),

            // ── Loading indicator ──
            if (_loading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D5BE)),
                ),
              ),

            // ── Info card فوق الخريطة ──
            if (hasShipment)
              Positioned(
                top: 12, left: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00D5BE).withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.local_shipping,
                        color: Color(0xFF00D5BE), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.pickupLocation} → ${widget.dropoffLocation}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.driverName != null)
                          Text(
                            'Driver: ${widget.driverName}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11),
                          ),
                      ],
                    )),
                    // Status badge
                    if (widget.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D5BE).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF00D5BE).withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.status!,
                          style: const TextStyle(
                              color: Color(0xFF00D5BE),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ]),
                ),
              ),

            // ── "No active shipment" لو مفيش شحنة ──
            if (!hasShipment && !_loading)
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF00D5BE), size: 16),
                      SizedBox(width: 8),
                      Text('No active shipment',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // ── Tap overlay hint ──
            if (hasShipment)
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D5BE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Track Live',
                          style: TextStyle(
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMarker({required IconData icon, required Color color}) =>
      Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      );
}