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
          sport: 'football',
          bio: 'Argentine professional footballer considered one of the greatest players of all time. World Cup Winner 2022, 8x Ballon d\'Or winner.',
        ),
        Athlete(
          id: '',
          name: 'Usain Bolt',
          sport: 'athletics',
          bio: 'Jamaican former sprinter, widely considered the greatest sprinter of all time. 8x Olympic Gold Medalist with 100m & 200m World Records.',
        ),
        Athlete(
          id: '',
          name: 'Novak Djokovic',
          sport: 'tennis',
          bio: 'Serbian professional tennis player, one of the greatest tennis players of all time. 24x Grand Slam Champion and former World No. 1.',
        ),
        Athlete(
          id: '',
          name: 'LeBron James',
          sport: 'basketball',
          bio: 'American professional basketball player, widely considered one of the greatest in NBA history. 4x NBA Champion, 4x NBA Finals MVP, 19x NBA All-Star.',
        ),
        Athlete(
          id: '',
          name: 'Serena Williams',
          sport: 'tennis',
          bio: 'American former professional tennis player, widely regarded as one of the greatest tennis players of all time. 23x Grand Slam Singles Champion and former World No. 1.',
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
