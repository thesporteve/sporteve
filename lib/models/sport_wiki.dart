import 'package:cloud_firestore/cloud_firestore.dart';

class SportWiki {
  final String id;
  final String name;                    // Required - sport name
  final String category;               // Required - Team/Individual/Mixed
  final String type;                   // Required - Outdoor/Indoor/Water
  final String description;            // Required - basic description
  
  // Optional detailed information
  final String? origin;
  final String? governingBody;
  final bool? olympicSport;
  final String? rulesSummary;
  final String? playerCount;
  final String? difficultyLevel;
  final String? seasonalPlay;
  
  // Lists (optional)
  final List<String>? famousAthletes;
  final List<String>? popularEvents;
  final List<String>? equipmentNeeded;
  final List<String>? physicalDemands;
  final List<String>? funFacts;
  final List<String>? tags;
  final List<String>? relatedSports;
  
  // Images (optional)
  final Map<String, String>? images;  // hero, equipment, action shots etc
  
  // Indian context (optional)
  final Map<String, dynamic>? indianHistory;
  final List<String>? indianMilestones;
  final String? regionalPopularity;
  final String? iconicMoments;
  
  // System fields
  final DateTime createdAt;
  final DateTime? lastUpdated;

  SportWiki({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.description,
    this.origin,
    this.governingBody,
    this.olympicSport,
    this.rulesSummary,
    this.playerCount,
    this.difficultyLevel,
    this.seasonalPlay,
    this.famousAthletes,
    this.popularEvents,
    this.equipmentNeeded,
    this.physicalDemands,
    this.funFacts,
    this.tags,
    this.relatedSports,
    this.images,
    this.indianHistory,
    this.indianMilestones,
    this.regionalPopularity,
    this.iconicMoments,
    required this.createdAt,
    this.lastUpdated,
  });

  // Factory constructor from Firestore document
  factory SportWiki.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SportWiki(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      origin: data['origin'],
      governingBody: data['governing_body'],
      olympicSport: data['olympic_sport'],
      rulesSummary: data['rules_summary'],
      playerCount: data['player_count'],
      difficultyLevel: data['difficulty_level'],
      seasonalPlay: data['seasonal_play'],
      famousAthletes: data['famous_athletes'] != null 
          ? List<String>.from(data['famous_athletes']) 
          : null,
      popularEvents: data['popular_events'] != null 
          ? List<String>.from(data['popular_events']) 
          : null,
      equipmentNeeded: data['equipment_needed'] != null 
          ? List<String>.from(data['equipment_needed']) 
          : null,
      physicalDemands: data['physical_demands'] != null 
          ? List<String>.from(data['physical_demands']) 
          : null,
      funFacts: data['fun_facts'] != null 
          ? List<String>.from(data['fun_facts']) 
          : null,
      tags: data['tags'] != null 
          ? List<String>.from(data['tags']) 
          : null,
      relatedSports: data['related_sports'] != null 
          ? List<String>.from(data['related_sports']) 
          : null,
      images: data['images'] != null 
          ? Map<String, String>.from(data['images']) 
          : null,
      indianHistory: data['indian_history'],
      indianMilestones: data['indian_milestones'] != null 
          ? List<String>.from(data['indian_milestones']) 
          : null,
      regionalPopularity: data['regional_popularity'],
      iconicMoments: data['iconic_moments'],
      createdAt: _parseTimestamp(data['created_at']),
      lastUpdated: _parseTimestamp(data['last_updated']),
    );
  }

  // Factory constructor from JSON
  factory SportWiki.fromJson(Map<String, dynamic> json) {
    return SportWiki(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      origin: json['origin'],
      governingBody: json['governing_body'],
      olympicSport: json['olympic_sport'],
      rulesSummary: json['rules_summary'],
      playerCount: json['player_count'],
      difficultyLevel: json['difficulty_level'],
      seasonalPlay: json['seasonal_play'],
      famousAthletes: json['famous_athletes'] != null 
          ? List<String>.from(json['famous_athletes']) 
          : null,
      popularEvents: json['popular_events'] != null 
          ? List<String>.from(json['popular_events']) 
          : null,
      equipmentNeeded: json['equipment_needed'] != null 
          ? List<String>.from(json['equipment_needed']) 
          : null,
      physicalDemands: json['physical_demands'] != null 
          ? List<String>.from(json['physical_demands']) 
          : null,
      funFacts: json['fun_facts'] != null 
          ? List<String>.from(json['fun_facts']) 
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
      relatedSports: json['related_sports'] != null 
          ? List<String>.from(json['related_sports']) 
          : null,
      images: json['images'] != null 
          ? Map<String, String>.from(json['images']) 
          : null,
      indianHistory: json['indian_history'],
      indianMilestones: json['indian_milestones'] != null 
          ? List<String>.from(json['indian_milestones']) 
          : null,
      regionalPopularity: json['regional_popularity'],
      iconicMoments: json['iconic_moments'],
      createdAt: _parseTimestamp(json['created_at']),
      lastUpdated: _parseTimestamp(json['last_updated']),
    );
  }

  // Helper method to parse different timestamp formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $timestamp, using current time');
        return DateTime.now();
      }
    } else {
      print('Unknown timestamp type: ${timestamp.runtimeType}, using current time');
      return DateTime.now();
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'type': type,
      'description': description,
      'origin': origin,
      'governing_body': governingBody,
      'olympic_sport': olympicSport,
      'rules_summary': rulesSummary,
      'player_count': playerCount,
      'difficulty_level': difficultyLevel,
      'seasonal_play': seasonalPlay,
      'famous_athletes': famousAthletes,
      'popular_events': popularEvents,
      'equipment_needed': equipmentNeeded,
      'physical_demands': physicalDemands,
      'fun_facts': funFacts,
      'tags': tags,
      'related_sports': relatedSports,
      'images': images,
      'indian_history': indianHistory,
      'indian_milestones': indianMilestones,
      'regional_popularity': regionalPopularity,
      'iconic_moments': iconicMoments,
      'created_at': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'description': description,
      'origin': origin,
      'governing_body': governingBody,
      'olympic_sport': olympicSport,
      'rules_summary': rulesSummary,
      'player_count': playerCount,
      'difficulty_level': difficultyLevel,
      'seasonal_play': seasonalPlay,
      'famous_athletes': famousAthletes,
      'popular_events': popularEvents,
      'equipment_needed': equipmentNeeded,
      'physical_demands': physicalDemands,
      'fun_facts': funFacts,
      'tags': tags,
      'related_sports': relatedSports,
      'images': images,
      'indian_history': indianHistory,
      'indian_milestones': indianMilestones,
      'regional_popularity': regionalPopularity,
      'iconic_moments': iconicMoments,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  SportWiki copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    String? description,
    String? origin,
    String? governingBody,
    bool? olympicSport,
    String? rulesSummary,
    String? playerCount,
    String? difficultyLevel,
    String? seasonalPlay,
    List<String>? famousAthletes,
    List<String>? popularEvents,
    List<String>? equipmentNeeded,
    List<String>? physicalDemands,
    List<String>? funFacts,
    List<String>? tags,
    List<String>? relatedSports,
    Map<String, String>? images,
    Map<String, dynamic>? indianHistory,
    List<String>? indianMilestones,
    String? regionalPopularity,
    String? iconicMoments,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return SportWiki(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      governingBody: governingBody ?? this.governingBody,
      olympicSport: olympicSport ?? this.olympicSport,
      rulesSummary: rulesSummary ?? this.rulesSummary,
      playerCount: playerCount ?? this.playerCount,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      seasonalPlay: seasonalPlay ?? this.seasonalPlay,
      famousAthletes: famousAthletes ?? this.famousAthletes,
      popularEvents: popularEvents ?? this.popularEvents,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      physicalDemands: physicalDemands ?? this.physicalDemands,
      funFacts: funFacts ?? this.funFacts,
      tags: tags ?? this.tags,
      relatedSports: relatedSports ?? this.relatedSports,
      images: images ?? this.images,
      indianHistory: indianHistory ?? this.indianHistory,
      indianMilestones: indianMilestones ?? this.indianMilestones,
      regionalPopularity: regionalPopularity ?? this.regionalPopularity,
      iconicMoments: iconicMoments ?? this.iconicMoments,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'SportWiki{id: $id, name: $name, category: $category, type: $type}';
  }
}
