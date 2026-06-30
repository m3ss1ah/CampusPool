import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_avatar.dart';
import '../../../shared/widgets/cp_empty_state.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(title: const Text('INBOX')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signalYellow)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.rejectRed, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load conversations', style: AppTextStyles.body.copyWith(color: AppColors.rejectRed)),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const CpEmptyState(
              title: 'No Conversations Yet',
              subtitle: 'Request a seat to start chatting',
              icon: Icons.chat_bubble_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.screenPaddingH),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
              itemBuilder: (context, i) {
                final c = conversations[i];
                final lastTime = c.lastMessageAt != null
                    ? DateFormat.jm().format(c.lastMessageAt!.toLocal())
                    : '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Stack(
                    children: [
                      CpAvatar(fallbackInitial: c.otherUserName, showPresence: c.unreadCount > 0),
                      if (c.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.signalYellow,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              c.unreadCount.toString(),
                              style: const TextStyle(color: AppColors.systemBlack, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(c.otherUserName, style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600,
                  )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.lastMessage ?? 'No messages yet', style: AppTextStyles.label.copyWith(
                        color: c.unreadCount > 0 ? AppColors.textPrimary : AppColors.textTertiary,
                        fontWeight: c.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      )),
                      const SizedBox(height: 2),
                      if (c.sourceLabel != null && c.destLabel != null)
                        Text('${c.sourceLabel} → ${c.destLabel}', style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                  trailing: Text(lastTime, style: AppTextStyles.labelSm),
                  onTap: () {
                    context.push('/chat/${c.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

