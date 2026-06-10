import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color urucum  = Color(0xFFD94F3D);
const Color fuba    = Color(0xFFF5C842);
const Color couve   = Color(0xFF4A8C3F);
const Color cafe    = Color(0xFF5C3D2E);
const Color bgLight = Color(0xFFFAF7F2);
const Color bgCard  = Color(0xFFFFFFFF);
const Color textDark = Color(0xFF1A1A1A);
const Color textMuted = Color(0xFF757575);

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: urucum,
      primary: urucum,
      secondary: fuba,
      surface: bgLight,
    ),
    scaffoldBackgroundColor: bgLight,
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: bgLight,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: urucum,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: urucum, width: 2),
      ),
    ),
  );
}
