import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Circular avatar with optional online presence dot.
class CpAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final double size;
  final bool showPresence;

  const CpAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackInitial,
    this.size = 48,
    this.showPresence = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface2,
            border: Border.all(color: AppColors.borderSubtle, width: 2),
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initial(),
                  ),
                )
              : _initial(),
        ),
        if (showPresence)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: AppColors.acceptGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface0, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initial() {
    return Center(
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.signalYellow,
        ),
      ),
    );
  }
}
