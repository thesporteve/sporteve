import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safe_fonts.dart';

class AppTheme {
  // Dusk Horizon Color Palette
  static const Color yaleBlue = Color(0xFF083D77);        // Primary - Deep blue
  static const Color beige = Color(0xFFEBEBD3);           // Background - Light beige  
  static const Color naplesYellow = Color(0xFFF4D35E);    // Accent - Warm yellow
  static const Color sandyBrown = Color(0xFFEE964B);      // Secondary - Orange-brown
  static const Color tomato = Color(0xFFF95738);          // Error - Red-orange
  
  // Color Scheme
  static const Color primaryColor = yaleBlue;
  static const Color secondaryColor = sandyBrown;
  static const Color accentColor = naplesYellow;
  static const Color errorColor = tomato;
  static const Color successColor = Color(0xFF059669);    // Emerald green
  static const Color warningColor = naplesYellow;
  
  // Light Theme Colors - Modern & Clean
  static const Color lightBackground = Color(0xFFFAFAFA);      // Clean light gray
  static const Color lightSurface = Color(0xFFFFFFFF);         // Pure white
  static const Color lightOnSurface = Color(0xFF1A202C);       // Soft dark gray
  static const Color lightOnBackground = Color(0xFF2D3748);    // Medium gray
  static const Color lightPrimary = Color(0xFF2563EB);         // Modern blue (lighter than yale)
  static const Color lightSecondary = Color(0xFFEA580C);       // Vibrant orange
  
  // Dark Theme Colors  
  static const Color darkBackground = Color(0xFF0A1929);   // Very dark blue
  static const Color darkSurface = Color(0xFF1E293B);     // Dark slate
  static const Color darkOnSurface = beige;
  static const Color darkOnBackground = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: accentColor,
        error: errorColor,
        background: lightBackground,
        surface: lightSurface,
        onBackground: lightOnBackground,
        onSurface: lightOnSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        outline: Color(0xFFE5E7EB),
        shadow: Color(0xFF000000),
      ),
      textTheme: SafeFonts.interTextTheme().copyWith(
        displayLarge: SafeFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightOnSurface,
        ),
        displayMedium: SafeFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightOnSurface,
        ),
        displaySmall: SafeFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        headlineLarge: SafeFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        headlineMedium: SafeFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        headlineSmall: SafeFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        titleLarge: SafeFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
        titleMedium: SafeFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightOnSurface,
        ),
        titleSmall: SafeFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightOnSurface,
        ),
        bodyLarge: SafeFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightOnSurface,
        ),
        bodyMedium: SafeFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightOnSurface,
        ),
        bodySmall: SafeFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightOnSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: SafeFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: lightPrimary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: secondaryColor,
        secondary: primaryColor,
        tertiary: accentColor,
        error: errorColor,
        background: darkBackground,
        surface: darkSurface,
        onBackground: darkOnBackground,
        onSurface: darkOnSurface,
      ),
      textTheme: SafeFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: SafeFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkOnSurface,
        ),
        displayMedium: SafeFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkOnSurface,
        ),
        displaySmall: SafeFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineLarge: SafeFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineMedium: SafeFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineSmall: SafeFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        titleLarge: SafeFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        titleMedium: SafeFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkOnSurface,
        ),
        titleSmall: SafeFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkOnSurface,
        ),
        bodyLarge: SafeFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkOnSurface,
        ),
        bodyMedium: SafeFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkOnSurface,
        ),
        bodySmall: SafeFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkOnSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: SafeFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sandyBrown,
          foregroundColor: darkBackground,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
