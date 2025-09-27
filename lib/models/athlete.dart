import 'package:cloud_firestore/cloud_firestore.dart';

/// Achievement model for athlete accomplishments
class Achievement {
  final int year;
  final String title;

  Achievement({
    required this.year,
    required this.title,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      year: json['year'] ?? DateTime.now().year,
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'title': title,
    };
  }

  Achievement copyWith({
    int? year,
    String? title,
  }) {
    return Achievement(
      year: year ?? this.year,
      title: title ?? this.title,
    );
  }
}

/// Enhanced Athlete model with comprehensive profile information
class Athlete {
  // CSV-uploadable fields (simple data)
  final String id;
  final String name;
  final String sport;
  final bool isParaAthlete;
  final DateTime? dob;
  final String placeOfBirth;
  final String education;
  final String? imageUrl;
  
  // Form-only fields (complex data)
  final String description; // General summary/biography of the athlete
  final List<Achievement> achievements;
  final List<String> awards;
  final List<String> funFacts;
  
  // Metadata
  final DateTime lastUpdated;

  Athlete({
    required this.id,
    required this.name,
    required this.sport,
    this.isParaAthlete = false,
    this.dob,
    this.placeOfBirth = '',
    this.education = '',
    this.imageUrl,
    this.description = '', // Form-only field
    this.achievements = const [],
    this.awards = const [],
    this.funFacts = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Create athlete from CSV data (basic fields only)
  factory Athlete.fromCsv({
    required String name,
    required String sport,
    bool isParaAthlete = false,
    DateTime? dob,
    String placeOfBirth = '',
    String education = '',
    String? imageUrl,
  }) {
    return Athlete(
      id: '', // Will be set by Firestore
      name: name.trim(),
      sport: sport.trim(),
      isParaAthlete: isParaAthlete,
      dob: dob,
      placeOfBirth: placeOfBirth.trim(),
      education: education.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      description: '', // Empty for CSV imports - admin can add later via form
      achievements: [],
      awards: [],
      funFacts: [],
      lastUpdated: DateTime.now(),
    );
  }

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sport: json['sport'] ?? '',
      isParaAthlete: json['is_para_athlete'] ?? false,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      placeOfBirth: json['place_of_birth'] ?? '',
      education: json['education'] ?? '',
      imageUrl: json['image_url']?.isEmpty == true ? null : json['image_url'],
      description: json['description'] ?? '',
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      awards: List<String>.from(json['awards'] ?? []),
      funFacts: List<String>.from(json['fun_facts'] ?? []),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory Athlete.fromFirestore(String id, Map<String, dynamic> data) {
    return Athlete(
      id: id,
      name: data['name'] ?? '',
      sport: data['sport'] ?? '',
      isParaAthlete: data['is_para_athlete'] ?? false,
      dob: data['dob'] != null 
          ? (data['dob'] is Timestamp 
              ? (data['dob'] as Timestamp).toDate()
              : DateTime.tryParse(data['dob'].toString()))
          : null,
      placeOfBirth: data['place_of_birth'] ?? '',
      education: data['education'] ?? '',
      imageUrl: data['image_url']?.isEmpty == true ? null : data['image_url'],
      description: data['description'] ?? '',
      achievements: (data['achievements'] as List<dynamic>?)
              ?.map((item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      awards: List<String>.from(data['awards'] ?? []),
      funFacts: List<String>.from(data['fun_facts'] ?? []),
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] is Timestamp 
              ? (data['last_updated'] as Timestamp).toDate()
              : DateTime.tryParse(data['last_updated'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'is_para_athlete': isParaAthlete,
      'dob': dob?.toIso8601String(),
      'place_of_birth': placeOfBirth,
      'education': education,
      'image_url': imageUrl,
      'description': description,
      'achievements': achievements.map((achievement) => achievement.toJson()).toList(),
      'awards': awards,
      'fun_facts': funFacts,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Convert to Firestore document (uses Timestamp for dates)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sport': sport,
      'is_para_athlete': isParaAthlete,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'place_of_birth': placeOfBirth,
      'education': education,
      'image_url': imageUrl,
      'description': description,
      'achievements': achievements.map((achievement) => achievement.toJson()).toList(),
      'awards': awards,
      'fun_facts': funFacts,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }

  Athlete copyWith({
    String? id,
    String? name,
    String? sport,
    bool? isParaAthlete,
    DateTime? dob,
    String? placeOfBirth,
    String? education,
    String? imageUrl,
    String? description,
    List<Achievement>? achievements,
    List<String>? awards,
    List<String>? funFacts,
    DateTime? lastUpdated,
  }) {
    return Athlete(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      isParaAthlete: isParaAthlete ?? this.isParaAthlete,
      dob: dob ?? this.dob,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      education: education ?? this.education,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      achievements: achievements ?? this.achievements,
      awards: awards ?? this.awards,
      funFacts: funFacts ?? this.funFacts,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Legacy support: migrate old bio field to fun_facts
  factory Athlete.fromLegacyData(String id, Map<String, dynamic> data) {
    final legacyBio = data['bio']?.toString().trim() ?? '';
    
    return Athlete(
      id: id,
      name: data['name'] ?? '',
      sport: data['sport'] ?? '',
      isParaAthlete: false, // Default for legacy data
      dob: null, // Will need manual entry
      placeOfBirth: '',
      education: '',
      imageUrl: null,
      description: '', // Will need manual entry
      achievements: [],
      awards: [],
      funFacts: legacyBio.isNotEmpty ? [legacyBio] : [], // Migrate bio to fun_facts
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if athlete has complete profile information
  bool get hasCompleteProfile {
    return name.isNotEmpty &&
           sport.isNotEmpty &&
           placeOfBirth.isNotEmpty &&
           dob != null &&
           (achievements.isNotEmpty || awards.isNotEmpty || funFacts.isNotEmpty);
  }

  /// Get display age from date of birth
  int? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }

  /// Format date of birth for display
  String get formattedDob {
    if (dob == null) return 'Not specified';
    return '${dob!.day}/${dob!.month}/${dob!.year}';
  }
}
