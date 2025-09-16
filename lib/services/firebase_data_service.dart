import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';
import '../models/match.dart';
import 'firebase_service.dart';

/// Data service for handling news articles and matches
/// Uses Firestore when available, falls back to mock data
class FirebaseDataService {
  static FirebaseDataService? _instance;
  static FirebaseDataService get instance => _instance ??= FirebaseDataService._();
  
  FirebaseDataService._();
  
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Get news articles from Firestore or mock data
  Future<List<NewsArticle>> getNewsArticles() async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        return _getMockNewsArticles();
      }

      // Try to fetch from Firestore
      QuerySnapshot snapshot = await _firebaseService.firestore
          .collection('news_articles')
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<NewsArticle> articles = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return NewsArticle.fromFirestore(doc.id, data);
        }).toList();
        
        return articles;
      } else {
        // No articles in Firestore, return mock data
        return _getMockNewsArticles();
      }
    } catch (e) {
      print('Failed to fetch news articles from Firestore: $e');
      return _getMockNewsArticles();
    }
  }

  /// Get matches from Firestore or mock data
  Future<List<Match>> getMatches() async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        return _getMockMatches();
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
        // No matches in Firestore, return mock data
        return _getMockMatches();
      }
    } catch (e) {
      print('Failed to fetch matches from Firestore: $e');
      return _getMockMatches();
    }
  }

  /// Search news articles from Firestore or mock data
  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      if (!_firebaseService.isFirebaseAvailable) {
        return _searchMockData(query);
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
        return _searchMockData(query);
      }
    } catch (e) {
      print('Failed to search news articles in Firestore: $e');
      return _searchMockData(query);
    }
  }

  /// Search mock data (fallback method)
  List<NewsArticle> _searchMockData(String query) {
    final articles = _getMockNewsArticles();
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
        final articles = _getMockNewsArticles();
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
        final articles = _getMockNewsArticles();
        final matches = articles.where((article) => article.id == id).toList();
        return matches.isEmpty ? null : matches.first;
      }
    } catch (e) {
      print('Failed to fetch article by ID from Firestore: $e');
      final articles = _getMockNewsArticles();
      final matches = articles.where((article) => article.id == id).toList();
      return matches.isEmpty ? null : matches.first;
    }
  }

  /// Mock news articles data
  List<NewsArticle> _getMockNewsArticles() {
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
        // tags and readTime removed per user request
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
        // tags and readTime removed per user request
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
        // tags and readTime removed per user request
      ),
    ];
  }

  /// Mock matches data
  List<Match> _getMockMatches() {
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