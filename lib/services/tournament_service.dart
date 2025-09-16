import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament.dart';
import '../models/athlete.dart';
import 'firebase_service.dart';

class TournamentService {
  static TournamentService? _instance;
  static TournamentService get instance => _instance ??= TournamentService._internal();
  
  TournamentService._internal();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Tournament Methods
  Future<List<Tournament>> getAllTournaments() async {
    try {
      print('Fetching tournaments from Firestore...');
      final querySnapshot = await _firestore
          .collection('tournaments')
          .orderBy('start_date', descending: false)
          .get();

      print('Found ${querySnapshot.docs.length} tournament documents');
      
      return querySnapshot.docs
          .map((doc) {
            print('Processing tournament doc: ${doc.id}');
            print('Tournament data: ${doc.data()}');
            return Tournament.fromFirestore(doc.id, doc.data());
          })
          .toList();
    } catch (e) {
      print('Error fetching tournaments with orderBy, trying without: $e');
      
      try {
        // Fallback: Get all tournaments and sort in memory
        final querySnapshot = await _firestore
            .collection('tournaments')
            .get();

        final tournaments = querySnapshot.docs
            .map((doc) => Tournament.fromFirestore(doc.id, doc.data()))
            .toList();
            
        // Sort by start date in memory
        tournaments.sort((a, b) => a.startDate.compareTo(b.startDate));
        
        return tournaments;
      } catch (fallbackError) {
        print('Error fetching tournaments (fallback): $fallbackError');
        return [];
      }
    }
  }

  Future<List<Tournament>> getLiveTournaments() async {
    try {
      // Try the optimized query with composite index first
      final querySnapshot = await _firestore
          .collection('tournaments')
          .where('status', isEqualTo: 'live')
          .orderBy('start_date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Tournament.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Composite index query failed, trying fallback: $e');
      
      try {
        // Fallback: Get all tournaments and filter in memory
        final querySnapshot = await _firestore
            .collection('tournaments')
            .get();

        final allTournaments = querySnapshot.docs
            .map((doc) => Tournament.fromFirestore(doc.id, doc.data()))
            .toList();
            
        // Filter live tournaments and sort by start date in memory
        final liveTournaments = allTournaments
            .where((tournament) => tournament.status.isLive)
            .toList();
            
        // Sort by start date (assuming start_date is a string in YYYY-MM-DD format)
        liveTournaments.sort((a, b) => a.startDate.compareTo(b.startDate));
        
        return liveTournaments;
      } catch (fallbackError) {
        print('Error fetching tournaments (fallback): $fallbackError');
        return [];
      }
    }
  }

  Future<Tournament?> getTournamentById(String tournamentId) async {
    try {
      final doc = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Tournament.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching tournament by ID: $e');
      return null;
    }
  }

  Future<String> addTournament(Tournament tournament) async {
    try {
      final docRef = await _firestore
          .collection('tournaments')
          .add(tournament.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding tournament: $e');
      rethrow;
    }
  }

  Future<void> updateTournament(String tournamentId, Tournament tournament) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .update(tournament.toJson());
    } catch (e) {
      print('Error updating tournament: $e');
      rethrow;
    }
  }

  Future<void> deleteTournament(String tournamentId) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .delete();
    } catch (e) {
      print('Error deleting tournament: $e');
      rethrow;
    }
  }

  // Athlete Methods
  Future<List<Athlete>> getAllAthletes() async {
    try {
      print('Fetching athletes from Firestore...');
      final querySnapshot = await _firestore
          .collection('athletes')
          .orderBy('name')
          .get();

      print('Found ${querySnapshot.docs.length} athlete documents');
      
      return querySnapshot.docs
          .map((doc) {
            print('Processing athlete doc: ${doc.id}');
            print('Athlete data: ${doc.data()}');
            return Athlete.fromFirestore(doc.id, doc.data());
          })
          .toList();
    } catch (e) {
      print('Error fetching athletes: $e');
      
      // Try without orderBy as fallback
      try {
        print('Trying to fetch athletes without orderBy...');
        final querySnapshot = await _firestore
            .collection('athletes')
            .get();
            
        print('Found ${querySnapshot.docs.length} athlete documents (fallback)');
        
        return querySnapshot.docs
            .map((doc) {
              print('Processing athlete doc: ${doc.id}');
              print('Athlete data: ${doc.data()}');
              return Athlete.fromFirestore(doc.id, doc.data());
            })
            .toList();
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<List<Athlete>> getAthletesBySport(String sport) async {
    try {
      final querySnapshot = await _firestore
          .collection('athletes')
          .where('sport', isEqualTo: sport)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Athlete.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching athletes by sport: $e');
      return [];
    }
  }

  Future<Athlete?> getAthleteById(String athleteId) async {
    try {
      final doc = await _firestore
          .collection('athletes')
          .doc(athleteId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Athlete.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching athlete by ID: $e');
      return null;
    }
  }

  Future<String> addAthlete(Athlete athlete) async {
    try {
      final docRef = await _firestore
          .collection('athletes')
          .add(athlete.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding athlete: $e');
      rethrow;
    }
  }

  Future<void> updateAthlete(String athleteId, Athlete athlete) async {
    try {
      await _firestore
          .collection('athletes')
          .doc(athleteId)
          .update(athlete.toJson());
    } catch (e) {
      print('Error updating athlete: $e');
      rethrow;
    }
  }

  Future<void> deleteAthlete(String athleteId) async {
    try {
      await _firestore
          .collection('athletes')
          .doc(athleteId)
          .delete();
    } catch (e) {
      print('Error deleting athlete: $e');
      rethrow;
    }
  }
}
