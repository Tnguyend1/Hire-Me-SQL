import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF09090F);
  static const card = Color(0xFF171821);
  static const cardSoft = Color(0xFF1E2030);
  static const border = Color(0xFF312450);
  static const purple = Color(0xFF8B5CF6);
  static const purpleBright = Color(0xFFA855F7);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA1A1AA);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.purpleBright,
      surface: AppColors.card,
    ),
  );
}