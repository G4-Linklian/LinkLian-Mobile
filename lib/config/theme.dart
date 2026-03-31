import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/sizes.dart';
import '../core/constants/style.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    fontFamily: 'IBMPlexSansThai',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPalette[200]!,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryPalette[200],
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headerSemiBold.copyWith(
        color: AppColors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPalette[200],
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, AppSizes.buttonMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: AppTextStyles.subheadingSemiBold.copyWith(
          color: AppColors.white,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryPalette[200],
        minimumSize: const Size(double.infinity, AppSizes.buttonMd),
        side: BorderSide(color: AppColors.primaryPalette[200]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: AppTextStyles.subheadingSemiBold.copyWith(
          color: AppColors.white,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: AppColors.primaryPalette[400]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: AppColors.primaryPalette[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: AppColors.primaryPalette[200]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: AppColors.dangerPalette[500]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      labelStyle: AppTextStyles.subheadingSemiBold.copyWith(
          color: AppColors.gray,
        ),
      hintStyle: AppTextStyles.subheadingSemiBold.copyWith(
          color: AppColors.gray,
        ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: AppTextStyles.titleBold.copyWith(
          color: AppColors.black,
      ),
      headlineMedium: AppTextStyles.headerSemiBold.copyWith(
          color: AppColors.black,
      ),
      headlineSmall: AppTextStyles.subheadingSemiBold.copyWith(
          color: AppColors.black,
      ),
      bodyLarge: AppTextStyles.paragraphRegular.copyWith(
          color: AppColors.black,
      ),
      bodyMedium: AppTextStyles.descriptionRegular.copyWith(
          color: AppColors.black,
      ),
      bodySmall: AppTextStyles.paragraphRegular.copyWith(
          color: AppColors.gray,
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    fontFamily: 'IBMPlexSansThai',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPalette[200]!,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.gray,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headerSemiBold.copyWith(
          color: AppColors.gray,
      ),
    ),
  );
}
