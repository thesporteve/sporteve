import 'package:shared_preferences/shared_preferences.dart';

class ContentLikeService {
  static ContentLikeService? _instance;
  static ContentLikeService get instance => _instance ??= ContentLikeService._internal();
  
  ContentLikeService._internal();

  static const String _likedContentKey = 'liked_content_feeds';

  /// Check if a content feed is liked by the current user
  Future<bool> isContentLiked(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedContent = prefs.getStringList(_likedContentKey) ?? [];
      return likedContent.contains(contentId);
    } catch (e) {
      print('Error checking if content is liked: $e');
      return false;
    }
  }

  /// Get all liked content IDs
  Future<List<String>> getLikedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_likedContentKey) ?? [];
    } catch (e) {
      print('Error getting liked content: $e');
      return [];
    }
  }

  /// Like a content feed (add to liked list)
  Future<bool> likeContent(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> likedContent = prefs.getStringList(_likedContentKey) ?? [];
      
      if (!likedContent.contains(contentId)) {
        likedContent.add(contentId);
        await prefs.setStringList(_likedContentKey, likedContent);
        return true; // Successfully liked
      }
      return false; // Already liked
    } catch (e) {
      print('Error liking content: $e');
      return false;
    }
  }

  /// Unlike a content feed (remove from liked list)
  Future<bool> unlikeContent(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> likedContent = prefs.getStringList(_likedContentKey) ?? [];
      
      if (likedContent.contains(contentId)) {
        likedContent.remove(contentId);
        await prefs.setStringList(_likedContentKey, likedContent);
        return true; // Successfully unliked
      }
      return false; // Wasn't liked
    } catch (e) {
      print('Error unliking content: $e');
      return false;
    }
  }

  /// Toggle like status for a content feed
  Future<bool> toggleLike(String contentId) async {
    final isLiked = await isContentLiked(contentId);
    if (isLiked) {
      await unlikeContent(contentId);
      return false; // Now unliked
    } else {
      await likeContent(contentId);
      return true; // Now liked
    }
  }

  /// Clear all liked content (for testing or reset)
  Future<void> clearAllLikedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_likedContentKey);
    } catch (e) {
      print('Error clearing liked content: $e');
    }
  }
}
