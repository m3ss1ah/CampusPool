import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/commute_model.dart';
import '../domain/seat_request_model.dart';

/// API client for commute and request endpoints.
class CommuteApi {
  final Dio _dio = DioClient().dio;

  // ── Commute Endpoints ──

  Future<CommuteModel> createCommute(Map<String, dynamic> data) async {
    final response = await _dio.post('commutes', data: data);
    return CommuteModel.fromJson(response.data['data']);
  }

  Future<({List<CommuteModel> commutes, Map<String, dynamic> pagination})>
      getNearby({
    required double lat,
    required double lng,
    double radius = 5,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('commutes/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'page': page,
      'limit': limit,
    });

    final data = response.data['data'] as List;
    final commutes = data.map((e) => CommuteModel.fromJson(e)).toList();
    final pagination = Map<String, dynamic>.from(response.data['pagination'] ?? {});

    return (commutes: commutes, pagination: pagination);
  }

  Future<CommuteModel> getById(String id) async {
    final response = await _dio.get('commutes/$id');
    return CommuteModel.fromJson(response.data['data']);
  }

  Future<List<CommuteModel>> getMyCommutes({String status = 'all'}) async {
    final response = await _dio.get('commutes/my', queryParameters: {
      'status': status,
    });
    final data = response.data['data'] as List;
    return data.map((e) => CommuteModel.fromJson(e)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await _dio.patch('commutes/$id/status', data: {'status': status});
  }

  // ── Request Endpoints ──

  Future<SeatRequestModel> createRequest({
    required String commuteId,
    String? message,
  }) async {
    final response = await _dio.post('requests', data: {
      'commute_id': commuteId,
      if (message != null) 'message': message,
    });
    return SeatRequestModel.fromJson(response.data['data']);
  }

  Future<void> respondToRequest(String requestId, String status) async {
    await _dio.patch('requests/$requestId/respond', data: {'status': status});
  }

  Future<void> cancelRequest(String requestId) async {
    await _dio.patch('requests/$requestId/cancel');
  }

  Future<List<SeatRequestModel>> getIncomingRequests() async {
    final response = await _dio.get('requests/incoming');
    final data = response.data['data'] as List;
    return data.map((e) => SeatRequestModel.fromJson(e)).toList();
  }

  Future<List<SeatRequestModel>> getOutgoingRequests() async {
    final response = await _dio.get('requests/outgoing');
    final data = response.data['data'] as List;
    return data.map((e) => SeatRequestModel.fromJson(e)).toList();
  }
}
