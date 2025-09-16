class SportsTeam {
  final String id;
  final String name;
  final String shortName;
  final String logoUrl;
  final String city;
  final String league;
  final String sport;
  final String primaryColor;
  final String secondaryColor;
  final int foundedYear;
  final String stadium;
  final String coach;
  final List<String> players;
  final Map<String, dynamic> stats;

  SportsTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.city,
    required this.league,
    required this.sport,
    required this.primaryColor,
    required this.secondaryColor,
    required this.foundedYear,
    required this.stadium,
    required this.coach,
    required this.players,
    required this.stats,
  });

  factory SportsTeam.fromJson(Map<String, dynamic> json) {
    return SportsTeam(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      city: json['city'] ?? '',
      league: json['league'] ?? '',
      sport: json['sport'] ?? '',
      primaryColor: json['primaryColor'] ?? '#000000',
      secondaryColor: json['secondaryColor'] ?? '#FFFFFF',
      foundedYear: json['foundedYear'] ?? 1900,
      stadium: json['stadium'] ?? '',
      coach: json['coach'] ?? '',
      players: List<String>.from(json['players'] ?? []),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'city': city,
      'league': league,
      'sport': sport,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'foundedYear': foundedYear,
      'stadium': stadium,
      'coach': coach,
      'players': players,
      'stats': stats,
    };
  }
}

