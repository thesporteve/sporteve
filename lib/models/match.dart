import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String status; // 'upcoming', 'live', 'finished'
  final DateTime date;
  final String league;
  final String venue;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final Map<String, dynamic>? additionalData;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.date,
    required this.league,
    required this.venue,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.additionalData,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      homeTeam: json['homeTeam'] ?? '',
      awayTeam: json['awayTeam'] ?? '',
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      status: json['status'] ?? 'upcoming',
      date: json['date'] is DateTime 
          ? json['date'] 
          : DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      league: json['league'] ?? '',
      venue: json['venue'] ?? '',
      homeTeamLogo: json['homeTeamLogo'],
      awayTeamLogo: json['awayTeamLogo'],
      additionalData: json['additionalData'],
    );
  }

  factory Match.fromFirestore(String id, Map<String, dynamic> data) {
    return Match(
      id: id,
      homeTeam: data['homeTeam'] ?? '',
      awayTeam: data['awayTeam'] ?? '',
      homeScore: data['homeScore'],
      awayScore: data['awayScore'],
      status: data['status'] ?? 'upcoming',
      date: data['date'] is DateTime 
          ? data['date'] 
          : (data['date'] as Timestamp).toDate(),
      league: data['league'] ?? '',
      venue: data['venue'] ?? '',
      homeTeamLogo: data['homeTeamLogo'],
      awayTeamLogo: data['awayTeamLogo'],
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
      'date': date.toIso8601String(),
      'league': league,
      'venue': venue,
      'homeTeamLogo': homeTeamLogo,
      'awayTeamLogo': awayTeamLogo,
      'additionalData': additionalData,
    };
  }

  Match copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
    String? status,
    DateTime? date,
    String? league,
    String? venue,
    String? homeTeamLogo,
    String? awayTeamLogo,
    Map<String, dynamic>? additionalData,
  }) {
    return Match(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      date: date ?? this.date,
      league: league ?? this.league,
      venue: venue ?? this.venue,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get scoreDisplay {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'TBD';
  }

  bool get isLive => status == 'live';
  bool get isFinished => status == 'finished';
  bool get isUpcoming => status == 'upcoming';
}
