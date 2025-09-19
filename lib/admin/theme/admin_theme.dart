import 'package:flutter/material.dart';

class AdminTheme {
  // Color scheme for admin app
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFF9800);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(backgroundColor),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        }),
        dividerThickness: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: IconThemeData(color: primaryColor),
        selectedLabelTextStyle: TextStyle(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: Colors.grey),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2D2D2D),
      ),
    );
  }

  // Helper colors for status indicators
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'active':
      case 'published':
        return successColor;
      case 'upcoming':
      case 'pending':
        return warningColor;
      case 'completed':
      case 'finished':
        return Colors.grey;
      case 'cancelled':
      case 'error':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  // Common text styles for admin interface
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  // Additional text styles for sports wiki
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}
