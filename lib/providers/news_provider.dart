import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../models/sports_team.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../services/firebase_data_service.dart';
import '../services/firebase_service.dart';
import '../services/tournament_service.dart';
import '../services/debug_logger.dart';

class NewsProvider with ChangeNotifier {
  List<NewsArticle> _articles = [];
  List<NewsArticle> _originalArticles = []; // Cache original articles
  List<Match> _upcomingMatches = [];
  List<Match> _liveMatches = [];
  List<Tournament> _liveTournaments = [];
  Map<String, String> _athleteNames = {}; // Cache athlete names by ID
  bool _isLoading = false;
  bool _isRefreshing = false; // Non-blocking background refresh
  String? _error;
  String _selectedCategory = 'all';
  String? _selectedTournamentId;
  String _searchQuery = '';
  DateTime? _lastLoadTime; // Track when articles were last loaded
  static const Duration _cacheValidDuration = Duration(minutes: 2); // Cache for 2 minutes (faster updates for live app)

  // Getters
  List<NewsArticle> get articles => _articles;
  List<Match> get upcomingMatches => _upcomingMatches;
  List<Match> get liveMatches => _liveMatches;
  List<Tournament> get liveTournaments => _liveTournaments;
  Map<String, String> get athleteNames => _athleteNames;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String? get selectedTournamentId => _selectedTournamentId;
  String get searchQuery => _searchQuery;

  List<NewsArticle> get filteredArticles {
    List<NewsArticle> filtered = _articles;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((article) => 
          article.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filter by tournament
    if (_selectedTournamentId != null) {
      filtered = filtered.where((article) => 
          article.tournamentId == _selectedTournamentId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((article) =>
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.summary.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  List<NewsArticle> get breakingNews {
    return _articles.where((article) => article.isBreaking == true).toList();
  }

  List<NewsArticle> get featuredArticles {
    return _articles.take(3).toList();
  }

  // Methods
  Future<void> loadNews({bool forceRefresh = false}) async {
    DebugLogger.instance.logInfo('NewsProvider', 'loadNews called (forceRefresh: $forceRefresh)');
    
    // Check if we have cached data that's still valid
    if (!forceRefresh && _originalArticles.isNotEmpty && _lastLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastLoadTime!);
      if (cacheAge < _cacheValidDuration) {
        print('📋 Using cached articles (${_originalArticles.length} articles, age: ${cacheAge.inMinutes}m)');
        DebugLogger.instance.logWarning('NewsProvider', 'Using cached articles (${_originalArticles.length} articles, age: ${cacheAge.inMinutes}m)');
        _articles = List.from(_originalArticles);
        notifyListeners();
        return;
      } else {
        DebugLogger.instance.logInfo('NewsProvider', 'Cache expired (age: ${cacheAge.inMinutes}m), fetching fresh data');
      }
    }

    if (forceRefresh) {
      DebugLogger.instance.logInfo('NewsProvider', 'Force refresh requested - bypassing cache');
    }

    _setLoading(true);
    _clearError();

    try {
      // Wait for Firebase to be fully initialized before loading data
      print('🔄 NewsProvider: Waiting for Firebase to be ready...');
      
      // Give Firebase a moment to initialize if it hasn't already
      int retryCount = 0;
      while (!FirebaseService.instance.isFirebaseAvailable && retryCount < 10) {
        print('⏳ Firebase not ready yet, waiting... (attempt ${retryCount + 1}/10)');
        await Future.delayed(Duration(milliseconds: 500));
        retryCount++;
      }
      
      if (!FirebaseService.instance.isFirebaseAvailable && retryCount >= 10) {
        print('❌ Firebase failed to initialize after 5 seconds, using mock data');
      }
      
      // Load news articles first
      print('🔄 NewsProvider: Starting to load news articles...');
      DebugLogger.instance.logInfo('NewsProvider', 'Fetching fresh articles from Firebase...');
      
      _articles = await FirebaseDataService.instance.getNewsArticles();
      _originalArticles = List.from(_articles); // Cache the original articles
      _lastLoadTime = DateTime.now();
      
      // Check if we got mock data (sample IDs are '1', '2', '3', '4', '5' for mock data)
      final hasMockData = _articles.any((article) => 
        article.id == '1' || article.id == '2' || article.id == '3' || 
        article.id == '4' || article.id == '5' || article.id.startsWith('sample'));
        
      if (hasMockData) {
        print('⚠️ NewsProvider: Loaded ${_articles.length} MOCK articles - Firebase connection failed');
      } else {
        print('✅ NewsProvider: Loaded ${_articles.length} REAL articles from Firestore');
      }
      
      DebugLogger.instance.logSuccess('NewsProvider', 'Loaded ${_articles.length} articles from Firestore (fresh)');
      
      // Load live tournaments
      try {
        _liveTournaments = await TournamentService.instance.getLiveTournaments();
        print('Loaded ${_liveTournaments.length} live tournaments');
        DebugLogger.instance.logInfo('NewsProvider', 'Loaded ${_liveTournaments.length} live tournaments');
      } catch (tournamentError) {
        print('Failed to load tournaments: $tournamentError');
        DebugLogger.instance.logError('NewsProvider', 'Failed to load tournaments: $tournamentError');
        _liveTournaments = []; // Continue without tournaments
      }
      
      // Load athlete names for articles that have athleteId
      try {
        await _loadAthleteNames(_articles);
        print('Loaded athlete names for articles');
        DebugLogger.instance.logInfo('NewsProvider', 'Loaded athlete names for articles');
      } catch (athleteError) {
        print('Failed to load athlete names: $athleteError');
        DebugLogger.instance.logError('NewsProvider', 'Failed to load athlete names: $athleteError');
        // Continue without athlete names
      }
      
      notifyListeners();
    } catch (e) {
      DebugLogger.instance.logError('NewsProvider', 'Failed to load news: ${e.toString()}');
      _setError('Failed to load news: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMatches() async {
    try {
      // Try Firebase first, fallback to mock data
      final matches = await FirebaseDataService.instance.getMatches();
      
      // Separate upcoming and live matches
      _upcomingMatches = matches.where((match) => match.isUpcoming).toList();
      _liveMatches = matches.where((match) => match.isLive).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load matches: ${e.toString()}');
    }
  }

  Future<void> searchNews(String query) async {
    _searchQuery = query;
    notifyListeners();

    if (query.isEmpty) {
      // Clear search and reload all news
      await loadNews();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Try Firebase search first, fallback to mock data
      final results = await FirebaseDataService.instance.searchNews(query);
      _articles = results;
      notifyListeners();
    } catch (e) {
      _setError('Failed to search news: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<NewsArticle?> getArticleById(String id) async {
    try {
      // Try Firebase first, fallback to mock data
      return await FirebaseDataService.instance.getArticleById(id);
    } catch (e) {
      _setError('Failed to load article: ${e.toString()}');
      return null;
    }
  }

  /// Increment view count for a news article
  Future<void> incrementArticleViews(String articleId) async {
    try {
      await FirebaseDataService.instance.incrementArticleViews(articleId);
    } catch (e) {
      print('Failed to increment article views: ${e.toString()}');
      // Don't throw error - view tracking should be non-blocking
    }
  }

  /// Clear all cached data and force fresh load
  Future<void> clearCacheAndRefresh() async {
    DebugLogger.instance.logInfo('NewsProvider', 'Clearing cache and forcing refresh...');
    _originalArticles.clear();
    _articles.clear();
    _lastLoadTime = null;
    await loadNews(forceRefresh: true);
  }

  /// Clear cache without refreshing
  void clearCache() {
    DebugLogger.instance.logInfo('NewsProvider', 'Clearing news cache...');
    _originalArticles.clear();
    _lastLoadTime = null;
  }

  /// Get cache info for debugging
  String getCacheInfo() {
    if (_lastLoadTime == null) {
      return 'No cached data';
    }
    final cacheAge = DateTime.now().difference(_lastLoadTime!);
    return 'Cache age: ${cacheAge.inMinutes}m ${cacheAge.inSeconds % 60}s (${_originalArticles.length} articles)';
  }

  /// Increment like count for a news article
  Future<void> incrementArticleLikes(String articleId) async {
    try {
      await FirebaseDataService.instance.incrementArticleLikes(articleId);
    } catch (e) {
      print('Failed to increment article likes: ${e.toString()}');
      // Don't throw error - like tracking should be non-blocking
    }
  }

  /// Increment share count for a news article
  Future<void> incrementArticleShares(String articleId) async {
    try {
      await FirebaseDataService.instance.incrementArticleShares(articleId);
    } catch (e) {
      print('Failed to increment article shares: ${e.toString()}');
      // Don't throw error - share tracking should be non-blocking
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setTournamentFilter(String? tournamentId) {
    _selectedTournamentId = tournamentId;
    notifyListeners();
  }

  void clearTournamentFilter() {
    _selectedTournamentId = null;
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedCategory = 'all';
    _selectedTournamentId = null;
    _searchQuery = '';
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    // Don't reload - just restore from cache if available
    if (_originalArticles.isNotEmpty) {
      _articles = List.from(_originalArticles);
      print('Restored ${_articles.length} articles from cache');
    }
    notifyListeners();
  }

  void refresh() {
    DebugLogger.instance.logInfo('NewsProvider', 'Manual refresh triggered');
    loadNews(forceRefresh: true);
    loadMatches();
  }

  /// Non-blocking refresh that keeps existing content visible while loading new data
  Future<void> refreshInBackground() async {
    DebugLogger.instance.logInfo('NewsProvider', 'Background refresh triggered - non-blocking');
    
    if (_isRefreshing) {
      print('⚠️ Refresh already in progress, skipping duplicate request');
      return;
    }

    _setRefreshing(true);
    
    try {
      // Wait for Firebase to be ready (same logic as loadNews)
      int retryCount = 0;
      while (!FirebaseService.instance.isFirebaseAvailable && retryCount < 10) {
        print('⏳ Firebase not ready yet, waiting... (attempt ${retryCount + 1}/10)');
        await Future.delayed(Duration(milliseconds: 500));
        retryCount++;
      }
      
      // Load fresh articles in background
      final freshArticles = await FirebaseDataService.instance.getNewsArticles();
      
      // Update cached articles without blocking UI
      _articles = freshArticles;
      _originalArticles = List.from(freshArticles);
      _lastLoadTime = DateTime.now();
      
      final hasMockData = _articles.any((article) => 
        article.id == '1' || article.id == '2' || article.id == '3' || 
        article.id == '4' || article.id == '5' || article.id.startsWith('sample'));
        
      if (hasMockData) {
        print('⚠️ Background refresh: Loaded ${_articles.length} MOCK articles');
      } else {
        print('✅ Background refresh: Loaded ${_articles.length} REAL articles from Firestore');
      }
      
      DebugLogger.instance.logSuccess('NewsProvider', 'Background refresh completed with ${_articles.length} articles');
      _error = null; // Clear any previous errors
      
    } catch (e) {
      print('❌ Background refresh failed: $e');
      DebugLogger.instance.logError('NewsProvider', 'Background refresh failed: $e');
      // Don't set _error for background refresh failures to avoid disrupting user experience
    } finally {
      _setRefreshing(false);
    }
  }

  Future<void> _loadAthleteNames(List<NewsArticle> articles) async {
    // Extract unique athlete IDs from articles
    final athleteIds = articles
        .where((article) => article.athleteId != null && article.athleteId!.isNotEmpty)
        .map((article) => article.athleteId!)
        .toSet()
        .toList();

    if (athleteIds.isEmpty) return;

    try {
      // Fetch athlete data for each unique ID
      final athleteFutures = athleteIds.map((id) => TournamentService.instance.getAthleteById(id));
      final athletes = await Future.wait(athleteFutures);
      
      // Cache athlete names by ID
      for (int i = 0; i < athleteIds.length; i++) {
        final athlete = athletes[i];
        if (athlete != null) {
          _athleteNames[athleteIds[i]] = athlete.name;
        }
      }
    } catch (e) {
      print('Error loading athlete names: $e');
      // Don't fail the entire news loading if athlete names fail to load
    }
  }

  String? getAthleteNameById(String? athleteId) {
    if (athleteId == null || athleteId.isEmpty) return null;
    return _athleteNames[athleteId];
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
