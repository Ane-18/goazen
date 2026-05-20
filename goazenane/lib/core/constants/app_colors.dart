import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF242424);
  static const Color surfaceElevated = Color(0xFF2E2E2E);

  // Accents
  static const Color primary = Color(0xFFFF6B2B);
  static const Color primaryLight = Color(0xFFFF8A57);
  static const Color primaryDark = Color(0xFFCC4A12);

  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);

  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF9A9A);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF90CAF9);

  static const Color warning = Color(0xFFFF9800);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF616161);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Cycle phases
  static const Color phaseMenstrual = Color(0xFFEF5350);
  static const Color phaseFolicular = Color(0xFF42A5F5);
  static const Color phaseOvulacion = Color(0xFFAB47BC);
  static const Color phaseLutea = Color(0xFFFF7043);

  // Chart
  static const Color chartLine = Color(0xFFFF6B2B);
  static const Color chartFill = Color(0x33FF6B2B);
  static const Color chartGrid = Color(0xFF2E2E2E);
}
