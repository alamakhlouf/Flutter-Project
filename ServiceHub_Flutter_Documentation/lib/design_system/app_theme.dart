import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.surface,
          secondary: AppColors.secondary,
          onSecondary: Colors.black,
          tertiary: AppColors.tertiary,
          onTertiary: Colors.black,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceTint: Colors.transparent,
        ),
    fontFamily: AppFonts.family,
    textTheme: AppTextStyles.textTheme,
    scaffoldBackgroundColor: AppColors.neutral,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.neutral,
      foregroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x33163B60),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
      ),
      labelStyle: AppTextStyles.textTheme.labelMedium,
      floatingLabelStyle: AppTextStyles.textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
      ),
      errorStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
        color: AppColors.error,
      ),
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: AppFonts.semiBold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary),
        textStyle: AppTextStyles.textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.textTheme.labelLarge,
      ),
    ),
  );
}
