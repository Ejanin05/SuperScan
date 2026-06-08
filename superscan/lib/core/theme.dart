import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primary = Color(0xFF00C896);      // Emerald green
  static const Color primaryDark = Color(0xFF00A37A);
  static const Color surface = Color(0xFF0F1923);      // Deep navy
  static const Color surfaceCard = Color(0xFF1A2733);
  static const Color surfaceElevated = Color(0xFF243140);
  static const Color onSurface = Color(0xFFE8F4F1);
  static const Color onSurfaceMuted = Color(0xFF8BA5A0);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB347);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: surface,
        secondary: primaryDark,
        surface: surface,
        onSurface: onSurface,
        error: error,
        surfaceContainerHighest: surfaceCard,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceElevated,
        thickness: 1,
      ),
    );
  }
}
