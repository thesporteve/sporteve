import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_article.dart';
import '../../models/tournament.dart';
import '../../models/athlete.dart';
// Removed admin_notification_service import - notifications now handled by Cloud Functions
import '../../services/firebase_service.dart';
import '../../services/tournament_service.dart';

class AdminDataService {
  static AdminDataService? _instance;
  static AdminDataService get instance => _instance ??= AdminDataService._internal();
  
  AdminDataService._internal();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final TournamentService _tournamentService = TournamentService.instance;

  // News Articles Methods
  Future<List<NewsArticle>> getAllNewsArticles() async {
    try {
      print('Fetching all news articles from Firestore...');
      final querySnapshot = await _firestore
          .collection('news_articles')
          .orderBy('publishedAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} news articles');
      
      return querySnapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching news articles: $e');
      // Try without orderBy as fallback
      try {
        final querySnapshot = await _firestore
            .collection('news_articles')
            .get();
        return querySnapshot.docs
            .map((doc) => NewsArticle.fromFirestore(doc.id, doc.data()))
            .toList();
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<String> addNewsArticle(NewsArticle article, {bool toStaging = false}) async {
    try {
      final collection = toStaging ? 'news_staging' : 'news_articles';
      final docRef = await _firestore
          .collection(collection)
          .add(article.toJson());
      print('Added news article to $collection with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding news article: $e');
      rethrow;
    }
  }

  Future<void> updateNewsArticle(String articleId, NewsArticle article) async {
    try {
      final updateData = article.toJson();
      // Add updatedAt field but preserve original publishedAt for proper ordering
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection('news_articles')
          .doc(articleId)
          .update(updateData);
      print('Updated news article: $articleId');
    } catch (e) {
      print('Error updating news article: $e');
      rethrow;
    }
  }

  Future<void> deleteNewsArticle(String articleId) async {
    try {
      await _firestore
          .collection('news_articles')
          .doc(articleId)
          .delete();
      print('Deleted news article: $articleId');
    } catch (e) {
      print('Error deleting news article: $e');
      rethrow;
    }
  }

  Future<void> publishFromStaging(String stagingId) async {
    try {
      // Get the article from staging
      final stagingDoc = await _firestore
          .collection('news_staging')
          .doc(stagingId)
          .get();

      if (!stagingDoc.exists) {
        throw Exception('Article not found in staging');
      }

      final article = NewsArticle.fromFirestore(stagingId, stagingDoc.data()!);
      
      // Add to news_articles collection
      final publishedArticleId = await addNewsArticle(article, toStaging: false);
      
      // Note: Push notifications will be sent automatically via Cloud Function
      // when the article is added to news_articles collection
      print('📱 Article published, Cloud Function will send notifications: ${article.title}');
      
      // Remove from staging
      await _firestore
          .collection('news_staging')
          .doc(stagingId)
          .delete();
      
      print('📱 Published article from staging: $stagingId');
    } catch (e) {
      print('Error publishing from staging: $e');
      rethrow;
    }
  }

  // Tournament Methods (delegated to existing service)
  Future<List<Tournament>> getAllTournaments() => _tournamentService.getAllTournaments();
  Future<String> addTournament(Tournament tournament) => _tournamentService.addTournament(tournament);
  Future<void> updateTournament(String id, Tournament tournament) => _tournamentService.updateTournament(id, tournament);
  Future<void> deleteTournament(String id) => _tournamentService.deleteTournament(id);
  Future<Tournament?> getTournamentById(String id) => _tournamentService.getTournamentById(id);

  // Enhanced Athlete Methods with proper collection handling
  Future<List<Athlete>> getAllAthletes() async {
    try {
      print('Fetching all athletes from "athletes" collection...');
      final querySnapshot = await _firestore
          .collection('athletes')
          .orderBy('name')
          .get();

      print('Found ${querySnapshot.docs.length} athletes');
      
      final athletes = querySnapshot.docs
          .map((doc) => Athlete.fromFirestore(doc.id, doc.data()))
          .toList();

      return athletes;
    } catch (e) {
      print('Error fetching athletes: $e');
      // Try without orderBy as fallback
      try {
        final querySnapshot = await _firestore
            .collection('athletes')
            .get();
        
        final athletes = querySnapshot.docs
            .map((doc) => Athlete.fromFirestore(doc.id, doc.data()))
            .toList();
        
        // Sort in memory if Firestore orderBy fails
        athletes.sort((a, b) => a.name.compareTo(b.name));
        return athletes;
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<String> addAthlete(Athlete athlete) async {
    try {
      final docRef = await _firestore
          .collection('athletes')
          .add(athlete.toFirestore());
      print('Added athlete to athletes collection with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding athlete: $e');
      rethrow;
    }
  }

  Future<void> updateAthlete(String athleteId, Athlete athlete) async {
    try {
      final updateData = athlete.toFirestore();
      // Ensure lastUpdated is current
      updateData['last_updated'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection('athletes')
          .doc(athleteId)
          .update(updateData);
      print('Updated athlete: $athleteId');
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
      print('Deleted athlete: $athleteId');
    } catch (e) {
      print('Error deleting athlete: $e');
      rethrow;
    }
  }

  Future<Athlete?> getAthleteById(String athleteId) async {
    try {
      final docSnapshot = await _firestore
          .collection('athletes')
          .doc(athleteId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return Athlete.fromFirestore(docSnapshot.id, docSnapshot.data()!);
    } catch (e) {
      print('Error getting athlete by ID: $e');
      return null;
    }
  }

  /// Bulk import athletes from CSV data
  Future<Map<String, dynamic>> bulkImportAthletes(List<Athlete> athletes) async {
    int successCount = 0;
    int errorCount = 0;
    List<String> errors = [];
    List<String> addedIds = [];

    try {
      print('Starting bulk import of ${athletes.length} athletes...');
      
      // Use batch for better performance and atomicity
      WriteBatch batch = _firestore.batch();
      
      for (int i = 0; i < athletes.length; i++) {
        try {
          final athlete = athletes[i];
          final docRef = _firestore.collection('athletes').doc();
          batch.set(docRef, athlete.toFirestore());
          addedIds.add(docRef.id);
          successCount++;
          
          // Commit in batches of 500 (Firestore limit)
          if ((i + 1) % 500 == 0 || i == athletes.length - 1) {
            await batch.commit();
            print('Committed batch of ${(i + 1) % 500} athletes. Total processed: ${i + 1}');
            batch = _firestore.batch(); // Create new batch
          }
        } catch (e) {
          errorCount++;
          errors.add('Row ${i + 1}: ${e.toString()}');
          print('Error importing athlete ${i + 1}: $e');
        }
      }

      print('Bulk import completed. Success: $successCount, Errors: $errorCount');
      
      return {
        'success_count': successCount,
        'error_count': errorCount,
        'errors': errors,
        'added_ids': addedIds,
        'total_processed': athletes.length,
      };
    } catch (e) {
      print('Bulk import failed: $e');
      return {
        'success_count': successCount,
        'error_count': athletes.length - successCount,
        'errors': [e.toString()],
        'added_ids': addedIds,
        'total_processed': athletes.length,
      };
    }
  }

  /// Migrate legacy athlete data to new schema
  Future<void> migrateLegacyAthletes() async {
    try {
      print('Starting legacy athlete data migration...');
      
      final querySnapshot = await _firestore
          .collection('athletes')
          .get();

      int migratedCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if it's legacy format (has 'bio' field but not new fields)
        if (data.containsKey('bio') && !data.containsKey('is_para_athlete')) {
          final legacyAthlete = Athlete.fromLegacyData(doc.id, data);
          await updateAthlete(doc.id, legacyAthlete);
          migratedCount++;
          print('Migrated legacy athlete: ${legacyAthlete.name}');
        }
      }
      
      print('Migration completed. Migrated $migratedCount athletes.');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  // Utility method to get available tournaments and athletes for linking
  Future<Map<String, String>> getTournamentOptions() async {
    final tournaments = await getAllTournaments();
    return {for (var tournament in tournaments) tournament.id: tournament.name};
  }

  Future<Map<String, String>> getAthleteOptions() async {
    final athletes = await getAllAthletes();
    return {for (var athlete in athletes) athlete.id: athlete.name};
  }
}
