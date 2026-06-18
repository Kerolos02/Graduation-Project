import 'package:flutter/material.dart';
import '../services/trader_service.dart';

class TraderProvider with ChangeNotifier {
  final TraderService _service = TraderService();

  // ── Loading / Error ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Home Data ──
  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? get homeData => _homeData;

  // ── Current Shipment ──
  Map<String, dynamic>? _currentShipment;
  Map<String, dynamic>? get currentShipment => _currentShipment;
  bool get hasActiveShipment => _currentShipment != null;

  // ── Shipments List ──
  List<dynamic> _shipments = [];
  List<dynamic> get shipments => List.unmodifiable(_shipments);

  // ── Offers ──
  List<dynamic> _offers = [];
  List<dynamic> get offers => List.unmodifiable(_offers);

  // ── Suggested Drivers ──
  List<dynamic> _suggestedDrivers = [];
  List<dynamic> get suggestedDrivers => List.unmodifiable(_suggestedDrivers);

  // ── Wallet ──
  Map<String, dynamic>? _walletData;
  Map<String, dynamic>? get walletData => _walletData;

  // ── Profile ──
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  String get fullName     => _profile?['fullName']     ?? '';
  String get businessName => _profile?['businessName'] ?? '';
  String get email        => _profile?['email']        ?? '';
  String get phoneNumber  => _profile?['phoneNumber']  ?? '';
  String get initials     => _profile?['initials']     ?? _getInitials();

  String _getInitials() {
    if (fullName.isEmpty) return '??';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  // ── Notification Settings ──
  Map<String, dynamic>? _notificationSettings;
  Map<String, dynamic>? get notificationSettings => _notificationSettings;

  // ── Privacy Settings ──
  Map<String, dynamic>? _privacySettings;
  Map<String, dynamic>? get privacySettings => _privacySettings;

  // ══════════════════════════════════════════
  //  LOAD HOME
  // ══════════════════════════════════════════

  Future<void> loadHome() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getHome();
      if (res['success'] == true) {
        // ✅ الـ /api/trader/home بيرجع الـ body مباشرة
        // { success, stats, activeShipments, recentOffers, availableDrivers }
        // بدون wrapper "data" — فبنخزن الـ body كامل
        _homeData = res['data'] as Map<String, dynamic>?;
      } else {
        _error = res['message'];
      }

      final shipmentRes = await _service.getCurrentShipment();
      if (shipmentRes['success'] == true) {
        final data = shipmentRes['data']?['data'];
        _currentShipment =
            (data != null && data is Map) ? Map<String, dynamic>.from(data) : null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════
  //  LOAD SHIPMENTS
  // ══════════════════════════════════════════

  /// ✅ GET /api/trader/shipments
  /// الشكل الحقيقي للـ response:
  /// { "success": true, "count": 5, "shipments": [ {...}, {...} ] }
  /// يعني القايمة اسمها "shipments" وموجودة على مستوى الـ body مباشرة،
  /// مش جوه "data".
  Future<void> loadShipments({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getShipments(status: status);
      if (res['success'] == true) {
        final body = res['data'];
        if (body is Map) {
          // ✅ المسار الصحيح: body['shipments']
          final list = body['shipments'];
          if (list is List) {
            _shipments = list;
          } else {
            // fallback لو الشكل اختلف يوماً ما (مثلاً body['data']['shipments'])
            final nested = body['data'];
            _shipments = (nested is Map && nested['shipments'] is List)
                ? nested['shipments'] as List
                : (nested is List ? nested : []);
          }
        } else if (body is List) {
          _shipments = body;
        } else {
          _shipments = [];
        }
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════
  //  LOAD OFFERS FOR SHIPMENT
  // ══════════════════════════════════════════

  Future<void> loadOffers({
    required String shipmentId,
    String tab = 'pending',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getShipmentOffers(
        shipmentId: shipmentId,
        tab: tab,
      );
      if (res['success'] == true) {
        final data = res['data']?['data'];
        _offers = (data is List) ? data : (data?['offers'] as List? ?? []);
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════
  //  ACCEPT / REJECT OFFER
  // ══════════════════════════════════════════

  Future<bool> acceptOffer({required String offerId}) async {
    try {
      final res = await _service.acceptOffer(offerId: offerId);
      if (res['success'] == true) {
        _offers.removeWhere((o) => o['offerId'] == offerId || o['id'] == offerId);
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOffer({required String offerId}) async {
    try {
      final res = await _service.rejectOffer(offerId: offerId);
      if (res['success'] == true) {
        _offers.removeWhere((o) => o['offerId'] == offerId || o['id'] == offerId);
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  SUGGESTED DRIVERS
  // ══════════════════════════════════════════

  Future<void> loadSuggestedDrivers({required String shipmentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getSuggestedDrivers(shipmentId: shipmentId);
      if (res['success'] == true) {
        final data = res['data']?['data'];
        _suggestedDrivers = data?['drivers'] as List? ?? [];
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectDriver({
    required String shipmentId,
    required String driverId,
  }) async {
    try {
      final res = await _service.selectDriver(
        shipmentId: shipmentId,
        driverId: driverId,
      );
      if (res['success'] == true) {
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  SHIPMENT ACTIONS
  // ══════════════════════════════════════════

  Future<bool> cancelShipment({
    required String shipmentId,
    String? reason,
  }) async {
    try {
      final res = await _service.cancelShipment(
        shipmentId: shipmentId,
        reason: reason,
      );
      if (res['success'] == true) {
        await loadShipments();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markDelivered({required String shipmentId}) async {
    try {
      final res = await _service.markDelivered(shipmentId: shipmentId);
      if (res['success'] == true) {
        _currentShipment = null;
        await loadShipments();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rateDriver({
    required String shipmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await _service.rateDriver(
        shipmentId: shipmentId,
        rating: rating,
        comment: comment,
      );
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  WALLET
  // ══════════════════════════════════════════

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getWallet();
      if (res['success'] == true) {
        _walletData = res['data']?['data'];
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCard({
    required String cardHolderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      final res = await _service.addCard(
        cardHolderName: cardHolderName,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
      );
      if (res['success'] == true) {
        await loadWallet();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCard({required String cardId}) async {
    try {
      final res = await _service.deleteCard(cardId: cardId);
      if (res['success'] == true) {
        await loadWallet();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultCard({required String cardId}) async {
    try {
      final res = await _service.setDefaultCard(cardId: cardId);
      if (res['success'] == true) {
        await loadWallet();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  INVOICE
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>?> loadInvoice({
    required String invoiceId,
  }) async {
    try {
      final res = await _service.getInvoice(invoiceId: invoiceId);
      if (res['success'] == true) {
        return res['data']?['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> payInvoice({
    required String invoiceId,
    required String cardId,
  }) async {
    try {
      final res = await _service.payInvoice(
        invoiceId:     invoiceId,
        paymentCardId: cardId,
      );
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> downloadInvoicePdf({required String invoiceId}) async {
    try {
      final res = await _service.downloadInvoicePdf(invoiceId: invoiceId);
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> shareInvoice({
    required String invoiceId,
    String? method,
  }) async {
    try {
      final res = await _service.shareInvoice(
        invoiceId: invoiceId,
        method: method,
      );
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  SETTINGS / PROFILE
  // ══════════════════════════════════════════

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getProfile();
      if (res['success'] == true) {
        _profile = res['data']?['data'];
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final res = await _service.changePassword(
        currentPassword:    currentPassword,
        newPassword:        newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final res = await _service.updateContact(
        email: email,
        phoneNumber: phoneNumber,
      );
      if (res['success'] == true) {
        await loadProfile();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNotificationSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getNotificationSettings();
      if (res['success'] == true) {
        _notificationSettings = res['data']?['data'];
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _service.updateNotificationSettings(settings);
      if (res['success'] == true) {
        _notificationSettings = res['data']?['data'] ?? settings;
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPrivacySettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getPrivacySettings();
      if (res['success'] == true) {
        _privacySettings = res['data']?['data'];
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final res = await _service.updatePrivacySettings(settings);
      if (res['success'] == true) {
        _privacySettings = res['data']?['data'] ?? settings;
        notifyListeners();
        return true;
      }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount({
    required String password,
    required String confirmationPhrase,
  }) async {
    try {
      final res = await _service.deleteAccount(
        password:            password,
        confirmationPhrase:  confirmationPhrase,
      );
      if (res['success'] == true) return true;
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Clear error ──
  void clearError() {
    _error = null;
    notifyListeners();
  }
}