import 'package:dio/dio.dart';
import 'api_service.dart';

class DriverService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getHome() async {
    try {
      final response = await _api.get('/api/driver/home');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updateStatus({required String status}) async {
    try {
      final response = await _api.patch('/api/driver/status', data: {'status': status});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getCurrentOffers() async {
    try {
      final response = await _api.get('/api/driver/offers/current');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> acceptOffer({required String offerId}) async {
    try {
      final response = await _api.post('/api/driver/offers/$offerId/accept');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> declineOffer({required String offerId}) async {
    try {
      final response = await _api.post('/api/driver/offers/$offerId/decline');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getIncomingTrips() async {
    try {
      final response = await _api.get('/api/driver/incoming-trips');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> startTrip({required String tripId}) async {
    try {
      final response = await _api.post('/api/driver/trips/$tripId/start');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> arrivePickup({required String tripId}) async {
    try {
      final response = await _api.post('/api/driver/trips/$tripId/arrive-pickup');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> confirmPickup({required String tripId}) async {
    try {
      final response = await _api.post('/api/driver/trips/$tripId/confirm-pickup');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> startDelivery({required String tripId}) async {
    try {
      final response = await _api.post('/api/driver/trips/$tripId/start-delivery');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> markDelivered({required String tripId}) async {
    try {
      final response = await _api.post('/api/driver/trips/$tripId/mark-delivered');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getTripDetails({required String tripId}) async {
    try {
      final response = await _api.get('/api/driver/trips/$tripId/details');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getRecentTrips() async {
    try {
      final response = await _api.get('/api/driver/trips/recent');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getAvailableRequests({
    int page = 1, int pageSize = 20, String sortBy = 'posted_desc',
  }) async {
    try {
      final response = await _api.get('/api/driver/trips/available-requests',
          queryParams: {'page': page, 'pageSize': pageSize, 'sortBy': sortBy});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getRequestDetails({required String requestId}) async {
    try {
      final response = await _api.get('/api/driver/trips/requests/$requestId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> acceptRequest({required String requestId}) async {
    try {
      final response = await _api.post('/api/driver/trips/requests/$requestId/accept');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> rejectRequest({
    required String requestId, String? reason,
  }) async {
    try {
      final response = await _api.post(
        '/api/driver/trips/requests/$requestId/reject',
        data: reason != null ? {'reason': reason} : {},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getMyTrips({
    String status = 'all', int page = 1, int pageSize = 10,
  }) async {
    try {
      final response = await _api.get('/api/driver/trips/my-trips',
          queryParams: {'status': status, 'page': page, 'pageSize': pageSize});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getWalletScreen({
    String filter = 'all', int page = 1, int pageSize = 10,
  }) async {
    try {
      final response = await _api.get('/api/driver/wallet/screen',
          queryParams: {'filter': filter, 'page': page, 'pageSize': pageSize});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getWalletSummary() async {
    try {
      final response = await _api.get('/api/driver/wallet/summary');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get('/api/driver/settings/profile');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword, required String newPassword,
  }) async {
    try {
      final response = await _api.patch('/api/driver/settings/change-password',
          data: {'oldPassword': oldPassword, 'newPassword': newPassword});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _api.get('/api/driver/settings/notifications');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _api.patch('/api/driver/settings/notifications', data: settings);
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  Future<Map<String, dynamic>> getDriverReviews({required String driverId}) async {
  try {
    final response = await _api.get('/api/review/driver/$driverId');
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'message': _handleError(e)};
  }
}

  // ✅ بيعرض رسالة الباك الحقيقية بالظبط
  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map) return errors.values.first.toString();
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