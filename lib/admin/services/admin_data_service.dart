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

  // Athlete Methods (delegated to existing service)
  Future<List<Athlete>> getAllAthletes() => _tournamentService.getAllAthletes();
  Future<String> addAthlete(Athlete athlete) => _tournamentService.addAthlete(athlete);
  Future<void> updateAthlete(String id, Athlete athlete) => _tournamentService.updateAthlete(id, athlete);
  Future<void> deleteAthlete(String id) => _tournamentService.deleteAthlete(id);
  Future<Athlete?> getAthleteById(String id) => _tournamentService.getAthleteById(id);

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
