import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/content_feed.dart';

class ContentAnalyticsService {
  static ContentAnalyticsService? _instance;
  static ContentAnalyticsService get instance => _instance ??= ContentAnalyticsService._internal();
  
  ContentAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Track when a user views content
  Future<void> trackContentView(String contentId, ContentType contentType) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Update content view count
      await _firestore.collection('content_feeds').doc(contentId).update({
        'view_count': FieldValue.increment(1),
        'last_viewed_at': FieldValue.serverTimestamp(),
      });

      // Track user interaction
      await _trackUserInteraction(
        userId: userId,
        contentId: contentId,
        action: 'view',
        contentType: contentType,
      );

      // Store locally for offline tracking
      await _storeLocalInteraction('view', contentId, contentType.toString());
      
      print('📊 Content view tracked: $contentId');
    } catch (e) {
      print('❌ Error tracking content view: $e');
    }
  }

  /// Track when a user likes content
  Future<void> trackContentLike(String contentId, ContentType contentType) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Update content like count
      await _firestore.collection('content_feeds').doc(contentId).update({
        'like_count': FieldValue.increment(1),
      });

      // Track user interaction
      await _trackUserInteraction(
        userId: userId,
        contentId: contentId,
        action: 'like',
        contentType: contentType,
      );

      // Store locally for offline tracking
      await _storeLocalInteraction('like', contentId, contentType.toString());
      
      print('❤️ Content like tracked: $contentId');
    } catch (e) {
      print('❌ Error tracking content like: $e');
    }
  }

  /// Track when a user shares content
  Future<void> trackContentShare(String contentId, ContentType contentType, String shareMethod) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Update content share count
      await _firestore.collection('content_feeds').doc(contentId).update({
        'share_count': FieldValue.increment(1),
      });

      // Track user interaction with share method
      await _trackUserInteraction(
        userId: userId,
        contentId: contentId,
        action: 'share',
        contentType: contentType,
        metadata: {'share_method': shareMethod},
      );

      // Store locally for offline tracking
      await _storeLocalInteraction('share', contentId, contentType.toString(), shareMethod);
      
      print('📤 Content share tracked: $contentId via $shareMethod');
    } catch (e) {
      print('❌ Error tracking content share: $e');
    }
  }

  /// Track when a user bookmarks content
  Future<void> trackContentBookmark(String contentId, ContentType contentType, bool isBookmarked) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final action = isBookmarked ? 'bookmark' : 'unbookmark';

      // Track user interaction
      await _trackUserInteraction(
        userId: userId,
        contentId: contentId,
        action: action,
        contentType: contentType,
      );

      // Store locally for offline tracking
      await _storeLocalInteraction(action, contentId, contentType.toString());
      
      print('🔖 Content bookmark tracked: $contentId ($action)');
    } catch (e) {
      print('❌ Error tracking content bookmark: $e');
    }
  }

  /// Get user's content engagement stats
  Future<Map<String, dynamic>> getUserEngagementStats(String userId) async {
    try {
      final userInteractionsRef = _firestore
          .collection('user_interactions')
          .where('user_id', isEqualTo: userId);

      final viewsQuery = await userInteractionsRef.where('action', isEqualTo: 'view').get();
      final likesQuery = await userInteractionsRef.where('action', isEqualTo: 'like').get();
      final sharesQuery = await userInteractionsRef.where('action', isEqualTo: 'share').get();
      final bookmarksQuery = await userInteractionsRef.where('action', isEqualTo: 'bookmark').get();

      final engagementBySport = await _analyzeEngagementBySport(viewsQuery.docs);
      
      final stats = {
        'total_views': viewsQuery.docs.length,
        'total_likes': likesQuery.docs.length,
        'total_shares': sharesQuery.docs.length,
        'total_bookmarks': bookmarksQuery.docs.length,
        'favorite_content_types': _analyzeFavoriteContentTypes(viewsQuery.docs),
        'engagement_by_sport': engagementBySport,
      };

      return stats;
    } catch (e) {
      print('❌ Error getting user engagement stats: $e');
      return {
        'total_views': 0,
        'total_likes': 0,
        'total_shares': 0,
        'total_bookmarks': 0,
        'favorite_content_types': <String, int>{},
        'engagement_by_sport': <String, int>{},
      };
    }
  }

  /// Get content performance analytics (for admin)
  Future<Map<String, dynamic>> getContentPerformanceStats() async {
    try {
      final contentFeedsRef = _firestore
          .collection('content_feeds')
          .where('status', isEqualTo: 'published');

      final snapshot = await contentFeedsRef.get();
      
      int totalViews = 0;
      int totalLikes = 0;
      int totalShares = 0;
      Map<String, int> performanceBySport = {};
      Map<String, int> performanceByType = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final views = data['view_count'] ?? 0;
        final likes = data['like_count'] ?? 0;
        final shares = data['share_count'] ?? 0;
        final sport = data['sport_category'] ?? 'Unknown';
        final type = data['type'] ?? 'Unknown';

        totalViews += views as int;
        totalLikes += likes as int;
        totalShares += shares as int;
        
        performanceBySport[sport] = (performanceBySport[sport] ?? 0) + views;
        performanceByType[type] = (performanceByType[type] ?? 0) + views;
      }

      return {
        'total_content': snapshot.docs.length,
        'total_views': totalViews,
        'total_likes': totalLikes,
        'total_shares': totalShares,
        'performance_by_sport': performanceBySport,
        'performance_by_type': performanceByType,
        'average_views_per_content': snapshot.docs.isNotEmpty ? totalViews / snapshot.docs.length : 0,
      };
    } catch (e) {
      print('❌ Error getting content performance stats: $e');
      return {};
    }
  }

  /// Get personalized content recommendations (Phase 3)
  Future<List<String>> getPersonalizedRecommendations(String userId) async {
    try {
      final stats = await getUserEngagementStats(userId);
      final favoriteTypes = stats['favorite_content_types'] as Map<String, int>;
      final favoriteSports = stats['engagement_by_sport'] as Map<String, int>;

      // Get top content types and sports user engages with
      final topContentTypes = favoriteTypes.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();

      final topSports = favoriteSports.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();

      if (topContentTypes.isEmpty && topSports.isEmpty) {
        // New user - return popular content
        return _getPopularContent();
      }

      // Query for recommended content
      Query query = _firestore
          .collection('content_feeds')
          .where('status', isEqualTo: 'published')
          .orderBy('view_count', descending: true)
          .limit(10);

      if (topContentTypes.isNotEmpty) {
        query = query.where('type', whereIn: topContentTypes);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error getting personalized recommendations: $e');
      return _getPopularContent();
    }
  }

  /// Private helper methods

  Future<void> _trackUserInteraction({
    required String userId,
    required String contentId,
    required String action,
    required ContentType contentType,
    Map<String, dynamic>? metadata,
  }) async {
    await _firestore.collection('user_interactions').add({
      'user_id': userId,
      'content_id': contentId,
      'action': action,
      'content_type': contentType.toFirestore(),
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  Future<void> _storeLocalInteraction(String action, String contentId, String contentType, [String? extra]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'interactions_${DateTime.now().millisecondsSinceEpoch}';
      final value = '$action|$contentId|$contentType${extra != null ? '|$extra' : ''}';
      await prefs.setString(key, value);
    } catch (e) {
      print('Error storing local interaction: $e');
    }
  }

  Map<String, int> _analyzeFavoriteContentTypes(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> typeCount = {};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final contentType = data['content_type'] ?? 'unknown';
      typeCount[contentType] = (typeCount[contentType] ?? 0) + 1;
    }
    return typeCount;
  }

  Future<Map<String, int>> _analyzeEngagementBySport(List<QueryDocumentSnapshot> docs) async {
    final Map<String, int> sportCount = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final contentId = data['content_id'] as String;
      
      // Get the content to find sport category
      try {
        final contentDoc = await _firestore.collection('content_feeds').doc(contentId).get();
        if (contentDoc.exists) {
          final contentData = contentDoc.data() as Map<String, dynamic>;
          final sport = contentData['sport_category'] ?? 'unknown';
          sportCount[sport] = (sportCount[sport] ?? 0) + 1;
        }
      } catch (e) {
        print('Error getting content sport: $e');
      }
    }
    
    return sportCount;
  }

  Future<List<String>> _getPopularContent() async {
    try {
      final snapshot = await _firestore
          .collection('content_feeds')
          .where('status', isEqualTo: 'published')
          .orderBy('view_count', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting popular content: $e');
      return [];
    }
  }

  /// Sync offline interactions when online (Phase 3)
  Future<void> syncOfflineInteractions() async {
    try {
      if (!_authService.isSignedIn) return;

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('interactions_')).toList();
      
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value == null) continue;
        
        final parts = value.split('|');
        if (parts.length >= 3) {
          final action = parts[0];
          final contentId = parts[1];
          final contentType = parts[2];
          final extra = parts.length > 3 ? parts[3] : null;
          
          try {
            switch (action) {
              case 'view':
                await trackContentView(contentId, ContentType.fromString(contentType));
                break;
              case 'like':
                await trackContentLike(contentId, ContentType.fromString(contentType));
                break;
              case 'share':
                await trackContentShare(contentId, ContentType.fromString(contentType), extra ?? 'unknown');
                break;
              case 'bookmark':
                await trackContentBookmark(contentId, ContentType.fromString(contentType), true);
                break;
            }
            
            // Remove synced interaction
            await prefs.remove(key);
            print('✅ Synced offline interaction: $action for $contentId');
          } catch (e) {
            print('❌ Error syncing interaction: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error syncing offline interactions: $e');
    }
  }
}
