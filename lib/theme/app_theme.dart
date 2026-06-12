import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Monochrome Scale (Zinc/Slate)
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Single Accent Color (Amber for Streaks/Points)
  static const Color accent = Color(0xFFFBBF24); 

  static const double borderRadius = 16.0;
  static const double padding = 16.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: white,
      canvasColor: black,
      
      cardTheme: CardThemeData(
        color: zinc950,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: zinc900, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: zinc950,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: zinc600, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: zinc900),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: zinc900),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: zinc800, width: 1.5),
        ),
      ),

      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displayMedium: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displaySmall: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: white, fontSize: 16),
          bodyMedium: TextStyle(color: zinc400, fontSize: 14),
          labelLarge: TextStyle(color: zinc500, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          labelSmall: TextStyle(color: zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
