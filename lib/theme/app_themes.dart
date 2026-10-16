import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppThemes {
  static final light = _crear(
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.paleBlue,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.navy,
      onSecondary: AppColors.surface,
      tertiary: const Color(0xFF23653B),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE8F5E9),
      onTertiaryContainer: const Color(0xFF163A20),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textSecondary,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.paleBlue,
    ),
    AppColors.background,
  );

  static final dark = _crear(
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: const Color(0xFFA9C7FF),
      onPrimary: const Color(0xFF083066),
      primaryContainer: const Color(0xFF213A60),
      onPrimaryContainer: const Color(0xFFD6E4FF),
      secondary: const Color(0xFFB8CDFA),
      onSecondary: const Color(0xFF17305A),
      tertiary: const Color(0xFF9ED4AE),
      onTertiary: const Color(0xFF00391B),
      tertiaryContainer: const Color(0xFF163D2B),
      onTertiaryContainer: const Color(0xFFB6EFC5),
      surface: const Color(0xFF182233),
      onSurface: const Color(0xFFE5ECF7),
      onSurfaceVariant: const Color(0xFFB7C5D9),
      outline: const Color(0xFF8C9CB3),
      outlineVariant: const Color(0xFF3B4B63),
      surfaceContainerHighest: const Color(0xFF263449),
    ),
    const Color(0xFF101826),
  );

  static ThemeData _crear(ColorScheme colors, Color background) => ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colors.onSurface,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurfaceVariant,
    ),
  );
}
