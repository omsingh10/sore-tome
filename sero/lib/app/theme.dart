import 'package:flutter/material.dart';

const kPrimaryGreen = Color(0xFF1A3A2A);
const kAccentGreen = Color(0xFF1D9E75);
const kLightGreen = Color(0xFFEAF3DE);
const kTextGreen = Color(0xFF3B6D11);
const kDarkGreen = Color(0xFF0F6E56);

const kBadgeGreenBg = Color(0xFFD4F0E2);
const kBadgeGreenText = Color(0xFF0F6E56);
const kBadgeAmberBg = Color(0xFFFAEEDA);
const kBadgeAmberText = Color(0xFF854F0B);
const kBadgeRedBg = Color(0xFFFCEBEB);
const kBadgeRedText = Color(0xFFA32D2D);
const kBadgeBlueBg = Color(0xFFE6F1FB);
const kBadgeBlueText = Color(0xFF185FA5);

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryGreen,
      primary: kPrimaryGreen,
      secondary: kAccentGreen,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: Color(0xFF8A8A8A),
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: kPrimaryGreen, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
      labelSmall: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
    ),
  );
}
