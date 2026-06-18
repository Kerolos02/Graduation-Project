import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String email,
  }) async {
    try {
      final response = await _api.post('/register/send-otp', data: {
        'phone': phone,
        'email': email,
      });
      print('📧 send-otp response: ${response.data}');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ Step 2: verify-otp → بترجع verificationToken
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String otpToken = '',
  }) async {
    try {
      final response = await _api.post('/register/verify-otp', data: {
        'email':   email,
        'otp':     otp,
        'otpCode': otp,
        if (otpToken.isNotEmpty) 'otpToken': otpToken,
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ Step 3: register بالـ driver object + verificationToken + licenseImageBase64
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String verificationToken,
    String otpVerificationCode = '',
    String nationalId = '',
    String licenseNumber = '',
    String licenseType = '',
    String plateNumber = '',
    String truckType = '',
    String capacity = '',
    String licenseImageBase64 = '',
  }) async {
    try {
      final response = await _api.post('/register', data: {
        'role': 1,
        'verificationToken': verificationToken,
        'driver': {
          'fullName':        name,
          'phone':           phone,
          'email':           email,
          'password':        password,
          'confirmPassword': password,
          'nationalId':      nationalId,
          'licenseNumber':   licenseNumber,
          'licenseType':     licenseType,
          'plateNumber':     plateNumber,
          'truckType':       truckType,
          'capacity':        capacity.isNotEmpty
              ? double.tryParse(capacity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0
              : 0,
          'otpVerificationCode': otpVerificationCode,
          if (licenseImageBase64.isNotEmpty)
            'licenseImageBase64': licenseImageBase64,
        },
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ FIX: login بقى يستخدم email بدل phone (الباك LoginDto بيطلب email)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/login', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['token'];
      if (token != null) await ApiService.saveToken(token);
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ FIX: الباك بيطلب email (مش phone)
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _api.post('/register/forgot-password', data: {'email': email});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ FIX: الباك بيطلب email + otp (مش phone)
  // الـ response بيرجع resetToken يُستخدم في reset-password
  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _api.post('/register/verify-reset-otp', data: {
        'email': email, 'otp': otp,
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ✅ FIX: الباك بيطلب resetToken + newPassword (مش phone+otp)
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post('/register/reset-password', data: {
        'resetToken': resetToken, 'newPassword': newPassword,
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }


  // ✅ Trader Register — POST /register
  // TraderSignUpDto: required [fullName, phone, email, nationalId, businessName,
  //                            password, confirmPassword, otpVerificationCode]
  Future<Map<String, dynamic>> registerTrader({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String verificationToken,
    String otpVerificationCode = '',
    String nationalId = '',
    String businessName = '',
    String address = '',
  }) async {
    try {
      final response = await _api.post('/register', data: {
        'role': 2,
        'verificationToken': verificationToken,
        'trader': {
          'fullName':            name,
          'phone':               phone,
          'email':               email,
          'password':            password,
          'confirmPassword':     password,
          'nationalId':          nationalId,
          'businessName':        businessName,
          'address':             address,
          'otpVerificationCode': otpVerificationCode,
        },
      });
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  Future<Map<String, dynamic>> logout() async {
    try {
      await _api.post('/api/auth/logout');
      await ApiService.clearToken();
      return {'success': true};
    } on DioException catch (e) {
      await ApiService.clearToken();
      return {'success': false, 'message': _handleError(e)};
    }
  }

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