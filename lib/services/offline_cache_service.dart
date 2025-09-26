import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_feed.dart';
import '../services/content_feed_service.dart';

class OfflineCacheService {
  static OfflineCacheService? _instance;
  static OfflineCacheService get instance => _instance ??= OfflineCacheService._internal();
  
  OfflineCacheService._internal();

  static const String _cacheVersion = '1.0';
  static const String _contentCacheKey = 'cached_content_feeds';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _cacheVersionKey = 'cache_version';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// Cache content feeds locally
  Future<void> cacheContent(List<ContentFeed> contentFeeds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert content to JSON
      final contentJson = contentFeeds.map((content) => {
        'id': content.id,
        'type': content.type.toFirestore(),
        'status': content.status.toFirestore(),
        'sport_category': content.sportCategory,
        'content': _extractContentData(content),
        'generation_source': content.generationSource,
        'source_sport_wiki_id': content.sourceSportsWikiId,
        'ai_prompt_used': content.aiPromptUsed,
        'created_at': content.createdAt.toIso8601String(),
        'approved_at': content.approvedAt?.toIso8601String(),
        'approved_by': content.approvedBy,
        'published_at': content.publishedAt?.toIso8601String(),
        'view_count': content.viewCount,
        'like_count': content.likeCount,
      }).toList();

      // Save to preferences
      await prefs.setString(_contentCacheKey, jsonEncode(contentJson));
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_cacheVersionKey, _cacheVersion);
      
      // Also save to file system for larger data
      await _saveCacheToFile(contentJson);
      
      print('✅ Cached ${contentFeeds.length} content items');
    } catch (e) {
      print('❌ Error caching content: $e');
    }
  }

  /// Retrieve cached content
  Future<List<ContentFeed>?> getCachedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final cachedVersion = prefs.getString(_cacheVersionKey);
      if (cachedVersion != _cacheVersion) {
        print('🗑️ Cache version mismatch, clearing cache');
        await clearCache();
        return null;
      }

      // Check cache timestamp
      final timestampString = prefs.getString(_cacheTimestampKey);
      if (timestampString == null) return null;
      
      final cacheTimestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(cacheTimestamp) > _cacheValidDuration) {
        print('⏰ Cache expired, clearing cache');
        await clearCache();
        return null;
      }

      // Try to load from preferences first (smaller data)
      final cachedDataString = prefs.getString(_contentCacheKey);
      List<dynamic> cachedData;
      
      if (cachedDataString != null) {
        cachedData = jsonDecode(cachedDataString);
      } else {
        // Fallback to file system
        cachedData = await _loadCacheFromFile();
        if (cachedData.isEmpty) return null;
      }

      // Convert back to ContentFeed objects
      final contentFeeds = cachedData.map((item) => _createContentFeedFromCache(item)).toList();
      
      print('✅ Loaded ${contentFeeds.length} items from cache');
      return contentFeeds;
    } catch (e) {
      print('❌ Error loading cached content: $e');
      return null;
    }
  }

  /// Cache specific content for offline reading
  Future<void> cacheForOfflineReading(List<String> contentIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('offline_reading_cache', contentIds);
      
      // Mark these content items for priority caching
      final allContent = await ContentFeedService.instance.getPublishedContentFeeds();
      final priorityContent = allContent.where((content) => contentIds.contains(content.id)).toList();
      
      await _savePriorityContent(priorityContent);
      
      print('✅ Cached ${priorityContent.length} items for offline reading');
    } catch (e) {
      print('❌ Error caching for offline reading: $e');
    }
  }

  /// Get offline reading content
  Future<List<ContentFeed>> getOfflineReadingContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedIds = prefs.getStringList('offline_reading_cache') ?? [];
      
      if (cachedIds.isEmpty) return [];
      
      final priorityContent = await _loadPriorityContent();
      return priorityContent.where((content) => cachedIds.contains(content.id)).toList();
    } catch (e) {
      print('❌ Error loading offline reading content: $e');
      return [];
    }
  }

  /// Check if content is available offline
  Future<bool> isContentAvailableOffline(String contentId) async {
    try {
      final cachedContent = await getCachedContent();
      if (cachedContent == null) return false;
      
      return cachedContent.any((content) => content.id == contentId);
    } catch (e) {
      print('❌ Error checking offline availability: $e');
      return false;
    }
  }

  /// Get cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_cacheTimestampKey);
      final cachedContent = await getCachedContent();
      
      final cacheSize = await _calculateCacheSize();
      
      return {
        'has_cache': cachedContent != null,
        'cache_timestamp': timestampString,
        'cached_items': cachedContent?.length ?? 0,
        'cache_size_mb': cacheSize,
        'cache_valid': timestampString != null && 
          DateTime.now().difference(DateTime.parse(timestampString)) <= _cacheValidDuration,
        'cache_version': _cacheVersion,
      };
    } catch (e) {
      print('❌ Error getting cache info: $e');
      return {
        'has_cache': false,
        'cached_items': 0,
        'cache_size_mb': 0.0,
        'cache_valid': false,
      };
    }
  }

  /// Clear all cached content
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contentCacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_cacheVersionKey);
      await prefs.remove('offline_reading_cache');
      
      // Clear file system cache
      await _clearCacheFiles();
      
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Update cache in background
  Future<void> updateCacheInBackground() async {
    try {
      final contentFeeds = await ContentFeedService.instance.getPublishedContentFeeds();
      await cacheContent(contentFeeds);
    } catch (e) {
      print('❌ Error updating cache in background: $e');
    }
  }

  /// Private helper methods

  Map<String, dynamic> _extractContentData(ContentFeed content) {
    switch (content.type) {
      case ContentType.parentTip:
        final tip = content.parentTipContent;
        return tip != null ? {
          'title': tip.title,
          'content': tip.content,
        } : {};
      case ContentType.didYouKnow:
        final fact = content.didYouKnowContent;
        return fact != null ? {
          'fact': fact.fact,
          'details': fact.details,
        } : {};
      case ContentType.trivia:
        final trivia = content.triviaContent;
        return trivia != null ? {
          'question': trivia.question,
          'options': trivia.options,
          'correct_answer': trivia.correctAnswer,
          'explanation': trivia.explanation,
        } : {};
    }
  }

  ContentFeed _createContentFeedFromCache(Map<String, dynamic> data) {
    final contentType = ContentType.fromString(data['type'] ?? 'parent_tip');
    final contentData = data['content'] as Map<String, dynamic>? ?? {};

    return ContentFeed(
      id: data['id'] ?? '',
      type: contentType,
      status: ContentStatus.fromString(data['status'] ?? 'published'),
      sportCategory: data['sport_category'] ?? '',
      parentTipContent: contentType == ContentType.parentTip && contentData.isNotEmpty
          ? ParentTipContent(
              title: contentData['title'] ?? '',
              content: contentData['content'] ?? '',
              benefits: List<String>.from(contentData['benefits'] ?? []),
              ageGroup: contentData['age_group'] ?? 'All Ages',
            )
          : null,
      didYouKnowContent: contentType == ContentType.didYouKnow && contentData.isNotEmpty
          ? DidYouKnowContent(
              fact: contentData['fact'] ?? '',
              details: contentData['details'] ?? '',
              category: contentData['category'] ?? 'General',
            )
          : null,
      triviaContent: contentType == ContentType.trivia && contentData.isNotEmpty
          ? TriviaContent(
              question: contentData['question'] ?? '',
              options: List<String>.from(contentData['options'] ?? []),
              correctAnswer: contentData['correct_answer'] ?? '',
              explanation: contentData['explanation'] ?? '',
              difficulty: DifficultyLevel.fromString(contentData['difficulty'] ?? 'medium'),
            )
          : null,
      generationSource: data['generation_source'] ?? '',
      sourceSportsWikiId: data['source_sport_wiki_id'],
      aiPromptUsed: data['ai_prompt_used'],
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      approvedAt: data['approved_at'] != null ? DateTime.parse(data['approved_at']) : null,
      approvedBy: data['approved_by'],
      publishedAt: data['published_at'] != null ? DateTime.parse(data['published_at']) : null,
      viewCount: data['view_count'] ?? 0,
      likeCount: data['like_count'] ?? 0,
    );
  }

  Future<void> _saveCacheToFile(List<Map<String, dynamic>> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final file = File('${cacheDir.path}/content_cache.json');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('❌ Error saving cache to file: $e');
    }
  }

  Future<List<dynamic>> _loadCacheFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cache/content_cache.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      print('❌ Error loading cache from file: $e');
    }
    return [];
  }

  Future<void> _savePriorityContent(List<ContentFeed> content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final contentJson = content.map((item) => {
        'id': item.id,
        'type': item.type.toFirestore(),
        'status': item.status.toFirestore(),
        'sport_category': item.sportCategory,
        'content': _extractContentData(item),
        'created_at': item.createdAt.toIso8601String(),
        'published_at': item.publishedAt?.toIso8601String(),
        'view_count': item.viewCount,
        'like_count': item.likeCount,
      }).toList();
      
      final file = File('${cacheDir.path}/priority_content.json');
      await file.writeAsString(jsonEncode(contentJson));
    } catch (e) {
      print('❌ Error saving priority content: $e');
    }
  }

  Future<List<ContentFeed>> _loadPriorityContent() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cache/priority_content.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as List<dynamic>;
        return data.map((item) => _createContentFeedFromCache(item)).toList();
      }
    } catch (e) {
      print('❌ Error loading priority content: $e');
    }
    return [];
  }

  Future<double> _calculateCacheSize() async {
    try {
      double totalSize = 0;
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }
      }
      
      // Convert to MB
      return totalSize / (1024 * 1024);
    } catch (e) {
      print('❌ Error calculating cache size: $e');
      return 0.0;
    }
  }

  Future<void> _clearCacheFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      print('❌ Error clearing cache files: $e');
    }
  }
}
