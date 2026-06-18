import 'package:dio/dio.dart';

class GeocodingService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'TruckMate/1.0'},
  ));

  // cache عشان مين نبعت نفس الـ request أكتر من مرة
  static final Map<String, List<double>?> _cache = {
    'Fayoum': [29.3084, 30.8428],
    'الفيوم': [29.3084, 30.8428],
    'fayoum': [29.3084, 30.8428],
    'Port Said': [31.2653, 32.3019],
    'بورسعيد': [31.2653, 32.3019],
    'port said': [31.2653, 32.3019],
  };

  /// بيحول اسم مكان لـ [lat, lng] — بيرجع null لو مش لاقيه
  static Future<List<double>?> getCoordinates(String place) async {
    if (place.isEmpty) return null;
    final trimmedPlace = place.trim();
    if (_cache.containsKey(trimmedPlace)) return _cache[trimmedPlace];

    try {
      // بنضيف "Egypt" عشان النتايج تبقى أدق
      final query = '$place, Egypt';
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
      );

      final data = response.data as List;
      if (data.isEmpty) {
        _cache[place] = null;
        return null;
      }

      final lat = double.tryParse(data[0]['lat'] ?? '');
      final lng = double.tryParse(data[0]['lon'] ?? '');

      if (lat == null || lng == null) {
        _cache[place] = null;
        return null;
      }

      final result = [lat, lng];
      _cache[place] = result;
      return result;
    } catch (e) {
      _cache[place] = null;
      return null;
    }
  }
}