import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarked_articles';
  static BookmarkService? _instance;

  static BookmarkService get instance {
    _instance ??= BookmarkService._();
    return _instance!;
  }

  BookmarkService._();

  // Get all bookmarked articles
  Future<List<NewsArticle>> getBookmarkedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
      
      return bookmarksJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return NewsArticle.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error loading bookmarks: $e');
      return [];
    }
  }

  // Add article to bookmarks
  Future<bool> addBookmark(NewsArticle article) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
      
      // Check if article is already bookmarked
      final existingIds = await getBookmarkedArticleIds();
      if (existingIds.contains(article.id)) {
        return false; // Already bookmarked
      }
      
      // Add new bookmark
      bookmarksJson.add(jsonEncode(article.toJson()));
      await prefs.setStringList(_bookmarksKey, bookmarksJson);
      return true;
    } catch (e) {
      print('Error adding bookmark: $e');
      return false;
    }
  }

  // Remove article from bookmarks
  Future<bool> removeBookmark(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
      
      // Find and remove the bookmark
      bookmarksJson.removeWhere((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['id'] == articleId;
      });
      
      await prefs.setStringList(_bookmarksKey, bookmarksJson);
      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }

  // Check if article is bookmarked
  Future<bool> isBookmarked(String articleId) async {
    try {
      final bookmarkedIds = await getBookmarkedArticleIds();
      return bookmarkedIds.contains(articleId);
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  // Get list of bookmarked article IDs
  Future<List<String>> getBookmarkedArticleIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
      
      return bookmarksJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['id'] as String;
      }).toList();
    } catch (e) {
      print('Error loading bookmark IDs: $e');
      return [];
    }
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
      return true;
    } catch (e) {
      print('Error clearing bookmarks: $e');
      return false;
    }
  }

  // Get bookmark count
  Future<int> getBookmarkCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
      return bookmarksJson.length;
    } catch (e) {
      print('Error getting bookmark count: $e');
      return 0;
    }
  }
}
