import 'package:flutter/material.dart';

class SportsIcons {
  static const Map<String, IconData> _sportsIconMap = {
    // Ball Sports
    'cricket': Icons.sports_cricket,
    'football': Icons.sports_soccer,
    'soccer': Icons.sports_soccer,
    'hockey': Icons.sports_hockey,
    'basketball': Icons.sports_basketball,
    'volleyball': Icons.sports_volleyball,
    'rugby': Icons.sports_rugby,
    'baseball': Icons.sports_baseball,
    'tennis': Icons.sports_tennis,
    'table_tennis': Icons.sports_tennis,
    'squash': Icons.sports_tennis,
    'badminton': Icons.sports_tennis,
    
    // Combat Sports
    'wrestling': Icons.sports_mma,
    'boxing': Icons.sports_mma,
    'judo': Icons.sports_mma,
    'karate': Icons.sports_mma,
    'taekwondo': Icons.sports_mma,
    
    // Mind Sports
    'chess': Icons.sports_esports,
    
    // Target Sports
    'shooting': Icons.gps_fixed,
    'archery': Icons.gps_fixed,
    
    // Strength Sports
    'weightlifting': Icons.fitness_center,
    
    // Track & Field
    'running': Icons.directions_run,
    'sprint': Icons.directions_run,
    'relay': Icons.directions_run,
    'long_jump': Icons.directions_run,
    'high_jump': Icons.directions_run,
    'triple_jump': Icons.directions_run,
    'javelin_throw': Icons.sports,
    'shot_put': Icons.sports,
    'discus_throw': Icons.sports,
    'hammer_throw': Icons.sports,
    'pole_vault': Icons.sports,
    'marathon': Icons.directions_run,
    'race_walking': Icons.directions_walk,
    
    // Water Sports
    'swimming': Icons.pool,
    'diving': Icons.pool,
    'sailing': Icons.sailing,
    'rowing': Icons.sailing,
    'kayaking': Icons.sailing,
    
    // Other Sports
    'kabaddi': Icons.sports,
  };

  static IconData getSportsIcon(String sport) {
    // Normalize the sport name
    final normalizedSport = sport.toLowerCase().replaceAll(' ', '_');
    
    // Try exact match first
    if (_sportsIconMap.containsKey(normalizedSport)) {
      return _sportsIconMap[normalizedSport]!;
    }
    
    // Try partial matches for common variations
    for (final entry in _sportsIconMap.entries) {
      if (normalizedSport.contains(entry.key) || entry.key.contains(normalizedSport)) {
        return entry.value;
      }
    }
    
    // Default fallback
    return Icons.sports;
  }

  static List<String> getAllSports() {
    return _sportsIconMap.keys.toList();
  }

  static String getSportDisplayName(String sport) {
    return sport.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }
}
