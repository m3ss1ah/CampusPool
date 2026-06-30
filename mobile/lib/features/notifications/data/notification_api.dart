import 'package:dio/dio.dart';
import '../domain/notification_model.dart';
import '../../../core/network/dio_client.dart';

class NotificationApi {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _dio.get('notifications', queryParameters: {
      'page': page,
      'limit': 30,
    });
    
    final data = response.data['data'] as List;
    final notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
    
    return {
      'notifications': notifications,
      'unread_count': response.data['unread_count'] ?? 0,
      'has_more': response.data['pagination']['has_more'] ?? false,
    };
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('notifications/read-all');
  }
}
