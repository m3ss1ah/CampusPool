import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';

/// Transit-style badge: [ROUTE] [LIVE] [2 SEATS]
class CpTransitBadge extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color? customColor;

  const CpTransitBadge({
    super.key,
    required this.text,
    this.isActive = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = customColor ?? (isActive ? AppColors.signalYellow : AppColors.surface2);
    final textColor = isActive ? AppColors.systemBlack : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.transitLabel.copyWith(color: textColor),
      ),
    );
  }
}
