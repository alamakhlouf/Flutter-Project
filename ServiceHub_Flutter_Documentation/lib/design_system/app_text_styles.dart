import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTextStyles {
  const AppTextStyles._();

  static final textTheme = GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: AppFonts.bold,
      color: AppColors.primary,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: AppFonts.bold,
      color: AppColors.primary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: AppFonts.semiBold,
      color: AppColors.primary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: AppFonts.semiBold,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: AppFonts.regular,
      color: AppColors.textSecondary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: AppFonts.regular,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: AppFonts.regular,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: AppFonts.semiBold,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: AppFonts.medium,
      color: AppColors.textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: AppFonts.medium,
      color: AppColors.textSecondary,
    ),
  );
}
