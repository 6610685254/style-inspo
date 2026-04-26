import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color warmBackground = Color(0xFFF9F3ED);
  static const Color warmCard = Color(0xFFFFFBF7);
  static const Color espresso = Color(0xFF2C211C);
  static const Color softTaupe = Color(0xFFD8C6B8);
  static const Color dustyRose = Color(0xFFB88D86);
  static const Color darkEspresso = Color(0xFF1E1714);
  static const Color darkMocha = Color(0xFF2A211D);
  static const Color warmIvory = Color(0xFFF2E7DD);
  static const Color mutedTaupe = Color(0xFF6F5A4D);

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
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,
      shadowColor: Colors.transparent,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: espresso,
      ),
      iconTheme: const IconThemeData(
        color: espresso,
        size: 22,
      ),
      actionsIconTheme: const IconThemeData(
        color: espresso,
        size: 22,
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: warmCard,
      scrimColor: Color(0x6B2C211C),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: warmCard,
      selectedItemColor: espresso,
      unselectedItemColor: espresso.withOpacity(0.55),
      selectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
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
    ).copyWith(
      surface: darkMocha,
      onSurface: warmIvory,
      primary: warmIvory,
      onPrimary: darkEspresso,
      outline: mutedTaupe,
    ),
    scaffoldBackgroundColor: darkEspresso,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: warmIvory,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: warmIvory,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: warmIvory,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: warmIvory,
      ),
      bodyLarge: GoogleFonts.inter(color: warmIvory.withOpacity(0.92)),
      bodyMedium: GoogleFonts.inter(color: warmIvory.withOpacity(0.9)),
      labelLarge: GoogleFonts.inter(
        color: warmIvory,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: darkEspresso,
      foregroundColor: warmIvory,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,
      shadowColor: Colors.transparent,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: warmIvory,
      ),
      iconTheme: const IconThemeData(
        color: warmIvory,
        size: 22,
      ),
      actionsIconTheme: const IconThemeData(
        color: warmIvory,
        size: 22,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: mutedTaupe.withOpacity(0.45),
      thickness: 1,
      space: 1,
    ),
  );
}
