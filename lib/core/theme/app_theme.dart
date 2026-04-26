import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color warmBackground = Color(0xFFF9F3ED);
  static const Color warmCard = Color(0xFFFFFBF7);
  static const Color espresso = Color(0xFF2C211C);
  static const Color softTaupe = Color(0xFFD8C6B8);
  static const Color dustyRose = Color(0xFFB88D86);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dustyRose,
      brightness: Brightness.light,
    ).copyWith(
      surface: warmCard,
      onSurface: espresso,
      primary: espresso,
      onPrimary: warmCard,
      secondary: dustyRose,
      outline: softTaupe,
    ),
    scaffoldBackgroundColor: warmBackground,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: espresso,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: espresso,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: espresso,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: espresso,
      ),
      bodyLarge: GoogleFonts.inter(color: espresso),
      bodyMedium: GoogleFonts.inter(color: espresso),
      labelLarge: GoogleFonts.inter(
        color: espresso,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: warmBackground,
      foregroundColor: espresso,
      elevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: espresso,
      ),
    ),
    cardTheme: CardThemeData(
      color: warmCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: softTaupe),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: warmCard,
      selectedColor: espresso,
      secondarySelectedColor: espresso,
      disabledColor: softTaupe,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      side: const BorderSide(color: softTaupe),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      labelStyle: GoogleFonts.inter(color: espresso, fontSize: 13),
      secondaryLabelStyle: GoogleFonts.inter(color: warmCard, fontSize: 13),
      brightness: Brightness.light,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: espresso,
        side: const BorderSide(color: softTaupe),
        backgroundColor: warmCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: espresso,
      foregroundColor: warmCard,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dustyRose,
      brightness: Brightness.dark,
    ),
  );
}
