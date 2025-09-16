import 'package:cloud_firestore/cloud_firestore.dart';

class Athlete {
  final String id;
  final String name;
  final String sport;
  final String bio;

  Athlete({
    required this.id,
    required this.name,
    required this.sport,
    required this.bio,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sport: json['sport'] ?? '',
      bio: json['bio'] ?? '',
    );
  }

  factory Athlete.fromFirestore(String id, Map<String, dynamic> data) {
    return Athlete(
      id: id,
      name: data['name'] ?? '',
      sport: data['sport'] ?? '',
      bio: data['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'bio': bio,
    };
  }

  Athlete copyWith({
    String? id,
    String? name,
    String? sport,
    String? bio,
  }) {
    return Athlete(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      bio: bio ?? this.bio,
    );
  }
}
