
import 'package:flutter/material.dart';

// SiteBench: A builder-friendly, charcoal/slate UI with strong readable type.
const Color kBlack = Color(0xFF0F0F0F);
const Color kDarkGray = Color(0xFF1C1C1E); // Slate background
const Color kGray = Color(0xFF2A2A2D);
const Color kLightGray = Color(0xFF3A3A3E);
const Color kWhite = Color(0xFFFFFFFF);

// Accents
const Color kSteelBlue = Color(0xFF2E86C1);
const Color kSteelBlueDark = Color(0xFF1B5E93);
const Color kAccentGreen = Color(0xFF1E9C55);

// Legacy color aliases (compatibility with older UI code)
// Map previous green/blue palette to SiteBench steel/charcoal palette.
const Color kGreen = kSteelBlue;
const Color kGreenDark = kSteelBlueDark;
const Color kLightGreenBg = Color(0xFF22303A); // subtle slate-blue background
const Color kBlue = kSteelBlue;
const Color kBlueDark = kSteelBlueDark;
const Color kLightBlueBg = Color(0xFF1E2730);

class AppTheme {
  // Light theme (used if system light; still keeps neutral, clean surfaces)
  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: kSteelBlue,
      onPrimary: kWhite,
      secondary: kGray,
      onSecondary: kWhite,
      error: const Color(0xFFB00020),
      onError: kWhite,
      background: const Color(0xFFF4F5F7),
      onBackground: kBlack,
      surface: kWhite,
      onSurface: kBlack,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      textTheme: const TextTheme(
        bodySmall: TextStyle(fontSize: 12, height: 1.35),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        margin: EdgeInsets.all(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const MaterialStatePropertyAll(kSteelBlue),
          foregroundColor: const MaterialStatePropertyAll(kWhite),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const MaterialStatePropertyAll(kSteelBlueDark),
          textStyle: const MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kSteelBlue, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        backgroundColor: scheme.surface,
      ),
      dividerTheme: const DividerThemeData(color: kLightGray),
    );
  }

  // Dark theme (default for SiteBench): charcoal backgrounds, steel accents.
  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: kSteelBlue,
      onPrimary: kWhite,
      secondary: kLightGray,
      onSecondary: kWhite,
      error: const Color(0xFFCF6679),
      onError: kBlack,
      background: kDarkGray,
      onBackground: kWhite,
      surface: kGray,
      onSurface: kWhite,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: kGray,
        foregroundColor: kWhite,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        margin: EdgeInsets.all(12),
        color: kGray,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const MaterialStatePropertyAll(kSteelBlue),
          foregroundColor: const MaterialStatePropertyAll(kWhite),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const MaterialStatePropertyAll(kSteelBlue),
          textStyle: const MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kGray,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kSteelBlue, width: 1.4),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB8BBC1)),
        hintStyle: const TextStyle(color: Color(0xFF9FA3A9)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        backgroundColor: kGray,
      ),
      dividerTheme: const DividerThemeData(color: kLightGray),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kBlack,
        selectedItemColor: kSteelBlue,
        unselectedItemColor: kWhite,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
