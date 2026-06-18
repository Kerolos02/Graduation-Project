import 'package:flutter/material.dart';
import '/models/driver_models.dart';
import '/services/api_service.dart';

class DriverProvider with ChangeNotifier {
  // ── Driver Identity (من /api/driver/home) ──
  String _driverName = '';
  String get driverName => _driverName;

  double _rating = 0.0;
  double get rating => _rating;

  // ── Initials (من driverName) ──
  String get initials {
    if (_driverName.trim().isEmpty) return '??';
    final parts = _driverName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ── Online State ──
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ── Loading / Error ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Clear error (called after showing it to the user once) ──
  void clearError() {
    _error = null;
  }

  // ── Active Trip ──
  AvailableTrip? _activeTrip;
  AvailableTrip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  // ── Daily Stats ──
  DailyStats _todayStats = const DailyStats(
    tripsCompleted: 0,
    earnings: 0.0,
    onlineTime: '0h 0m',
  );
  DailyStats get todayStats => _todayStats;

  // ── Available Trips ──
  List<AvailableTrip> _availableTrips = [];
  List<AvailableTrip> get availableTrips =>
      _availableTrips.where((t) => t.status == TripStatus.available).toList();

  // ── Recent Trips ──
  List<CompletedTrip> _recentTrips = [];
  List<CompletedTrip> get recentTrips => List.unmodifiable(_recentTrips);

  // ── Total Earnings ──
  double get totalEarnings =>
      _recentTrips.fold(0.0, (sum, t) => sum + t.earnings);

  // ══════════════════════════════════════════
  //  LOAD HOME DATA  →  GET /api/driver/home
  // ══════════════════════════════════════════
  Future<void> loadHome() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService().get('/api/driver/home');
      final data = res.data;

      if (data['success'] == true) {
        final d = data['data'];

        // ── Driver Identity ──
        _driverName = (d['driverName'] ?? '').toString();
        _rating = (d['rating'] as num?)?.toDouble() ?? 0.0;

        // ── Status ──
        _isOnline = d['status'] == 'Online';

        // ── Active Trip ──
        if (d['activeTrip'] != null) {
          final t = d['activeTrip'];
          _activeTrip = AvailableTrip(
            id:             t['tripId']           ?? '',
            traderName:     t['traderName']        ?? '',
            traderRating:   t['traderRating']?.toString() ?? '0',
            origin:         t['pickupLocation']    ?? '',
            destination:    t['dropoffLocation']   ?? '',
            distance:       t['distance']          ?? '',
            estimatedTime:  t['estimatedTime']     ?? '',
            price:          (t['price'] as num?)?.toDouble() ?? 0.0,
            goodsType:      t['goodsType']         ?? '',
            weightTons:     (t['weightTons'] as num?)?.toDouble() ?? 0.0,
            isFragile:      t['isFragile']         ?? false,
            isRefrigerated: t['isRefrigerated']    ?? false,
            scheduledDate:  t['scheduledDate']     ?? '',
            scheduledTime:  t['scheduledTime']     ?? '',
          );
          // Set status
          final statusStr = (t['status'] ?? '').toString().toLowerCase();
          if (statusStr == 'inprogress' || statusStr == 'intransit') {
            _activeTrip!.status = TripStatus.inProgress;
          } else {
            _activeTrip!.status = TripStatus.accepted;
          }
        } else {
          _activeTrip = null;
        }

        // ── Daily Stats ──
        if (d['todaySummary'] != null) {
          final s = d['todaySummary'];
          _todayStats = DailyStats(
            tripsCompleted: s['tripsCompleted'] ?? 0,
            earnings:       (s['earningsEGP'] as num?)?.toDouble() ?? 0.0,
            onlineTime:     s['onlineTimeFormatted'] ?? '0h 0m',
          );
        } else if (d['todayStats'] != null) {
          // fallback لو الباك بيرجع الاسم القديم
          final s = d['todayStats'];
          _todayStats = DailyStats(
            tripsCompleted: s['tripsCompleted'] ?? 0,
            earnings:       (s['earnings'] as num?)?.toDouble() ?? 0.0,
            onlineTime:     s['onlineTime'] ?? '0h 0m',
          );
        }

        // ── Recent Trips ──
        if (d['recentTrips'] != null) {
          _recentTrips = (d['recentTrips'] as List).map((t) => CompletedTrip(
            id:          (t['shipmentNumber'] ?? t['tripId'] ?? '').toString(),
            date:        (t['date'] ?? t['earnedAtFormatted'] ?? '').toString(),
            time:        (t['time'] ?? t['earnedAtFormatted'] ?? '').toString(),
            origin:      _routeOrigin(t),
            destination: _routeDestination(t),
            earnings:    (t['amountEGP'] as num?)?.toDouble() ?? 0.0,
            miles:       0,
            status:      TripStatus.completed,
          )).toList();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helper: recent trips من DriverHomeResponseDto بيرجعوا كـ "route" string ──
  String _routeOrigin(Map t) {
    if (t['pickupLocation'] != null) return t['pickupLocation'].toString();
    final route = (t['route'] ?? '').toString();
    if (route.contains('→')) return route.split('→').first.trim();
    if (route.contains('->')) return route.split('->').first.trim();
    return '';
  }

  String _routeDestination(Map t) {
    if (t['dropoffLocation'] != null) return t['dropoffLocation'].toString();
    final route = (t['route'] ?? '').toString();
    if (route.contains('→')) return route.split('→').last.trim();
    if (route.contains('->')) return route.split('->').last.trim();
    return '';
  }

  // ══════════════════════════════════════════
  //  TOGGLE ONLINE  →  PATCH /api/driver/status
  // ══════════════════════════════════════════
  Future<void> toggleOnline() async {
    final newStatus = !_isOnline;

    // Optimistic UI update
    _isOnline = newStatus;
    notifyListeners();

    try {
      await ApiService().patch(
        '/api/driver/status',
        data: {'status': newStatus ? 'Online' : 'Offline'},
      );
    } catch (e) {
      // Revert on failure
      _isOnline = !newStatus;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════
  //  LOAD AVAILABLE TRIPS
  //  GET /api/driver/trips/available-requests
  // ══════════════════════════════════════════
  Future<void> loadAvailableTrips({int page = 1}) async {
    _error = null;
    try {
      final res = await ApiService().get(
        '/api/driver/trips/available-requests',
        queryParams: {'page': page, 'pageSize': 20, 'sortBy': 'posted_desc'},
      );
      final data = res.data;

      if (data['success'] == true && data['data'] != null) {
        final list = data['data']['requests'] as List? ?? [];
        _availableTrips = list.map((t) => AvailableTrip(
          id:             t['requestId']       ?? t['tripId'] ?? '',
          traderName:     t['traderName']       ?? '',
          traderRating:   t['traderRating']?.toString() ?? '0',
          origin:         t['pickupLocation']   ?? '',
          destination:    t['dropoffLocation']  ?? '',
          distance:       t['distanceFormatted']?.toString()
                          ?? t['distance']?.toString() ?? '',
          estimatedTime:  t['estimatedDurationFormatted']
                          ?? t['estimatedTime'] ?? '',
          price:          (t['offeredPaymentEGP'] as num?)?.toDouble()
                          ?? (t['price'] as num?)?.toDouble() ?? 0.0,
          goodsType:      t['cargoType'] ?? t['goodsType'] ?? '',
          weightTons:     (t['weightLbs'] as num?)?.toDouble()
                          ?? (t['weightTons'] as num?)?.toDouble() ?? 0.0,
          isFragile:      t['isFragile']        ?? false,
          isRefrigerated: t['isRefrigerated']   ?? false,
          scheduledDate:  t['scheduledDate']    ?? '',
          scheduledTime:  t['scheduledTime']    ?? '',
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════
  //  ACCEPT TRIP
  //  POST /api/driver/trips/requests/{requestId}/accept
  // ══════════════════════════════════════════
  Future<bool> acceptTrip(AvailableTrip trip) async {
    try {
      final res = await ApiService().post(
        '/api/driver/trips/requests/${trip.id}/accept',
      );
      final data = res.data;

      if (data['success'] == true) {
        final index = _availableTrips.indexWhere((t) => t.id == trip.id);
        if (index != -1) {
          _availableTrips[index].status = TripStatus.accepted;
          _activeTrip = _availableTrips[index];
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  REJECT TRIP
  //  POST /api/driver/trips/requests/{requestId}/reject
  // ══════════════════════════════════════════
  Future<bool> rejectTrip(AvailableTrip trip, {String? reason}) async {
    try {
      await ApiService().post(
        '/api/driver/trips/requests/${trip.id}/reject',
        data: reason != null ? {'reason': reason} : null,
      );
      final index = _availableTrips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _availableTrips[index].status = TripStatus.cancelled;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  START TRIP  →  POST /api/driver/trips/{tripId}/start
  // ══════════════════════════════════════════
  Future<bool> startTrip() async {
    if (_activeTrip == null) return false;

    try {
      final res = await ApiService().post(
        '/api/driver/trips/${_activeTrip!.id}/start',
      );
      if (res.data['success'] == true) {
        final index = _availableTrips.indexWhere((t) => t.id == _activeTrip!.id);
        if (index != -1) {
          _availableTrips[index].status = TripStatus.inProgress;
          _activeTrip = _availableTrips[index];
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  COMPLETE TRIP  →  POST /api/driver/trips/{tripId}/mark-delivered
  // ══════════════════════════════════════════
  Future<bool> completeTrip() async {
    if (_activeTrip == null) return false;
    final trip = _activeTrip!;

    try {
      final res = await ApiService().post(
        '/api/driver/trips/${trip.id}/mark-delivered',
      );
      if (res.data['success'] == true) {
        _recentTrips.insert(
          0,
          CompletedTrip(
            id:          trip.id,
            date:        _todayDate(),
            time:        _currentTime(),
            origin:      trip.origin,
            destination: trip.destination,
            earnings:    trip.price,
            miles:       int.tryParse(trip.distance.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            status:      TripStatus.completed,
          ),
        );

        _todayStats = DailyStats(
          tripsCompleted: _todayStats.tripsCompleted + 1,
          earnings:       _todayStats.earnings + trip.price,
          onlineTime:     _todayStats.onlineTime,
        );

        final index = _availableTrips.indexWhere((t) => t.id == trip.id);
        if (index != -1) {
          _availableTrips[index].status = TripStatus.completed;
        }
        _activeTrip = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  ARRIVE AT PICKUP
  //  POST /api/driver/trips/{tripId}/arrive-pickup
  // ══════════════════════════════════════════
  Future<bool> arriveAtPickup() async {
    if (_activeTrip == null) return false;
    try {
      final res = await ApiService().post(
        '/api/driver/trips/${_activeTrip!.id}/arrive-pickup',
      );
      return res.data['success'] == true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  CONFIRM PICKUP
  //  POST /api/driver/trips/{tripId}/confirm-pickup
  // ══════════════════════════════════════════
  Future<bool> confirmPickup() async {
    if (_activeTrip == null) return false;
    try {
      final res = await ApiService().post(
        '/api/driver/trips/${_activeTrip!.id}/confirm-pickup',
      );
      return res.data['success'] == true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  START DELIVERY
  //  POST /api/driver/trips/{tripId}/start-delivery
  // ══════════════════════════════════════════
  Future<bool> startDelivery() async {
    if (_activeTrip == null) return false;
    try {
      final res = await ApiService().post(
        '/api/driver/trips/${_activeTrip!.id}/start-delivery',
      );
      if (res.data['success'] == true) {
        final index = _availableTrips.indexWhere((t) => t.id == _activeTrip!.id);
        if (index != -1) {
          _availableTrips[index].status = TripStatus.inProgress;
          _activeTrip = _availableTrips[index];
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ──
  String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}