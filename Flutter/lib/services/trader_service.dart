import 'package:dio/dio.dart';
import 'api_service.dart';

class TraderService {
  final ApiService _api = ApiService();

  // ══════════════════════════════════════════
  //  HOME
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getHome() async {
    try {
      final response = await _api.get('/api/trader/home');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getCurrentShipment() async {
    try {
      final response = await _api.get('/api/trader/mobile/home-current-shipment');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  SHIPMENTS
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getShipments({
    String? status,
    String? city,
    String? from,
    String? to,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/shipments',
        queryParams: {
          if (status != null) 'status': status,
          if (city   != null) 'city':   city,
          if (from   != null) 'from':   from,
          if (to     != null) 'to':     to,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getShipmentDetails({
    required String shipmentId,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/mobile/shipments/$shipmentId/details',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getShipmentOffers({
    required String shipmentId,
    String tab = 'pending',
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/mobile/shipments/$shipmentId/offers',
        queryParams: {'tab': tab, 'page': page, 'pageSize': pageSize},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ POST /api/Shipment/estimate — معاينة التكلفة والوقت قبل إنشاء الشحنة
  Future<Map<String, dynamic>> estimateShipment({
    required String pickupLocation,
    required String dropOffLocation,
    required String scheduledDate,
    required String scheduledTime,
    int packageCount = 1,
    double weight = 1,
    bool isFragile = false,
    bool isRefrigerated = false,
    double? minTemperature,
    double? maxTemperature,
  }) async {
    try {
      final response = await _api.post('/api/Shipment/estimate', data: {
        'pickupLocation': pickupLocation,
        'dropOffLocation': dropOffLocation,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'packageCount': packageCount,
        'weight': weight,
        'isFragile': isFragile,
        'isRefrigerated': isRefrigerated,
        if (minTemperature != null) 'minTemperature': minTemperature,
        if (maxTemperature != null) 'maxTemperature': maxTemperature,
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ POST /api/Shipment — إنشاء شحنة جديدة
  Future<Map<String, dynamic>> createShipment({
    required String pickupLocation,
    required String dropOffLocation,
    required String scheduledDate,
    required String scheduledTime,
    int packageCount = 1,
    double weight = 1,
    bool isFragile = false,
    bool isRefrigerated = false,
    double? minTemperature,
    double? maxTemperature,
  }) async {
    try {
      final response = await _api.post('/api/Shipment', data: {
        'pickupLocation': pickupLocation,
        'dropOffLocation': dropOffLocation,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'packageCount': packageCount,
        'weight': weight,
        'isFragile': isFragile,
        'isRefrigerated': isRefrigerated,
        if (minTemperature != null) 'minTemperature': minTemperature,
        if (maxTemperature != null) 'maxTemperature': maxTemperature,
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> confirmShipment({
    required String shipmentId,
  }) async {
    try {
      final response = await _api.put('/api/Shipment/$shipmentId/confirm');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> cancelShipment({
    required String shipmentId,
    String? reason,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/shipments/$shipmentId/cancel',
        data: {'reason': reason},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> markDelivered({
    required String shipmentId,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/shipments/$shipmentId/mark-delivered',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> trackShipment({
    required String shipmentId,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/shipments/$shipmentId/tracking',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getDeliverySummary({
    required String shipmentId,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/shipments/$shipmentId/delivery-summary',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  OFFERS
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> acceptOffer({required String offerId}) async {
    try {
      final response = await _api.post(
        '/api/trader/mobile/offers/$offerId/accept',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> rejectOffer({required String offerId}) async {
    try {
      final response = await _api.post(
        '/api/trader/mobile/offers/$offerId/reject',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  DRIVERS
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getSuggestedDrivers({
    required String shipmentId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/shipments/$shipmentId/suggested-drivers',
        queryParams: {'page': page, 'pageSize': pageSize},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getDriverDetails({
    required String driverId,
    required String shipmentId,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/drivers/$driverId/details',
        queryParams: {'shipmentId': shipmentId},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> selectDriver({
    required String shipmentId,
    required String driverId,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/shipments/$shipmentId/select-driver',
        data: {'driverId': driverId},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> rateDriver({
    required String shipmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/shipments/$shipmentId/rate-driver',
        data: {'rating': rating, 'comment': comment},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  WALLET
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _api.get('/api/trader/wallet');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> addCard({
    required String cardHolderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/wallet/cards',
        data: {
          'cardHolderName': cardHolderName,
          'cardNumber':     cardNumber,
          'expiryMonth':    expiryMonth,
          'expiryYear':     expiryYear,
          'cvv':            cvv,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteCard({required String cardId}) async {
    try {
      final response = await _api.delete('/api/trader/wallet/cards/$cardId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> setDefaultCard({
    required String cardId,
  }) async {
    try {
      final response = await _api.patch(
        '/api/trader/wallet/cards/$cardId/set-default',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  INVOICES
  // ══════════════════════════════════════════

  /// GET /api/trader/invoices/{invoiceId}
  Future<Map<String, dynamic>> getInvoice({
    required String invoiceId,
  }) async {
    try {
      final response = await _api.get('/api/trader/invoices/$invoiceId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// POST /api/trader/invoices/{invoiceId}/pay
  Future<Map<String, dynamic>> payInvoice({
    required String invoiceId,
    required String paymentCardId,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/invoices/$invoiceId/pay',
        data: {'paymentCardId': paymentCardId},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// GET /api/trader/invoices/{invoiceId}/pdf  ✅ جديد
  Future<Map<String, dynamic>> downloadInvoicePdf({
    required String invoiceId,
  }) async {
    try {
      final response = await _api.get(
        '/api/trader/invoices/$invoiceId/pdf',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// POST /api/trader/invoices/{invoiceId}/share
  Future<Map<String, dynamic>> shareInvoice({
    required String invoiceId,
    String? method,
  }) async {
    try {
      final response = await _api.post(
        '/api/trader/invoices/$invoiceId/share',
        data: {'method': method},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  SETTINGS
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get('/api/trader/settings/profile');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _api.patch(
        '/api/trader/settings/change-password',
        data: {
          'currentPassword':    currentPassword,
          'newPassword':        newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updateContact({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final response = await _api.patch(
        '/api/trader/settings/update-contact',
        data: {'email': email, 'phoneNumber': phoneNumber},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _api.get('/api/trader/settings/notifications');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _api.patch(
        '/api/trader/settings/notifications',
        data: settings,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final response = await _api.get('/api/trader/settings/privacy');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _api.patch(
        '/api/trader/settings/privacy',
        data: settings,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String password,
    required String confirmationPhrase,
  }) async {
    try {
      final response = await _api.delete(
        '/api/trader/settings/account',
        data: {
          'password':           password,
          'confirmationPhrase': confirmationPhrase,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final response = await _api.post(
        '/api/trader/settings/account/cancel-deletion',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ══════════════════════════════════════════
  //  ERROR HANDLER
  // ══════════════════════════════════════════

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map)  return errors.values.first.toString();
          if (errors is List) return errors.first.toString();
        }
        if (data['title'] != null) return data['title'].toString();
      }
      if (data is String && data.isNotEmpty) return data;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.unknown) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}