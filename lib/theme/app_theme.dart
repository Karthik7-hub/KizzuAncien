import 'package:flutter/material.dart';

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
    return _buildTheme(Brightness.dark);
  }

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    // Core Colors
    final Color bgColor = isDark ? black : zinc50; // Off-white for light
    final Color textColor = isDark ? white : zinc950; // Near black for light
    final Color subTextColor = isDark ? zinc500 : zinc500;
    final Color cardColor = isDark ? zinc950 : white; // Pure white cards for light
    final Color borderColor = isDark ? zinc900 : zinc200; // Subtle gray borders

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      primaryColor: textColor,
      canvasColor: bgColor,
      dividerColor: borderColor,
      
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: isDark ? zinc600 : zinc400, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: isDark ? white : black, width: 1),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: isDark ? zinc400 : zinc600, fontSize: 14),
        labelLarge: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelSmall: TextStyle(color: isDark ? zinc600 : zinc400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      
      iconTheme: IconThemeData(color: textColor),
      
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? zinc900 : zinc100,
        disabledColor: isDark ? zinc800 : zinc200,
        selectedColor: isDark ? white : black,
        secondarySelectedColor: isDark ? white : black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: isDark ? zinc400 : zinc600, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: isDark ? black : white, fontSize: 12),
        brightness: brightness,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
