import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const String _poppins = 'Poppins';
  static const String _inter = 'Inter';

  // Display (métricas clave)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    color: AppColors.textPrimary,
  );

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  // Body (texto informativo)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Metric (números grandes en sesión activa)
  static const TextStyle metricHuge = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 48,
    color: AppColors.primary,
  );

  static const TextStyle metricLarge = TextStyle(
    fontFamily: _poppins,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    color: AppColors.textPrimary,
  );
}
