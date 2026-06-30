import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/notification_api.dart';
import '../domain/notification_model.dart';
import '../../../core/network/socket_client.dart';

part 'notification_provider.g.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationsState({
    required this.notifications,
    required this.unreadCount,
  });
}

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  final _api = NotificationApi();

  @override
  FutureOr<NotificationsState> build() async {
    _setupSocket();
    return _fetchNotifications();
  }

  void _setupSocket() {
    final socketClient = ref.read(socketClientProvider);
    
    socketClient.on('notification', (data) {
      final notification = NotificationModel.fromJson(data);
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncData(NotificationsState(
          notifications: [notification, ...currentState.notifications],
          unreadCount: currentState.unreadCount + 1,
        ));
      }
    });

    ref.onDispose(() {
      socketClient.off('notification');
    });
  }

  Future<NotificationsState> _fetchNotifications() async {
    final result = await _api.getNotifications();
    return NotificationsState(
      notifications: result['notifications'] as List<NotificationModel>,
      unreadCount: result['unread_count'] as int,
    );
  }

  Future<void> markAsRead(String id) async {
    await _api.markAsRead(id);
    final currentState = state.value;
    if (currentState != null) {
      final updated = currentState.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      state = AsyncData(NotificationsState(
        notifications: updated,
        unreadCount: (currentState.unreadCount - 1).clamp(0, 999),
      ));
    }
  }

  Future<void> markAllAsRead() async {
    await _api.markAllAsRead();
    final currentState = state.value;
    if (currentState != null) {
      final updated = currentState.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncData(NotificationsState(
        notifications: updated,
        unreadCount: 0,
      ));
    }
  }
}
