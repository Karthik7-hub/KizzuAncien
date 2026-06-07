import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color zinc950 = Color(0xFF09090B);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc300 = Color(0xFFD4D4D8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: white,
      cardTheme: CardThemeData(
        color: zinc900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: zinc900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: white, width: 1),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: white,
        onPrimary: black,
        secondary: zinc800,
        onSecondary: white,
        surface: zinc900,
        onSurface: white,
        outline: zinc800,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: white, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: white, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: white),
          bodyMedium: TextStyle(color: zinc400),
          labelLarge: TextStyle(color: zinc500, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
