import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_feed.dart';
import '../services/content_feed_service.dart';
import '../services/content_analytics_service.dart';

class ContentProvider with ChangeNotifier {
  // Content state
  List<ContentFeed> _allContent = [];
  List<ContentFeed> _filteredContent = [];
  List<ContentFeed> _favoriteContent = [];
  ContentFeed? _dailyTipContent;
  
  // User preferences
  Set<String> _favoriteIds = {};
  Set<String> _readIds = {};
  Map<String, int> _userLikes = {};
  
  // Search and filter state
  String _searchQuery = '';
  ContentType? _selectedContentType;
  String _selectedSport = 'All';
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingFavorites = false;
  String? _error;

  // Getters
  List<ContentFeed> get allContent => _allContent;
  List<ContentFeed> get filteredContent => _filteredContent;
  List<ContentFeed> get favoriteContent => _favoriteContent;
  ContentFeed? get dailyTipContent => _dailyTipContent;
  
  Set<String> get favoriteIds => _favoriteIds;
  Set<String> get readIds => _readIds;
  Map<String, int> get userLikes => _userLikes;
  
  String get searchQuery => _searchQuery;
  ContentType? get selectedContentType => _selectedContentType;
  String get selectedSport => _selectedSport;
  
  bool get isLoading => _isLoading;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get error => _error;

  /// Initialize the provider
  Future<void> initialize() async {
    await _loadUserPreferences();
    await loadContent();
    await loadDailyTip();
  }

  /// Load all published content
  Future<void> loadContent() async {
    try {
      _setLoading(true);
      _error = null;
      
      final content = await ContentFeedService.instance.getPublishedContentFeeds();
      _allContent = content;
      _applyFilters();
      
      print('✅ Loaded ${_allContent.length} content items');
    } catch (e) {
      _error = 'Failed to load content: $e';
      print('❌ Error loading content: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load daily tip content
  Future<void> loadDailyTip() async {
    try {
      final dailyTip = await ContentFeedService.instance.getLatestPublishedContent();
      _dailyTipContent = dailyTip;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading daily tip: $e');
    }
  }

  /// Load favorite content
  Future<void> loadFavoriteContent() async {
    try {
      _setLoadingFavorites(true);
      
      if (_favoriteIds.isEmpty) {
        _favoriteContent = [];
        return;
      }

      // Filter favorites from all content
      _favoriteContent = _allContent.where((content) => 
        _favoriteIds.contains(content.id)).toList();
      
      // Sort by most recently added to favorites
      _favoriteContent.sort((a, b) => b.publishedAt?.compareTo(a.publishedAt ?? DateTime.now()) ?? 0);
      
    } catch (e) {
      print('❌ Error loading favorite content: $e');
    } finally {
      _setLoadingFavorites(false);
    }
  }

  /// Search content
  Future<void> searchContent(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _applyFilters();
    } else {
      try {
        final searchResults = await ContentFeedService.instance.searchPublishedContent(query);
        _filteredContent = searchResults;
        _applyTypeAndSportFilters();
        notifyListeners();
      } catch (e) {
        print('❌ Error searching content: $e');
        _applyFilters();
      }
    }
  }

  /// Filter by content type
  void filterByType(ContentType? type) {
    _selectedContentType = type;
    _applyFilters();
  }

  /// Filter by sport
  void filterBySport(String sport) {
    _selectedSport = sport;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedContentType = null;
    _selectedSport = 'All';
    _applyFilters();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String contentId) async {
    try {
      final content = _allContent.firstWhere((c) => c.id == contentId);
      
      if (_favoriteIds.contains(contentId)) {
        _favoriteIds.remove(contentId);
        _favoriteContent.removeWhere((c) => c.id == contentId);
        
        // Track unfavorite
        ContentAnalyticsService.instance.trackContentBookmark(
          contentId, content.type, false);
      } else {
        _favoriteIds.add(contentId);
        _favoriteContent.add(content);
        
        // Track favorite
        ContentAnalyticsService.instance.trackContentBookmark(
          contentId, content.type, true);
      }

      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling favorite: $e');
    }
  }

  /// Mark content as read
  Future<void> markAsRead(String contentId) async {
    if (_readIds.contains(contentId)) return;
    
    try {
      _readIds.add(contentId);
      await _saveReadStatus();
      
      // Track view
      final content = _allContent.firstWhere((c) => c.id == contentId);
      ContentAnalyticsService.instance.trackContentView(contentId, content.type);
      
      notifyListeners();
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  /// Like content
  Future<void> likeContent(String contentId) async {
    try {
      _userLikes[contentId] = (_userLikes[contentId] ?? 0) + 1;
      await _saveLikes();
      
      // Track like
      final content = _allContent.firstWhere((c) => c.id == contentId);
      ContentAnalyticsService.instance.trackContentLike(contentId, content.type);
      
      notifyListeners();
    } catch (e) {
      print('❌ Error liking content: $e');
    }
  }

  /// Share content
  Future<void> shareContent(String contentId, String shareMethod) async {
    try {
      // Track share
      final content = _allContent.firstWhere((c) => c.id == contentId);
      ContentAnalyticsService.instance.trackContentShare(contentId, content.type, shareMethod);
      
      print('📤 Content shared: $contentId via $shareMethod');
    } catch (e) {
      print('❌ Error sharing content: $e');
    }
  }

  /// Get personalized recommendations
  Future<List<ContentFeed>> getPersonalizedRecommendations() async {
    try {
      // This will be implemented in Phase 3
      // For now, return popular content
      final sortedContent = List<ContentFeed>.from(_allContent);
      sortedContent.sort((a, b) => (b.viewCount + b.likeCount).compareTo(a.viewCount + a.likeCount));
      return sortedContent.take(10).toList();
    } catch (e) {
      print('❌ Error getting recommendations: $e');
      return [];
    }
  }

  /// Get user engagement statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final stats = await ContentAnalyticsService.instance.getUserEngagementStats('current_user');
      return {
        ...stats,
        'total_favorites': _favoriteIds.length,
        'total_read': _readIds.length,
        'total_likes_given': _userLikes.values.fold(0, (sum, likes) => sum + likes),
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {};
    }
  }

  /// Private methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingFavorites(bool loading) {
    _isLoadingFavorites = loading;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredContent = _allContent;
    _applyTypeAndSportFilters();
    notifyListeners();
  }

  void _applyTypeAndSportFilters() {
    if (_selectedContentType != null) {
      _filteredContent = _filteredContent.where((content) => 
        content.type == _selectedContentType).toList();
    }

    if (_selectedSport != 'All') {
      _filteredContent = _filteredContent.where((content) => 
        content.sportCategory.toLowerCase() == _selectedSport.toLowerCase()).toList();
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final favoritesList = prefs.getStringList('favorite_content') ?? [];
      _favoriteIds = Set.from(favoritesList);
      
      final readList = prefs.getStringList('read_content') ?? [];
      _readIds = Set.from(readList);
      
      final likesData = prefs.getStringList('user_likes') ?? [];
      _userLikes = {};
      for (final item in likesData) {
        final parts = item.split(':');
        if (parts.length == 2) {
          _userLikes[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
      
      print('✅ Loaded user preferences: ${_favoriteIds.length} favorites, ${_readIds.length} read');
    } catch (e) {
      print('❌ Error loading user preferences: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_content', _favoriteIds.toList());
    } catch (e) {
      print('❌ Error saving favorites: $e');
    }
  }

  Future<void> _saveReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_content', _readIds.toList());
    } catch (e) {
      print('❌ Error saving read status: $e');
    }
  }

  Future<void> _saveLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesData = _userLikes.entries.map((e) => '${e.key}:${e.value}').toList();
      await prefs.setStringList('user_likes', likesData);
    } catch (e) {
      print('❌ Error saving likes: $e');
    }
  }

  /// Refresh content
  Future<void> refresh() async {
    await loadContent();
    await loadDailyTip();
  }

  /// Clear all user data
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('favorite_content');
      await prefs.remove('read_content');
      await prefs.remove('user_likes');
      
      _favoriteIds.clear();
      _readIds.clear();
      _userLikes.clear();
      _favoriteContent.clear();
      
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }
}
