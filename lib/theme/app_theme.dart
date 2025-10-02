
import 'package:flutter/material.dart';

const Color kGreen = Color(0xFF2ECC71);
const Color kGreenDark = Color(0xFF1E9C55);
const Color kBlack = Color(0xFF0F0F0F);
const Color kDarkGray = Color(0xFF1C1C1E);
const Color kGray = Color(0xFF2A2A2D);
const Color kLightGray = Color(0xFF3A3A3E);
const Color kWhite = Color(0xFFFFFFFF);
const Color kLightGreenBg = Color(0xFFEFFAF3);
const Color kBlue = Color(0xFF3498DB);
const Color kBlueDark = Color(0xFF1565C0);
const Color kLightBlueBg = Color(0xFFE3F2FD);

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kGreen,
        primary: kGreen,
        onPrimary: kBlack,
        secondary: kGray,
        background: kLightGreenBg,
        surface: kWhite,
      ),
      scaffoldBackgroundColor: kLightGreenBg,
      textTheme: const TextTheme(
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.3),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: kWhite,
        foregroundColor: kBlack,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.all(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(kGreen),
          foregroundColor: MaterialStatePropertyAll(kBlack),
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kWhite,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreenDark, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: kBlack,
        selectedItemColor: kGreen,
        unselectedItemColor: kWhite,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kLightGray,
        labelStyle: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        brightness: Brightness.light,
        secondaryLabelStyle: const TextStyle(color: kWhite),
        padding: const EdgeInsets.all(4),
      ),
      dividerTheme: const DividerThemeData(color: kLightGray),
    );
  }
}
