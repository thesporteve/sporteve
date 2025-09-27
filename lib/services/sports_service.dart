import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sport_wiki.dart';
import '../utils/sports_icons.dart';
import '../providers/settings_provider.dart';
import '../admin/services/csv_service.dart';

/// Service for dynamic sports management with fallback mechanisms
/// 
/// This service provides a unified interface for sports data that can source from:
/// 1. Dynamic sports_wiki collection (preferred)
/// 2. Static hardcoded lists (fallback)
/// 3. Smart mappings between different naming conventions
class SportsService {
  static final SportsService _instance = SportsService._internal();
  factory SportsService() => _instance;
  SportsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for performance
  static List<SportWiki>? _cachedActiveSports;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get all active sports for dropdowns and forms
  /// 
  /// Returns sports from sports_wiki collection, sorted by sortOrder and name.
  /// Falls back to static data if collection is empty or unavailable.
  Future<List<SportWiki>> getActiveSports() async {
    try {
      // Check cache first
      if (_cachedActiveSports != null && _lastCacheUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
        if (timeSinceUpdate < _cacheExpiry) {
          return _cachedActiveSports!;
        }
      }

      // Fetch from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('sports_wiki')
          .where('is_active', isEqualTo: true)
          .orderBy('sort_order')
          .orderBy('name')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final sports = snapshot.docs.map((doc) => SportWiki.fromFirestore(doc)).toList();
        
        // Update cache
        _cachedActiveSports = sports;
        _lastCacheUpdate = DateTime.now();
        
        return sports;
      } else {
        // Fallback to static data if no active sports in Firestore
        return _generateFallbackSports();
      }
    } catch (e) {
      print('Error fetching active sports from Firestore: $e');
      // Fallback to static data on error
      return _generateFallbackSports();
    }
  }

  /// Get sport by name with smart matching and fallback
  /// 
  /// Tries multiple name formats:
  /// 1. Exact match with sports_wiki.name
  /// 2. Match with sports_wiki.display_name
  /// 3. Case-insensitive matching
  /// 4. Fallback to static sport creation
  Future<SportWiki?> getSportByName(String name) async {
    if (name.trim().isEmpty) return null;

    try {
      final activeSports = await getActiveSports();
      
      // Try exact name match
      final exactMatches = activeSports
          .where((s) => s.name.toLowerCase() == name.toLowerCase());
      SportWiki? sport = exactMatches.isEmpty ? null : exactMatches.first;
      
      if (sport != null) return sport;

      // Try display name match
      final displayMatches = activeSports
          .where((s) => s.displayName?.toLowerCase() == name.toLowerCase());
      sport = displayMatches.isEmpty ? null : displayMatches.first;
      
      if (sport != null) return sport;

      // Try partial/fuzzy matching for common variations
      final normalizedName = _normalizeSportName(name);
      final fuzzyMatches = activeSports
          .where((s) => _normalizeSportName(s.name) == normalizedName ||
                      (s.displayName != null && _normalizeSportName(s.displayName!) == normalizedName));
      sport = fuzzyMatches.isEmpty ? null : fuzzyMatches.first;
      
      if (sport != null) return sport;

      // Create fallback sport if not found
      return _createFallbackSport(name);
    } catch (e) {
      print('Error getting sport by name: $e');
      return _createFallbackSport(name);
    }
  }

  /// Get sport icon with smart fallback
  /// 
  /// Priority order:
  /// 1. sports_wiki.icon_name (Material icon name)
  /// 2. Static SportsIcons mapping
  /// 3. Generic sports icon
  static IconData getSportIcon(String sportName) {
    // This will be enhanced once we have the sport object
    // For now, use the static mapping as fallback
    return SportsIcons.getSportsIcon(sportName);
  }

  /// Get sport icon from SportWiki object
  static IconData getSportIconFromWiki(SportWiki sport) {
    // Try icon from sports_wiki first
    if (sport.iconName != null && sport.iconName!.isNotEmpty) {
      final iconData = _getIconByName(sport.iconName!);
      if (iconData != null) return iconData;
    }

    // Fallback to static mapping
    return getSportIcon(sport.name);
  }

  /// Get sport display color
  static Color getSportColor(SportWiki sport) {
    if (sport.primaryColor != null && sport.primaryColor!.isNotEmpty) {
      try {
        // Parse hex color (e.g., "#FF5722" or "FF5722")
        String colorHex = sport.primaryColor!.replaceFirst('#', '');
        if (colorHex.length == 6) {
          return Color(int.parse('FF$colorHex', radix: 16));
        }
      } catch (e) {
        print('Error parsing sport color: ${sport.primaryColor}');
      }
    }
    
    // Default sport color
    return const Color(0xFF2196F3);
  }

  /// Get sports for dropdown with proper display names
  Future<List<DropdownMenuItem<String>>> getSportsDropdownItems() async {
    final sports = await getActiveSports();
    
    return sports.map((sport) {
      final displayName = sport.displayName ?? sport.name;
      return DropdownMenuItem<String>(
        value: sport.name,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getSportIconFromWiki(sport),
              size: 16,
              color: getSportColor(sport),
            ),
            const SizedBox(width: 8),
            Text(displayName),
          ],
        ),
      );
    }).toList();
  }

  /// Clear cache to force refresh
  static void clearCache() {
    _cachedActiveSports = null;
    _lastCacheUpdate = null;
  }

  /// Normalize sport name for fuzzy matching
  String _normalizeSportName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');
  }

  /// Create fallback sport when not found in database
  SportWiki _createFallbackSport(String name) {
    // Try to categorize sport based on common patterns
    String category = 'Individual Sport';
    String type = 'Outdoor';
    
    // Simple heuristics for categorization
    final lowerName = name.toLowerCase();
    if (lowerName.contains('team') || 
        ['football', 'basketball', 'cricket', 'volleyball', 'hockey'].any((s) => lowerName.contains(s))) {
      category = 'Team Sport';
    }
    
    if (['chess', 'boxing', 'swimming', 'gymnastics'].any((s) => lowerName.contains(s))) {
      type = 'Indoor';
    } else if (['swimming', 'diving', 'water'].any((s) => lowerName.contains(s))) {
      type = 'Water';
    } else if (['boxing', 'wrestling', 'martial', 'fight'].any((s) => lowerName.contains(s))) {
      type = 'Combat';
    }

    return SportWiki(
      id: 'fallback_${name.hashCode}',
      name: name,
      category: category,
      type: type,
      description: 'Sport information not yet available',
      displayName: _capitalizeWords(name),
      isActive: true,
      sortOrder: 9999, // Low priority for fallback sports
      createdAt: DateTime.now(),
    );
  }

  /// Generate fallback sports from static lists
  List<SportWiki> _generateFallbackSports() {
    final List<SportWiki> fallbackSports = [];
    
    // Convert from SettingsProvider.availableSports (snake_case)
    int sortOrder = 100;
    for (final sport in SettingsProvider.availableSports) {
      fallbackSports.add(SportWiki(
        id: 'static_$sport',
        name: sport,
        category: 'Individual Sport', // Default
        type: 'Outdoor', // Default
        description: 'Generated from static data',
        displayName: _capitalizeWords(sport.replaceAll('_', ' ')),
        isActive: true,
        sortOrder: sortOrder++,
        createdAt: DateTime.now(),
      ));
    }

    // Also add from CSV service supported sports
    for (final sport in CsvService.supportedSports) {
      // Avoid duplicates
      if (!fallbackSports.any((s) => s.displayName?.toLowerCase() == sport.toLowerCase())) {
        fallbackSports.add(SportWiki(
          id: 'csv_${sport.hashCode}',
          name: sport.toLowerCase().replaceAll(' ', '_'),
          category: _guessSportCategory(sport),
          type: _guessSportType(sport),
          description: 'Generated from CSV supported data',
          displayName: sport,
          isActive: true,
          sortOrder: sortOrder++,
          createdAt: DateTime.now(),
        ));
      }
    }

    // Sort by sort order and name
    fallbackSports.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      return orderCompare != 0 ? orderCompare : a.name.compareTo(b.name);
    });

    return fallbackSports;
  }

  /// Guess sport category from name
  String _guessSportCategory(String sportName) {
    final lower = sportName.toLowerCase();
    if (['football', 'basketball', 'cricket', 'volleyball', 'hockey', 'rugby', 'baseball'].any((s) => lower.contains(s))) {
      return 'Team Sport';
    }
    return 'Individual Sport';
  }

  /// Guess sport type from name
  String _guessSportType(String sportName) {
    final lower = sportName.toLowerCase();
    if (['swimming', 'diving', 'sailing', 'rowing'].any((s) => lower.contains(s))) {
      return 'Water';
    } else if (['boxing', 'wrestling', 'judo', 'karate', 'taekwondo', 'fencing'].any((s) => lower.contains(s))) {
      return 'Combat';
    } else if (['chess', 'figure skating', 'gymnastics', 'weightlifting'].any((s) => lower.contains(s))) {
      return 'Indoor';
    }
    return 'Outdoor';
  }

  /// Capitalize words helper
  String _capitalizeWords(String text) {
    return text.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
    ).join(' ');
  }

  /// Get Material icon by name string
  static IconData? _getIconByName(String iconName) {
    // This is a simplified mapping - in a production app, you'd want a more comprehensive mapping
    final iconMap = <String, IconData>{
      'sports': Icons.sports,
      'sports_soccer': Icons.sports_soccer,
      'sports_football': Icons.sports_soccer,
      'sports_cricket': Icons.sports_cricket,
      'sports_basketball': Icons.sports_basketball,
      'sports_tennis': Icons.sports_tennis,
      'sports_volleyball': Icons.sports_volleyball,
      'sports_hockey': Icons.sports_hockey,
      'sports_rugby': Icons.sports_rugby,
      'sports_baseball': Icons.sports_baseball,
      'sports_handball': Icons.sports_handball,
      'sports_golf': Icons.sports_golf,
      'sports_mma': Icons.sports_mma,
      'sports_kabaddi': Icons.sports_kabaddi,
      'sports_motorsports': Icons.sports_motorsports,
      'sports_esports': Icons.sports_esports,
      'pool': Icons.pool,
      'directions_run': Icons.directions_run,
      'directions_walk': Icons.directions_walk,
      'fitness_center': Icons.fitness_center,
      'gps_fixed': Icons.gps_fixed,
      'self_improvement': Icons.self_improvement,
    };
    
    return iconMap[iconName];
  }
}

