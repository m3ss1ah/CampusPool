import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/cp_button.dart';
import '../../../shared/widgets/cp_avatar.dart';
import '../../../shared/widgets/cp_transit_badge.dart';

/// Ride detail screen — route, driver info, seat indicator, request CTA.
class CommuteDetailScreen extends StatelessWidget {
  final String commuteId;
  const CommuteDetailScreen({super.key, required this.commuteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('CAMPUSPOOL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time badge
            const CpTransitBadge(text: 'Tomorrow  08:30 AM', isActive: true),
            const SizedBox(height: AppConstants.spacingLg),

            // Route
            Text('North\nCampus', style: AppTextStyles.displayLg.copyWith(fontSize: 36, height: 1.05)),
            const SizedBox(height: 4),
            Text('↓', style: AppTextStyles.displayLg.copyWith(color: AppColors.signalYellow)),
            Text('Downtown', style: AppTextStyles.displayLg.copyWith(fontSize: 36, height: 1.05)),
            const SizedBox(height: AppConstants.spacing3xl),

            // Divider
            Container(height: 2, color: AppColors.borderSubtle),
            const SizedBox(height: AppConstants.spacingXl),

            // Driver badge
            Center(child: CpTransitBadge(text: '⭐ 4.9 Super Driver', isActive: true)),
            const SizedBox(height: AppConstants.spacingLg),

            // Driver card
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                border: Border.all(color: AppColors.borderSubtle, width: 2),
                borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
              ),
              child: Row(
                children: [
                  const CpAvatar(fallbackInitial: 'A', size: 56),
                  const SizedBox(width: AppConstants.spacingLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alex Rivera', style: AppTextStyles.title),
                        Text('Computer Science, \'25', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Metadata row
            Row(
              children: [
                // Vehicle
                Expanded(child: _metaBlock('VEHICLE', 'Yellow Honda Civic')),
                const SizedBox(width: 12),
                Expanded(child: _metaBlock('MUSIC VIBE', 'Indie Rock')),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Seats & Contribution
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      border: Border.all(color: AppColors.borderSubtle, width: 2),
                      borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                    ),
                    child: Column(
                      children: [
                        Text('AVAILABLE SEATS', style: AppTextStyles.labelSm),
                        const SizedBox(height: 8),
                        // Seat dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) => Container(
                            width: 14, height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < 2 ? AppColors.signalYellow : AppColors.surface3,
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                          )),
                        ),
                        const SizedBox(height: 4),
                        Text('2 / 4', style: AppTextStyles.headline),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing4xl),

            CpButton(
              label: 'Request Seat →',
              icon: Icons.airline_seat_recline_normal,
              onPressed: () {
                // TODO: wire to requests provider
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm),
        const SizedBox(height: 4),
        CpTransitBadge(text: value),
      ],
    );
  }
}
