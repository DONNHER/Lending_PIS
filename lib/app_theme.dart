import 'package:flutter/material.dart';

class AppTheme {
  // 🔶 Primary colors (ORANGE THEME)
  static const primary = Color(0xFFFF6F00); // Main orange
  static const secondary = Color(0xFFFFA726); // Lighter orange
  static const surface = Color(0xFFF7F7F7); // Soft gray background
  static const surfaceCard = Colors.white; // Clean cards

  // 📝 Text colors
  static const textDark = Color(0xFF212121);
  static const textMuted = Color(0xFF757575);

  // ⚠️ Status colors (kept for meaning)
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: surface,

      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
      ),

      // 🧾 INPUT FIELDS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.2)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.2)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),

        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),

      // 🔘 ELEVATED BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // 🔲 OUTLINED BUTTON
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.3)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // 🍞 SNACKBAR
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(color: primary, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textMuted);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withOpacity(0.15),
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: const IconThemeData(color: textMuted),
        selectedLabelTextStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(color: textMuted),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: textDark,
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    );
  }
}
