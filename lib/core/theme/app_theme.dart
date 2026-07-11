import 'package:flutter/material.dart';

class AppTheme {
  // Your Custom Brand Color Palette
  static const Color deepNavy = Color(0xFF0A2947);
  static const Color softCream = Color(0xFFF3E4C9);
  static const Color mutedSage = Color(0xFFD3D4C0);
  static const Color warmTerracotta = Color(0xFF8B5E3C);

  // Clean typography colors
  static const Color textDark = Color(0xFF1A2530);
  static const Color textMuted = Color(0xFF627282);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softCream,

      // Setting up the global core color scheme
      colorScheme: const ColorScheme.light(
        primary: deepNavy,
        secondary: warmTerracotta,
        surface: softCream,
        outline: mutedSage,
      ),

      // Modern Minimalist Top App Bar Configuration
      appBarTheme: const AppBarTheme(
        backgroundColor: softCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: deepNavy, size: 22),
        titleTextStyle: TextStyle(
          color: deepNavy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),

      // Consistent Typography Theming
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: deepNavy,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),

      // Ultra-Clean Input Fields for adding grocery items rapidly
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mutedSage, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mutedSage, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepNavy, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Sleek, flat card design for shopping list rows
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.6),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: mutedSage, width: 0.5),
        ),
      ),

      // Custom Checkbox styling matching the theme accent
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return warmTerracotta;
          return Colors.white.withValues(alpha: 0.8);
        }),
        side: const BorderSide(color: mutedSage, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
