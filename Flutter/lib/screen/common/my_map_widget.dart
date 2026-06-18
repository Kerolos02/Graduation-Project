import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MyMapWidget extends StatefulWidget {
  const MyMapWidget({super.key});

  @override
  State<MyMapWidget> createState() => _MyMapWidgetState();
}

class _MyMapWidgetState extends State<MyMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;

  final LatLng _warehouseLocation = const LatLng(30.0624, 31.2475);
  final StreamController<LatLng> _truckLocationStreamController =
      StreamController<LatLng>.broadcast();

  @override
  void initState() {
    super.initState();
    _startMockLiveTracking();
  }

  @override
  void dispose() {
    _truckLocationStreamController.close();
    super.dispose();
  }

  void _startMockLiveTracking() {
    double baseLat = 30.0444;
    double baseLng = 31.2357;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (baseLat >= 30.0624) {
        timer.cancel();
        return;
      }
      baseLat += 0.0010;
      baseLng += 0.0005;
      if (!_truckLocationStreamController.isClosed) {
        _truckLocationStreamController.add(LatLng(baseLat, baseLng));
      }
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );
    controller.addListener(
      () => _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      ),
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(
      () => _currentPosition = LatLng(position.latitude, position.longitude),
    );
    _animatedMapMove(_currentPosition!, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(30.05, 31.24),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),

              StreamBuilder<LatLng>(
                stream: _truckLocationStreamController.stream,
                initialData: const LatLng(30.0444, 31.2357),
                builder: (context, snapshot) {
                  final truckPos = snapshot.data!;
                  return Stack(
                    children: [
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [truckPos, _warehouseLocation],
                            color: Colors.blueAccent,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _warehouseLocation,
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.warehouse_rounded,
                              color: Colors.redAccent,
                              size: 38,
                            ),
                          ),
                          Marker(
                            point: truckPos,
                            width: 50,
                            height: 50,
                            child: _buildTruckMarker(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: _buildUberMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // الكارت اللي كان ناقص
          Positioned(top: 50, left: 20, right: 20, child: _buildInfoCard()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location, color: Colors.black),
      ),
    );
  }

  Widget _buildTruckMarker() => Container(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.local_shipping, color: Colors.blue, size: 30),
  );

  Widget _buildUberMarker() => Container(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildInfoCard() => Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.15),
            child: const Icon(Icons.local_shipping, color: Colors.blue),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تتبع حي للشاحنة #4092',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'جاري التحرك باتجاه المخزن...',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}