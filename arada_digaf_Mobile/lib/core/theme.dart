import 'package:flutter/material.dart';

class AppColors {
  // Brand greens & surfaces
  static const Color primaryGreen = Color(0xFF0B6B54);
  static const Color darkGreen = Color(0xFF08493A);
  static const Color mintSurface = Color(0xFFE3F2EC);
  static const Color mintLight = Color(0xFFF0F7F4);
  static const Color background = Color(0xFFF5F8F7);
  static const Color cardSurface = Colors.white;
  static const Color textPrimary = Color(0xFF1B2B27);
  static const Color textSecondary = Color(0xFF6B7E78);
  static const Color border = Color(0xFFD3E4DE);
  static const Color inputBackground = Color(0xFFF9FBFA);

  // Status colors & backgrounds
  static const Color statusSubmitted = Color(0xFF1976D2);
  static const Color statusSubmittedBg = Color(0xFFE3F2FD);

  static const Color statusInProgress = Color(0xFFF57C00);
  static const Color statusInProgressBg = Color(0xFFFFF3E0);

  static const Color statusResolved = Color(0xFF2E7D32);
  static const Color statusResolvedBg = Color(0xFFE8F5E9);

  static const Color statusNotResolved = Color(0xFFD32F2F);
  static const Color statusNotResolvedBg = Color(0xFFFFEBEE);

  static const Color statusReferred = Color(0xFF7B1FA2);
  static const Color statusReferredBg = Color(0xFFF3E5F5);

  // Badges & accents
  static const Color badgeRed = Color(0xFFE53935);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        onPrimary: Colors.white,
        secondary: AppColors.darkGreen,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        surfaceContainerLow: AppColors.cardSurface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null, // Fall back to Android system Ethiopic font
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          height: 1.35,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusNotResolved, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.35,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
        unselectedLabelStyle: TextStyle(fontSize: 12, height: 1.3),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

