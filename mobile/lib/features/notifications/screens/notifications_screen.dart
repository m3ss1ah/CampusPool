import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_empty_state.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.signalYellow),
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signalYellow)),
        error: (e, _) => Center(child: Text('Failed to load notifications', style: AppTextStyles.body.copyWith(color: AppColors.rejectRed))),
        data: (state) {
          if (state.notifications.isEmpty) {
            return const CpEmptyState(
              title: 'All caught up',
              subtitle: 'You have no notifications',
              icon: Icons.notifications_none,
            );
          }

          return ListView.builder(
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final n = state.notifications[index];
              return ListTile(
                tileColor: n.isRead ? null : AppColors.surface1,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: _getColorForType(n.type).withValues(alpha: 0.2),
                  child: Icon(_getIconForType(n.type), color: _getColorForType(n.type)),
                ),
                title: Text(n.title, style: AppTextStyles.body.copyWith(
                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                )),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.body != null) ...[
                      const SizedBox(height: 4),
                      Text(n.body!, style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
                    ],
                    const SizedBox(height: 4),
                    Text(timeago.format(n.createdAt), style: AppTextStyles.labelSm),
                  ],
                ),
                onTap: () {
                  if (!n.isRead) {
                    ref.read(notificationNotifierProvider.notifier).markAsRead(n.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('accepted')) return Icons.check_circle;
    if (type.contains('rejected')) return Icons.cancel;
    if (type.contains('request')) return Icons.person_add;
    return Icons.notifications;
  }

  Color _getColorForType(String type) {
    if (type.contains('accepted')) return AppColors.acceptGreen;
    if (type.contains('rejected')) return AppColors.rejectRed;
    return AppColors.signalYellow;
  }
}
