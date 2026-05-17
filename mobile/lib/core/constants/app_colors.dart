import 'dart:ui';

/// CampusPool Color System
/// Transit-inspired dark theme with Signal Yellow (#FFE000) as signature.
class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const signalYellow = Color(0xFFFFE000);
  static const carbonBlack = Color(0xFF0A0A0A);
  static const pureWhite = Color(0xFFFFFFFF);
  static const systemBlack = Color(0xFF000000);

  // ── Surface System (Dark Theme) ──
  static const surface0 = Color(0xFF0A0A0A); // App background
  static const surface1 = Color(0xFF141414); // Card bg, bottom sheet
  static const surface2 = Color(0xFF1E1E1E); // Elevated cards, inputs
  static const surface3 = Color(0xFF2A2A2A); // Hover/pressed states

  // ── Borders ──
  static const borderSubtle = Color(0xFF333333);
  static const borderStrong = Color(0xFF555555);

  // ── Text ──
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0A0);
  static const textTertiary = Color(0xFF666666);

  // ── Semantic / Status ──
  static const statusOpen = Color(0xFFFFE000);
  static const statusFull = Color(0xFFFF6B35);
  static const statusOngoing = Color(0xFF00D4AA);
  static const statusCompleted = Color(0xFF888888);
  static const statusCancelled = Color(0xFFFF3B3B);

  // ── Actions ──
  static const acceptGreen = Color(0xFF00D4AA);
  static const rejectRed = Color(0xFFFF3B3B);

  // ── Map ──
  static const mapGridYellow = Color(0x33FFE000); // 20% opacity yellow
  static const mapRouteGlow = Color(0xCCFFE000);  // 80% opacity yellow
}
