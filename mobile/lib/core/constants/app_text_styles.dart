import 'package:flutter/material.dart';
import 'app_colors.dart';

/// CampusPool Typography System
/// Space Grotesk for display/headlines, Space Mono for data/metadata.
class AppTextStyles {
  AppTextStyles._();

  static const _grotesk = 'SpaceGrotesk';
  static const _mono = 'SpaceMono';

  // ── Display ──
  static const displayLg = TextStyle(
    fontFamily: _grotesk, fontSize: 32, fontWeight: FontWeight.w700,
    height: 1.12, color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static const displayMd = TextStyle(
    fontFamily: _grotesk, fontSize: 28, fontWeight: FontWeight.w700,
    height: 1.14, color: AppColors.textPrimary, letterSpacing: -0.3,
  );

  // ── Headline ──
  static const headline = TextStyle(
    fontFamily: _grotesk, fontSize: 22, fontWeight: FontWeight.w600,
    height: 1.27, color: AppColors.textPrimary,
  );

  // ── Title ──
  static const title = TextStyle(
    fontFamily: _grotesk, fontSize: 18, fontWeight: FontWeight.w600,
    height: 1.33, color: AppColors.textPrimary,
  );

  // ── Body ──
  static const bodyLg = TextStyle(
    fontFamily: _grotesk, fontSize: 16, fontWeight: FontWeight.w400,
    height: 1.37, color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _grotesk, fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.43, color: AppColors.textSecondary,
  );

  // ── Labels (Monospace — transit metadata) ──
  static const labelLg = TextStyle(
    fontFamily: _mono, fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.14, color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w400,
    height: 1.17, color: AppColors.textSecondary,
  );

  static const labelSm = TextStyle(
    fontFamily: _mono, fontSize: 10, fontWeight: FontWeight.w400,
    height: 1.2, color: AppColors.textTertiary,
  );

  // ── Utility Styles ──
  static const buttonText = TextStyle(
    fontFamily: _grotesk, fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 1.5, color: AppColors.systemBlack,
  );

  static const transitLabel = TextStyle(
    fontFamily: _mono, fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.2, color: AppColors.systemBlack,
  );
}
