import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class OsrmService {
  final Dio _dio = Dio();

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.get(
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
        },
      );

      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) {
            // GeoJSON coordinates are [longitude, latitude]
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('OSRM Routing Error: $e');
      return [];
    }
  }
}
