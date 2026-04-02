import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimaryGreen = Color(0xFF1A3A2A);
const kAccentGreen = Color(0xFF1D9E75);
const kLightGreen = Color(0xFFEAF3DE);
const kTextGreen = Color(0xFF3B6D11);
const kDarkGreen = Color(0xFF0F6E56);
const kDeepNavy = Color(0xFF0F172A); // Modern slate/navy for gradients

const kBadgeGreenBg = Color(0xFFD4F0E2);
const kBadgeGreenText = Color(0xFF0F6E56);
const kBadgeAmberBg = Color(0xFFFAEEDA);
const kBadgeAmberText = Color(0xFF854F0B);
const kBadgeRedBg = Color(0xFFFCEBEB);
const kBadgeRedText = Color(0xFFA32D2D);
const kBadgeBlueBg = Color(0xFFE6F1FB);
const kBadgeBlueText = Color(0xFF185FA5);

ThemeData appTheme() {
  final base = ThemeData.light();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryGreen,
      primary: kPrimaryGreen,
      secondary: kAccentGreen,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: const Color(0xFF94A3B8),
      selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccentGreen,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kAccentGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
    ),
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)),
      bodySmall: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
      labelSmall: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
    ),
  );
}
