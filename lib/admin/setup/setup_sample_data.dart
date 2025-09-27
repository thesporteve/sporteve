import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament.dart';
import '../../models/athlete.dart';

/// One-time setup script to create sample tournaments and athletes for testing
/// Run this once to populate your database with sample data
class SampleDataSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample tournaments
  static Future<void> createSampleTournaments() async {
    try {
      print('Setting up sample tournaments...');

      final tournaments = [
        Tournament(
          id: '',
          name: 'FIFA World Cup 2024',
          description: 'Global football championship',
          sportType: 'football',
          startDate: '2024-11-20',
          endDate: '2024-12-18',
          place: 'Qatar',
          status: TournamentStatus.upcoming,
          eventUrl: 'https://www.fifa.com/worldcup',
        ),
        Tournament(
          id: '',
          name: 'Olympic Games Paris 2024',
          description: 'Summer Olympics in Paris',
          sportType: 'athletics',
          startDate: '2024-07-26',
          endDate: '2024-08-11',
          place: 'Paris, France',
          status: TournamentStatus.upcoming,
          eventUrl: 'https://www.paris2024.org',
        ),
        Tournament(
          id: '',
          name: 'Wimbledon Championships 2024',
          description: 'The most prestigious tennis tournament',
          sportType: 'tennis',
          startDate: '2024-07-01',
          endDate: '2024-07-14',
          place: 'London, UK',
          status: TournamentStatus.upcoming,
          eventUrl: 'https://www.wimbledon.com',
        ),
        Tournament(
          id: '',
          name: 'NBA Finals 2024',
          description: 'Basketball championship series',
          sportType: 'basketball',
          startDate: '2024-06-06',
          endDate: '2024-06-23',
          place: 'USA',
          status: TournamentStatus.completed,
          eventUrl: 'https://www.nba.com/finals',
        ),
      ];

      for (var tournament in tournaments) {
        await _firestore.collection('tournaments').add(tournament.toJson());
        print('✅ Added tournament: ${tournament.name}');
      }

      print('✅ Sample tournaments created successfully!');
      
    } catch (e) {
      print('❌ Error setting up sample tournaments: $e');
    }
  }

  /// Create sample athletes
  static Future<void> createSampleAthletes() async {
    try {
      print('Setting up sample athletes...');

      final athletes = [
        Athlete(
          id: '',
          name: 'Lionel Messi',
          sport: 'Football',
          isParaAthlete: false,
          dob: DateTime(1987, 6, 24),
          placeOfBirth: 'Rosario, Argentina',
          education: 'La Masia Football Academy',
          achievements: [
            Achievement(year: 2022, title: 'FIFA World Cup Winner'),
            Achievement(year: 2023, title: '8th Ballon d\'Or'),
            Achievement(year: 2015, title: 'UEFA Champions League Winner'),
          ],
          awards: ['Ballon d\'Or (8 times)', 'FIFA World Player of the Year'],
          funFacts: ['Shortest player to win Ballon d\'Or', 'Left-footed genius', 'Started at FC Barcelona at age 13'],
        ),
        Athlete(
          id: '',
          name: 'Usain Bolt',
          sport: 'Athletics',
          isParaAthlete: false,
          dob: DateTime(1986, 8, 21),
          placeOfBirth: 'Sherwood Content, Jamaica',
          education: 'William Knibb Memorial High School',
          achievements: [
            Achievement(year: 2008, title: 'Olympic 100m Gold Medal'),
            Achievement(year: 2009, title: '100m World Record (9.58s)'),
            Achievement(year: 2012, title: 'Olympic Triple Gold (100m, 200m, 4x100m)'),
          ],
          awards: ['Order of Jamaica', 'Laureus World Sportsman of the Year'],
          funFacts: ['Fastest human ever recorded', 'Lightning Bolt celebration', 'Loves cricket and wanted to be a cricket player'],
        ),
        Athlete(
          id: '',
          name: 'Novak Djokovic',
          sport: 'Tennis',
          isParaAthlete: false,
          dob: DateTime(1987, 5, 22),
          placeOfBirth: 'Belgrade, Serbia',
          education: 'Pilic Tennis Academy',
          achievements: [
            Achievement(year: 2023, title: '24th Grand Slam Title'),
            Achievement(year: 2021, title: 'Australian Open Champion'),
            Achievement(year: 2019, title: 'Wimbledon Champion'),
          ],
          awards: ['Order of the Star of Karađorđe', 'Laureus World Sportsman of the Year'],
          funFacts: ['Speaks 6 languages fluently', 'Gluten-free diet advocate', 'Founded Novak Djokovic Foundation'],
        ),
        Athlete(
          id: '',
          name: 'LeBron James',
          sport: 'Basketball',
          isParaAthlete: false,
          dob: DateTime(1984, 12, 30),
          placeOfBirth: 'Akron, Ohio, USA',
          education: 'St. Vincent-St. Mary High School',
          achievements: [
            Achievement(year: 2020, title: 'NBA Championship with Lakers'),
            Achievement(year: 2016, title: 'NBA Championship with Cavaliers'),
            Achievement(year: 2013, title: 'NBA Championship with Heat'),
          ],
          awards: ['4x NBA Champion', '4x NBA Finals MVP', '19x NBA All-Star'],
          funFacts: ['Chosen straight from high school to NBA', 'King James', 'Active in social justice causes'],
        ),
        Athlete(
          id: '',
          name: 'Serena Williams',
          sport: 'Tennis',
          isParaAthlete: false,
          dob: DateTime(1981, 9, 26),
          placeOfBirth: 'Saginaw, Michigan, USA',
          education: 'Art Institute of Fort Lauderdale',
          achievements: [
            Achievement(year: 2017, title: 'Australian Open Champion (while pregnant)'),
            Achievement(year: 2015, title: 'Serena Slam (4 consecutive Grand Slams)'),
            Achievement(year: 1999, title: 'First Grand Slam at US Open'),
          ],
          awards: ['23x Grand Slam Singles Champion', 'Olympic Gold Medalist'],
          funFacts: ['Won Grand Slam while pregnant', 'Fashion designer', 'Youngest player to win US Open at age 17'],
        ),
      ];

      for (var athlete in athletes) {
        await _firestore.collection('athletes').add(athlete.toJson());
        print('✅ Added athlete: ${athlete.name}');
      }

      print('✅ Sample athletes created successfully!');
      
    } catch (e) {
      print('❌ Error setting up sample athletes: $e');
    }
  }

  /// Check if tournaments exist
  static Future<bool> tournamentsExist() async {
    try {
      final querySnapshot = await _firestore.collection('tournaments').limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking tournaments: $e');
      return false;
    }
  }

  /// Check if athletes exist
  static Future<bool> athletesExist() async {
    try {
      final querySnapshot = await _firestore.collection('athletes').limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking athletes: $e');
      return false;
    }
  }

  /// Run setup only if no sample data exists
  static Future<void> setupIfNeeded() async {
    try {
      final tournamentsExist = await SampleDataSetup.tournamentsExist();
      final athletesExist = await SampleDataSetup.athletesExist();
      
      if (!tournamentsExist) {
        print('No tournaments found. Setting up sample tournaments...');
        await createSampleTournaments();
      } else {
        print('Tournaments already exist. Skipping tournament setup.');
      }
      
      if (!athletesExist) {
        print('No athletes found. Setting up sample athletes...');
        await createSampleAthletes();
      } else {
        print('Athletes already exist. Skipping athlete setup.');
      }
    } catch (e) {
      print('Error in sample data setup: $e');
    }
  }
}
