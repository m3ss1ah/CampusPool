import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_avatar.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final auth = authAsync.value ?? const AuthState();
    final user = auth.user;
    final name = user?['full_name'] ?? 'Rider';

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          children: [
            // Avatar + name
            CpAvatar(fallbackInitial: name, size: 80),
            const SizedBox(height: AppConstants.spacingLg),
            Text(name, style: AppTextStyles.headline),
            Text(
              user?['email'] ?? '',
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppConstants.spacingXl),

            // Stats row
            Row(
              children: [
                _statCard('RIDES\nOFFERED', '${user?['total_rides_offered'] ?? 0}'),
                const SizedBox(width: 12),
                _statCard('RIDES\nJOINED', '${user?['total_rides_joined'] ?? 0}'),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXl),

            // Info tiles
            _infoTile(Icons.school, 'COLLEGE', user?['college'] ?? 'Not set'),
            _infoTile(Icons.phone, 'PHONE', user?['phone'] ?? 'Not set'),
            _infoTile(
              Icons.directions_car,
              'VEHICLE',
              user?['has_vehicle'] == true
                ? (user?['vehicle_type'] ?? 'Yes').toString().toUpperCase()
                : 'None',
            ),
            const SizedBox(height: AppConstants.spacing3xl),

            // Actions
            CpButton(
              label: 'Edit Profile',
              icon: Icons.edit,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile coming soon!', style: AppTextStyles.body)),
                );
              },
            ),
            const SizedBox(height: AppConstants.spacingLg),
            CpButton(
              label: 'Log Out',
              variant: CpButtonVariant.outlined,
              icon: Icons.logout,
              onPressed: () {
                ref.read(authNotifierProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          border: Border.all(color: AppColors.borderSubtle, width: 2),
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.displayMd.copyWith(color: AppColors.signalYellow)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSm, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSm),
              Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
