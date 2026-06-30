import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';

/// Commute list card — route letter, source→dest, metadata.
class CpCommuteCard extends StatelessWidget {
  final String routeLetter;
  final String sourceLabel;
  final String destLabel;
  final String timeAway;
  final int availableSeats;
  final int totalSeats;
  final String? vehicleType;
  final double progress;
  final VoidCallback? onTap;

  const CpCommuteCard({
    super.key,
    required this.routeLetter,
    required this.sourceLabel,
    required this.destLabel,
    required this.timeAway,
    required this.availableSeats,
    required this.totalSeats,
    this.vehicleType,
    this.progress = 0.5,
    this.onTap,
  });

  IconData get _vehicleIcon {
    switch (vehicleType) {
      case 'car': return Icons.directions_car;
      case 'bike': return Icons.two_wheeler;
      case 'auto': return Icons.electric_rickshaw;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          border: Border.all(color: AppColors.borderSubtle, width: 2),
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Route letter badge
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.signalYellow,
                    borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
                  ),
                  child: Center(
                    child: Text(
                      routeLetter.toUpperCase(),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.systemBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                // Route info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${sourceLabel.toUpperCase()} → ${destLabel.toUpperCase()}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            timeAway,
                            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          const Text('·', style: AppTextStyles.label),
                          const SizedBox(width: 8),
                          Text(
                            '$availableSeats seats',
                            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Icon(_vehicleIcon, size: 14, color: AppColors.textTertiary),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(Icons.arrow_forward, color: AppColors.signalYellow, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            // Reverse Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface0,
                color: progress < 0.2 ? AppColors.rejectRed : AppColors.acceptGreen,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
