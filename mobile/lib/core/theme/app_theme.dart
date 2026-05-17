import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// CampusPool dark theme — neo-brutalist transit aesthetic.
ThemeData campusPoolTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface0,
    fontFamily: 'SpaceGrotesk',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.signalYellow,
      onPrimary: AppColors.systemBlack,
      secondary: AppColors.surface2,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface1,
      onSurface: AppColors.textPrimary,
      error: AppColors.rejectRed,
      onError: AppColors.pureWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface0,
      selectedItemColor: AppColors.signalYellow,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'SpaceMono', fontSize: 10, fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'SpaceMono', fontSize: 10,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        borderSide: const BorderSide(color: AppColors.signalYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        borderSide: const BorderSide(color: AppColors.rejectRed, width: 2),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'SpaceMono', fontSize: 12, color: AppColors.textTertiary,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'SpaceMono', fontSize: 14, color: AppColors.textTertiary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.signalYellow,
        foregroundColor: AppColors.systemBlack,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        ),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk', fontSize: 14,
          fontWeight: FontWeight.w600, letterSpacing: 1.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        side: const BorderSide(color: AppColors.borderSubtle, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
        ),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk', fontSize: 14,
          fontWeight: FontWeight.w600, letterSpacing: 1.5,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle, thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: const TextStyle(
        fontFamily: 'SpaceGrotesk', fontSize: 14, color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusBrutalist),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
