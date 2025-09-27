import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sports_service.dart';
import '../models/sport_wiki.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _sportsPreferencesKey = 'sports_preferences';
  
  // Dynamic sports management
  List<SportWiki> _availableSports = [];
  bool _sportsLoaded = false;

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark
  Set<String> _selectedSports = {}; // Empty = show all sports
  bool _isLoaded = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Set<String> get selectedSports => Set.from(_selectedSports);
  bool get isLoaded => _isLoaded;
  bool get showAllSports => _selectedSports.isEmpty;
  List<SportWiki> get availableSports => List.from(_availableSports);
  bool get sportsLoaded => _sportsLoaded;
  
  // Check if a sport should be shown based on user preferences
  bool shouldShowSport(String category) {
    return showAllSports || _selectedSports.contains(category);
  }

  // Load available sports from SportsService
  Future<void> loadSports() async {
    if (_sportsLoaded) return;
    
    try {
      final sports = await SportsService().getActiveSports();
      _availableSports = sports;
      _sportsLoaded = true;
      notifyListeners();
      
      debugPrint('Settings: Loaded ${sports.length} sports dynamically');
    } catch (e) {
      debugPrint('Error loading sports: $e');
      // Use empty list as fallback - app will still work
      _availableSports = [];
      _sportsLoaded = true;
      notifyListeners();
    }
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
      
      // Load dynamic sports as well
      await loadSports();
      
      notifyListeners();
      
      debugPrint('Settings loaded: Theme=$themeString, Sports=${_selectedSports.length}');
    } catch (e) {
      debugPrint('Error loading settings: $e');
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

  // Get display name for sport - uses dynamic data when available
  String getSportDisplayName(String sport) {
    final matches = _availableSports.where((s) => s.name == sport);
    final sportWiki = matches.isEmpty ? null : matches.first;
    return sportWiki?.displayName ?? _formatSportName(sport);
  }

  // Static fallback for display names
  static String _formatSportName(String sport) {
    return sport
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get available sports with display names
  List<MapEntry<String, String>> getAvailableSportsWithNames() {
    return _availableSports
        .map((sport) => MapEntry(sport.name, sport.displayName ?? _formatSportName(sport.name)))
        .toList();
  }

  // Get list of sport names (for backwards compatibility)
  List<String> get availableSportNames => _availableSports.map((s) => s.name).toList();
}
