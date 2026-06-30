import 'package:dio/dio.dart';

/// Uses Nominatim (OpenStreetMap) for free reverse geocoding.
/// Rate limited to 1 req/sec — callers must debounce.
class CoordinateUtils {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await Dio().get(_nominatimUrl, queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'zoom': 16,
        'addressdetails': 1,
      }, options: Options(headers: {
        'User-Agent': 'CampusPool/1.0 (campuspool@college.edu)',
      }));

      final address = response.data['address'];
      if (address == null) return 'Selected Location';

      final parts = <String>[];

      final suburb = address['suburb'] ??
          address['neighbourhood'] ??
          address['residential'];
      final city = address['city'] ??
          address['town'] ??
          address['village'];
      final state = address['state'];

      if (suburb != null) parts.add(suburb);
      if (city != null) parts.add(city);
      if (state != null) parts.add(state);

      return parts.isNotEmpty ? parts.join(', ') : 'Selected Location';
    } catch (_) {
      return 'Selected Location';
    }
  }
}
