import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String name;
  final String place;
  final String sportType;
  final String startDate;
  final String endDate;
  final TournamentStatus status;
  final String description;
  final String? eventUrl;

  Tournament({
    required this.id,
    required this.name,
    required this.place,
    required this.sportType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.description,
    this.eventUrl,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      place: json['place'] ?? '',
      sportType: json['sport_type'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: TournamentStatus.fromString(json['status'] ?? 'upcoming'),
      description: json['description'] ?? '',
      eventUrl: json['event_url'],
    );
  }

  factory Tournament.fromFirestore(String id, Map<String, dynamic> data) {
    return Tournament(
      id: id,
      name: data['name'] ?? '',
      place: data['place'] ?? '',
      sportType: data['sport_type'] ?? '',
      startDate: data['start_date'] ?? '',
      endDate: data['end_date'] ?? '',
      status: TournamentStatus.fromString(data['status'] ?? 'upcoming'),
      description: data['description'] ?? '',
      eventUrl: data['event_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'place': place,
      'sport_type': sportType,
      'start_date': startDate,
      'end_date': endDate,
      'status': status.value,
      'description': description,
      'event_url': eventUrl,
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? place,
    String? sportType,
    String? startDate,
    String? endDate,
    TournamentStatus? status,
    String? description,
    String? eventUrl,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      place: place ?? this.place,
      sportType: sportType ?? this.sportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      eventUrl: eventUrl ?? this.eventUrl,
    );
  }
}

enum TournamentStatus {
  upcoming('upcoming'),
  live('live'),
  completed('completed');

  const TournamentStatus(this.value);

  final String value;

  static TournamentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'live':
        return TournamentStatus.live;
      case 'completed':
        return TournamentStatus.completed;
      case 'upcoming':
      default:
        return TournamentStatus.upcoming;
    }
  }

  String get displayName {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.live:
        return 'Live';
      case TournamentStatus.completed:
        return 'Completed';
    }
  }

  bool get isLive => this == TournamentStatus.live;
}
