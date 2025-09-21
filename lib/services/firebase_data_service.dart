import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';
import '../models/match.dart';
import 'firebase_service.dart';
import 'debug_logger.dart';

/// Data service for handling news articles and matches
/// Uses Firestore when available, falls back to sample data
class FirebaseDataService {
  static FirebaseDataService? _instance;
  static FirebaseDataService get instance => _instance ??= FirebaseDataService._();
  
  FirebaseDataService._();
  
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Get news articles from Firestore or mock data
  Future<List<NewsArticle>> getNewsArticles() async {
    DebugLogger.instance.logInfo('Data', 'Fetching news articles...');
    DebugLogger.instance.logFirebaseStatus(_firebaseService.getFirebaseStatus());
    
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        DebugLogger.instance.logWarning('Data', 'Firebase not available, using mock data');
        return _getSampleNewsArticles();
      }

      DebugLogger.instance.logInfo('Data', 'Querying Firestore for news articles...');
      // Try to fetch from Firestore with timeout
      QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('news_articles')
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get()
          .timeout(Duration(seconds: 20));

      DebugLogger.instance.logInfo('Data', 'Firestore query completed. Found ${snapshot.docs.length} articles');

      if (snapshot.docs.isNotEmpty) {
        List<NewsArticle> articles = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return NewsArticle.fromFirestore(doc.id, data);
        }).toList();
        
        DebugLogger.instance.logSuccess('Data', 'Successfully loaded ${articles.length} articles from Firestore');
        return articles;
      } else {
        // No articles in Firestore, return sample data
        DebugLogger.instance.logWarning('Data', 'No articles found in Firestore, using mock data');
        return _getSampleNewsArticles();
      }
    } catch (e) {
      DebugLogger.instance.logError('Data', 'Failed to fetch news articles from Firestore: $e');
      if (e.toString().contains('timeout')) {
        DebugLogger.instance.logError('Data', 'Request timed out - check network connection');
      } else if (e.toString().contains('permission')) {
        DebugLogger.instance.logError('Data', 'Permission denied - check Firestore security rules');
      } else if (e.toString().contains('network')) {
        DebugLogger.instance.logError('Data', 'Network error - check internet connectivity');
      }
      return _getSampleNewsArticles();
    }
  }

  /// Get matches from Firestore or mock data
  Future<List<Match>> getMatches() async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        return _getSampleMatches();
      }

      // Try to fetch from Firestore
      QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('matches')
          .orderBy('date', descending: false)
          .limit(20)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Match> matches = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return Match.fromJson({...data, 'id': doc.id});
        }).toList();
        
        return matches;
      } else {
        // No matches in Firestore, return sample data
        return _getSampleMatches();
      }
    } catch (e) {
      print('Failed to fetch matches from Firestore: $e');
      return _getSampleMatches();
    }
  }

  /// Search news articles from Firestore or sample data
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        return _searchSampleData(query);
      }

      if (query.isEmpty) {
        return getNewsArticles(); // Return all articles
      }

      // Optimized search: Limit results and use multiple collection queries
      // For better performance, limit to recent articles first
      QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('news_articles')
          .orderBy('publishedAt', descending: true)
          .limit(100) // Limit to recent 100 articles for better performance
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<NewsArticle> recentArticles = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return NewsArticle.fromFirestore(doc.id, data);
        }).toList();
        
        // Filter articles based on query - search in title, summary, and content
        final searchResults = recentArticles.where((article) {
          final queryLower = query.toLowerCase();
          return article.title.toLowerCase().contains(queryLower) ||
                 article.summary.toLowerCase().contains(queryLower) ||
                 article.content.toLowerCase().contains(queryLower) ||
                 article.author.toLowerCase().contains(queryLower) ||
                 article.source.toLowerCase().contains(queryLower);
        }).toList();

        // Limit search results to 20 for better performance
        return searchResults.take(20).toList();
      } else {
        return _searchSampleData(query);
      }
    } catch (e) {
      print('Failed to search news articles in Firestore: $e');
      return _searchSampleData(query);
    }
  }

  /// Search sample data (fallback method)
  List<NewsArticle> _searchSampleData(String query) {
    final articles = _getSampleNewsArticles();
    if (query.isEmpty) return articles;
    
    final searchResults = articles.where((article) {
      final queryLower = query.toLowerCase();
      return article.title.toLowerCase().contains(queryLower) ||
             article.summary.toLowerCase().contains(queryLower) ||
             article.content.toLowerCase().contains(queryLower) ||
             article.author.toLowerCase().contains(queryLower) ||
             article.source.toLowerCase().contains(queryLower);
    }).toList();

    // Limit mock search results to 20 for consistency
    return searchResults.take(20).toList();
  }

  /// Get article by ID from Firestore or mock data
  Future<NewsArticle?> getArticleById(String id) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        final articles = _getSampleNewsArticles();
        final matches = articles.where((article) => article.id == id).toList();
        return matches.isEmpty ? null : matches.first;
      }

      // Try to fetch from Firestore
      DocumentSnapshot doc = await _firebaseService.firestore
          .collection('news_articles')
          .doc(id)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return NewsArticle.fromFirestore(doc.id, data);
      } else {
        // Article not found in Firestore, check mock data
        final articles = _getSampleNewsArticles();
        final matches = articles.where((article) => article.id == id).toList();
        return matches.isEmpty ? null : matches.first;
      }
    } catch (e) {
      print('Failed to fetch article by ID from Firestore: $e');
      final articles = _getSampleNewsArticles();
      final matches = articles.where((article) => article.id == id).toList();
      return matches.isEmpty ? null : matches.first;
    }
  }

  /// Increment view count for a news article
  Future<void> incrementArticleViews(String articleId) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        print('📊 View tracked for article: $articleId (Firebase not available - demo mode)');
        return;
      }

      await _firebaseService.firestore
          .collection('news_articles')
          .doc(articleId)
          .update({'views': FieldValue.increment(1)});
      
      print('📊 View incremented for article: $articleId');
    } catch (e) {
      print('❌ Failed to increment view count for article $articleId: $e');
      // Don't throw error - view tracking should be non-blocking
    }
  }

  /// Increment like count for a news article
  Future<void> incrementArticleLikes(String articleId) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        print('❤️ Like tracked for article: $articleId (Firebase not available - demo mode)');
        return;
      }

      await _firebaseService.firestore
          .collection('news_articles')
          .doc(articleId)
          .update({'likes': FieldValue.increment(1)});
      
      print('❤️ Like incremented for article: $articleId');
    } catch (e) {
      print('❌ Failed to increment like count for article $articleId: $e');
      // Don't throw error - like tracking should be non-blocking
    }
  }

  /// Increment share count for a news article
  Future<void> incrementArticleShares(String articleId) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        print('🔄 Share tracked for article: $articleId (Firebase not available - demo mode)');
        return;
      }

      await _firebaseService.firestore
          .collection('news_articles')
          .doc(articleId)
          .update({'shares': FieldValue.increment(1)});
      
      print('🔄 Share incremented for article: $articleId');
    } catch (e) {
      print('❌ Failed to increment share count for article $articleId: $e');
      // Don't throw error - share tracking should be non-blocking
    }
  }

  /// Sample news articles data
  List<NewsArticle> _getSampleNewsArticles() {
    return [
      NewsArticle(
        id: '1',
        title: 'Manchester City Dominates Derby Match',
        summary: 'City secures a convincing 3-1 victory over United in the Manchester derby.',
        content: 'In a thrilling Manchester derby, City showcased their superior tactics and individual brilliance...',
        author: 'John Smith',
        category: 'football',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'ESPN',
        sourceUrl: 'https://twitter.com/espn/status/1234567890',
        imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      ),
      NewsArticle(
        id: '2',
        title: 'LeBron Leads Lakers to Victory',
        summary: 'LeBron James scores 35 points as Lakers defeat Nuggets 101-100.',
        content: 'LeBron James delivered a masterclass performance, leading the Lakers to a nail-biting victory...',
        author: 'Maria Rodriguez',
        category: 'basketball',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        source: 'NBA.com',
        sourceUrl: 'https://www.nba.com/lakers/news/game-recap-2024',
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
      ),
      NewsArticle(
        id: '3',
        title: 'Tennis Championship Update',
        summary: 'Novak Djokovic advances to the semifinals after a hard-fought match.',
        content: 'World number one Novak Djokovic continues his quest for another Grand Slam title...',
        author: 'David Wilson',
        category: 'tennis',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        source: 'Tennis.com',
        sourceUrl: 'https://www.tennis.com/news/djokovic-semifinals-2024',
        imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800',
      ),
    ];
  }

  /// Sample matches data
  List<Match> _getSampleMatches() {
    return [
      Match(
        id: '1',
        homeTeam: 'Toronto Maple Leafs',
        awayTeam: 'Boston Bruins',
        status: 'upcoming',
        date: DateTime.now().add(const Duration(days: 1)),
        league: 'NHL',
        venue: 'Scotiabank Arena',
      ),
      Match(
        id: '2',
        homeTeam: 'India',
        awayTeam: 'Australia',
        status: 'live',
        date: DateTime.now(),
        league: 'ICC',
        venue: 'Melbourne Cricket Ground',
        homeScore: 285,
        awayScore: 320,
      ),
    ];
  }
}