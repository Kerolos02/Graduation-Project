import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  static const String baseUrl = 'http://truckmateapi.runasp.net';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // بيطبع كل request/response في الـ console (مفيد جداً في التطوير)
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
    ));

    // بيضيف الـ Token تلقائياً في كل request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // ── GET ──
  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    return await _dio.get(endpoint, queryParameters: queryParams);
  }

  // ── POST ──
  Future<Response> post(String endpoint,
      {Map<String, dynamic>? data}) async {
    return await _dio.post(endpoint, data: data);
  }

  // ── PUT ──
  Future<Response> put(String endpoint,
      {Map<String, dynamic>? data}) async {
    return await _dio.put(endpoint, data: data);
  }

  // ── PATCH ──
  Future<Response> patch(String endpoint,
      {Map<String, dynamic>? data}) async {
    return await _dio.patch(endpoint, data: data);
  }

  // ── DELETE ──
  Future<Response> delete(String endpoint, {Map<String, dynamic>? data}) async {
  return await _dio.delete(endpoint, data: data);
}

  // ── حفظ التوكن بعد اللوجين ──
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ── مسح التوكن عند اللوجاوت ──
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ── جيب التوكن ──
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}