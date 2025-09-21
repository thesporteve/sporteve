import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../models/sports_team.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../services/firebase_data_service.dart';
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
  String? _error;
  String _selectedCategory = 'all';
  String? _selectedTournamentId;
  String _searchQuery = '';
  DateTime? _lastLoadTime; // Track when articles were last loaded
  static const Duration _cacheValidDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Getters
  List<NewsArticle> get articles => _articles;
  List<Match> get upcomingMatches => _upcomingMatches;
  List<Match> get liveMatches => _liveMatches;
  List<Tournament> get liveTournaments => _liveTournaments;
  Map<String, String> get athleteNames => _athleteNames;
  bool get isLoading => _isLoading;
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
      // Load news articles first
      DebugLogger.instance.logInfo('NewsProvider', 'Fetching fresh articles from Firebase...');
      _articles = await FirebaseDataService.instance.getNewsArticles();
      _originalArticles = List.from(_articles); // Cache the original articles
      _lastLoadTime = DateTime.now();
      print('✅ Loaded ${_articles.length} articles from Firestore (fresh)');
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

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
