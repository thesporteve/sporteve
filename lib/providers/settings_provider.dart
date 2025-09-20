import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _sportsPreferencesKey = 'sports_preferences';
  
  // Available sports categories
  static const List<String> availableSports = [
    'archery',
    'athletics',
    'badminton',
    'basketball',
    'boxing',
    'chess',
    'cricket',
    'discus_throw',
    'diving',
    'football',
    'golf',
    'hammer_throw',
    'handball',
    'high_jump',
    'hockey',
    'javelin_throw',
    'judo',
    'kabaddi',
    'karate',
    'kayaking',
    'kho_kho',
    'long_jump',
    'marathon',
    'pole_vault',
    'race_walking',
    'relay',
    'rowing',
    'rugby',
    'running',
    'sailing',
    'sepak_takraw',
    'shooting',
    'shot_put',
    'skating',
    'skiing',
    'soccer',
    'soft_tennis',
    'sprint',
    'swimming',
    'taekwondo',
    'tennis',
    'triple_jump',
    'volleyball',
    'weightlifting',
    'wrestling',
  ];

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark
  Set<String> _selectedSports = {}; // Empty = show all sports
  bool _isLoaded = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Set<String> get selectedSports => Set.from(_selectedSports);
  bool get isLoaded => _isLoaded;
  bool get showAllSports => _selectedSports.isEmpty;
  
  // Check if a sport should be shown based on user preferences
  bool shouldShowSport(String category) {
    return showAllSports || _selectedSports.contains(category);
  }

  // Initialize settings from local storage
  Future<void> loadSettings() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme preference
      final themeString = prefs.getString(_themeKey) ?? 'dark';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeString,
        orElse: () => ThemeMode.dark,
      );
      
      // Load sports preferences
      final sportsPrefs = prefs.getStringList(_sportsPreferencesKey) ?? [];
      _selectedSports = sportsPrefs.toSet();
      
      _isLoaded = true;
      notifyListeners();
      
      print('Settings loaded: Theme=$themeString, Sports=${_selectedSports.length}');
    } catch (e) {
      print('Error loading settings: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Update theme mode
  Future<void> updateThemeMode(ThemeMode newTheme) async {
    if (_themeMode == newTheme) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newTheme.name);
      
      _themeMode = newTheme;
      notifyListeners();
      
      print('Theme updated to: ${newTheme.name}');
    } catch (e) {
      print('Error updating theme: $e');
    }
  }

  // Update sports preferences
  Future<void> updateSportsPreferences(Set<String> sports) async {
    if (_selectedSports == sports) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_sportsPreferencesKey, sports.toList());
      
      _selectedSports = sports;
      notifyListeners();
      
      print('Sports preferences updated: ${sports.length} sports selected');
    } catch (e) {
      print('Error updating sports preferences: $e');
    }
  }

  // Add a sport to preferences
  Future<void> addSport(String sport) async {
    final newSports = Set<String>.from(_selectedSports)..add(sport);
    await updateSportsPreferences(newSports);
  }

  // Remove a sport from preferences
  Future<void> removeSport(String sport) async {
    final newSports = Set<String>.from(_selectedSports)..remove(sport);
    await updateSportsPreferences(newSports);
  }

  // Toggle a sport in preferences
  Future<void> toggleSport(String sport) async {
    if (_selectedSports.contains(sport)) {
      await removeSport(sport);
    } else {
      await addSport(sport);
    }
  }

  // Clear all sports preferences (show all)
  Future<void> clearSportsPreferences() async {
    await updateSportsPreferences({});
  }

  // Set multiple sports at once
  Future<void> setSportsPreferences(Set<String> sports) async {
    await updateSportsPreferences(sports);
  }

  // Get display name for sport
  static String getSportDisplayName(String sport) {
    return sport
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get available sports with display names
  static List<MapEntry<String, String>> getAvailableSportsWithNames() {
    return availableSports
        .map((sport) => MapEntry(sport, getSportDisplayName(sport)))
        .toList();
  }
}
