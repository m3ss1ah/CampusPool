import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_avatar.dart';
import '../../../shared/widgets/cp_empty_state.dart';

/// Conversations list screen.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data — will be replaced by provider
    final conversations = [
      {'name': 'Alex Rivera', 'last': 'Cool, 2 min away', 'time': '10:32 AM', 'route': 'Campus → Downtown'},
      {'name': 'Priya Sharma', 'last': 'See you at gate 3', 'time': '9:15 AM', 'route': 'Andheri → Powai'},
    ];

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(title: const Text('INBOX')),
      body: conversations.isEmpty
        ? const CpEmptyState(
            title: 'No Conversations Yet',
            subtitle: 'Request a seat to start chatting',
            icon: Icons.chat_bubble_outline,
          )
        : ListView.separated(
            padding: const EdgeInsets.all(AppConstants.screenPaddingH),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSubtle),
            itemBuilder: (context, i) {
              final c = conversations[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CpAvatar(fallbackInitial: c['name']!, showPresence: i == 0),
                title: Text(c['name']!, style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600,
                )),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['last']!, style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text(c['route']!, style: AppTextStyles.labelSm.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
                trailing: Text(c['time']!, style: AppTextStyles.labelSm),
                onTap: () {},
              );
            },
          ),
    );
  }
}
