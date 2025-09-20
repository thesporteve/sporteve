import 'package:shared_preferences/shared_preferences.dart';

class LikeService {
  static LikeService? _instance;
  static LikeService get instance => _instance ??= LikeService._internal();
  
  LikeService._internal();

  static const String _likedArticlesKey = 'liked_articles';

  /// Check if an article is liked by the current user
  Future<bool> isArticleLiked(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedArticles = prefs.getStringList(_likedArticlesKey) ?? [];
      return likedArticles.contains(articleId);
    } catch (e) {
      print('Error checking if article is liked: $e');
      return false;
    }
  }

  /// Get all liked article IDs
  Future<List<String>> getLikedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_likedArticlesKey) ?? [];
    } catch (e) {
      print('Error getting liked articles: $e');
      return [];
    }
  }

  /// Like an article (add to liked list)
  Future<bool> likeArticle(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> likedArticles = prefs.getStringList(_likedArticlesKey) ?? [];
      
      if (!likedArticles.contains(articleId)) {
        likedArticles.add(articleId);
        await prefs.setStringList(_likedArticlesKey, likedArticles);
        return true; // Successfully liked
      }
      return false; // Already liked
    } catch (e) {
      print('Error liking article: $e');
      return false;
    }
  }

  /// Unlike an article (remove from liked list)
  Future<bool> unlikeArticle(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> likedArticles = prefs.getStringList(_likedArticlesKey) ?? [];
      
      if (likedArticles.contains(articleId)) {
        likedArticles.remove(articleId);
        await prefs.setStringList(_likedArticlesKey, likedArticles);
        return true; // Successfully unliked
      }
      return false; // Wasn't liked
    } catch (e) {
      print('Error unliking article: $e');
      return false;
    }
  }

  /// Toggle like status for an article
  Future<bool> toggleLike(String articleId) async {
    final isLiked = await isArticleLiked(articleId);
    if (isLiked) {
      await unlikeArticle(articleId);
      return false; // Now unliked
    } else {
      await likeArticle(articleId);
      return true; // Now liked
    }
  }

  /// Clear all liked articles (for testing or reset)
  Future<void> clearAllLikedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_likedArticlesKey);
    } catch (e) {
      print('Error clearing liked articles: $e');
    }
  }
}
