import 'package:flutter/foundation.dart';

/// Service for handling Firebase Storage images with optimized caching
class FirebaseImageService {
  
  /// Check if the URL is from Firebase Storage
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
           url.contains('storage.googleapis.com') ||
           url.contains('storage.cloud.google.com');
  }

  /// Get appropriate headers for Firebase Storage requests
  static Map<String, String>? getFirebaseStorageHeaders(String imageUrl) {
    if (isFirebaseStorageUrl(imageUrl)) {
      return {
        'Accept': 'image/*',
        'Cache-Control': 'max-age=3600', // 1 hour cache
        'User-Agent': 'SportEve/1.0',
      };
    }
    return null;
  }

  /// Generate optimized cache key for Firebase Storage images
  static String generateCacheKey(String imageUrl, String articleId, {String prefix = ''}) {
    // For Firebase Storage URLs, use a clean cache key
    if (isFirebaseStorageUrl(imageUrl)) {
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.join('/');
      final baseKey = prefix.isNotEmpty ? '${prefix}_' : '';
      return 'firebase_${baseKey}${path}_$articleId';
    }
    final baseKey = prefix.isNotEmpty ? '${prefix}_' : '';
    return '$baseKey${articleId}_$imageUrl';
  }

  /// Get optimized memory cache dimensions based on image type
  static Map<String, int> getMemoryCacheDimensions({bool isDetail = false, bool isFeatured = false}) {
    if (isDetail) {
      return {'width': 1200, 'height': 800};
    } else if (isFeatured) {
      return {'width': 600, 'height': 320};
    } else {
      return {'width': 800, 'height': 480};
    }
  }

  /// Log Firebase Storage image errors for debugging
  static void logImageError(String url, dynamic error) {
    if (kDebugMode) {
      debugPrint('Firebase Image Service - Failed to load image from URL: $url');
      debugPrint('Firebase Image Service - Error: $error');
      
      // Additional Firebase Storage specific error handling
      if (isFirebaseStorageUrl(url)) {
        debugPrint('Firebase Image Service - This is a Firebase Storage URL');
        
        // Check for common Firebase Storage issues
        if (error.toString().contains('403')) {
          debugPrint('Firebase Image Service - 403 Error: Check Firebase Storage rules');
        } else if (error.toString().contains('404')) {
          debugPrint('Firebase Image Service - 404 Error: Image not found in Firebase Storage');
        } else if (error.toString().contains('NetworkImage')) {
          debugPrint('Firebase Image Service - Network Error: Check internet connection');
        }
      }
    }
  }

  /// Get download URL for Firebase Storage with optional token refresh
  static Future<String?> getOptimizedDownloadUrl(String firebaseStorageUrl) async {
    // For future enhancement: Add token refresh logic if needed
    // Currently just returns the original URL
    return firebaseStorageUrl;
  }

  /// Validate Firebase Storage URL format
  static bool isValidFirebaseStorageUrl(String url) {
    if (!isFirebaseStorageUrl(url)) return false;
    
    try {
      final uri = Uri.parse(url);
      // Check if it has required query parameters for Firebase Storage
      return uri.queryParameters.containsKey('alt') || 
             url.contains('/o/') || // Firebase Storage object path
             url.contains('token='); // Firebase Storage token
    } catch (e) {
      return false;
    }
  }
}
