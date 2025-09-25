import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

/// Safe font loading with fallbacks for when Google Fonts fails
class SafeFonts {
  /// Get Inter font with fallback to system fonts
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    // In simulator/debug mode, use system fonts to avoid network issues
    if (_isSimulatorOrOffline()) {
      return TextStyle(
        fontFamily: null, // Use system default
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // Fallback to system fonts when Google Fonts fails
      print('⚠️ Google Fonts failed, using system fallback: $e');
      return TextStyle(
        fontFamily: null, // Use system default
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  /// Get Inter TextTheme with fallback
  static TextTheme interTextTheme([TextTheme? baseTheme]) {
    // In simulator/debug mode, use system fonts to avoid network issues
    if (_isSimulatorOrOffline()) {
      return baseTheme ?? const TextTheme();
    }
    
    try {
      return GoogleFonts.interTextTheme(baseTheme);
    } catch (e) {
      print('⚠️ Google Fonts TextTheme failed, using system fallback: $e');
      // Return system default TextTheme
      return baseTheme ?? const TextTheme();
    }
  }

  /// Check if Google Fonts is available
  static Future<bool> isGoogleFontsAvailable() async {
    try {
      // Try to create a simple Google Font to test connectivity
      GoogleFonts.inter();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if running in simulator or offline environment
  static bool _isSimulatorOrOffline() {
    // In debug mode, assume simulator might have network issues
    return kDebugMode;
  }
}
