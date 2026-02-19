// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceElevated = Color(0xFF1E1E1E);
  static const red = Color(0xFFE50914);
  static const redDark = Color(0xFFB20710);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF808080);
  static const greyLight = Color(0xFFAAAAAA);
  static const greyDark = Color(0xFF2A2A2A);
  static const amber = Color(0xFFFFC107);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.red,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: AppColors.greyLight),
          bodyMedium: TextStyle(color: AppColors.grey),
          labelSmall: TextStyle(color: AppColors.grey, fontSize: 10),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      useMaterial3: true,
    );
  }
}
