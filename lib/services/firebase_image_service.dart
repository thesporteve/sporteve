import 'package:flutter/foundation.dart';

/// Service for handling Firebase Storage images with optimized caching
class FirebaseImageService {
  
  /// Check if the URL is from Firebase Storage
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
           url.contains('storage.googleapis.com') ||
           url.contains('storage.cloud.google.com');
  }

  /// Get optimized headers for Firebase Storage requests with better caching
  static Map<String, String>? getFirebaseStorageHeaders(String imageUrl) {
    if (isFirebaseStorageUrl(imageUrl)) {
      return {
        // Prefer WebP format for better compression (30% smaller files)
        'Accept': 'image/webp,image/avif,image/jpeg,image/png,image/*;q=0.8,*/*;q=0.5',
        // Extended cache for news images (7 days)
        'Cache-Control': 'public, max-age=604800, stale-while-revalidate=86400',
        'User-Agent': 'SportEve/1.0 (Mobile)',
        // Enable compression
        'Accept-Encoding': 'gzip, deflate, br',
        // Prefer faster connection reuse
        'Connection': 'keep-alive',
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

  /// Get download URL (Firebase Storage serves files as-is)
  static String getOptimizedDownloadUrl(String firebaseStorageUrl) {
    // Firebase Storage doesn't support query parameter transformations
    // Files are served exactly as uploaded
    return firebaseStorageUrl;
  }

  /// Get URL for card thumbnails (same as original until WebP conversion)
  static String getCardThumbnailUrl(String firebaseStorageUrl, {bool isFeatured = false}) {
    // Note: Firebase Storage serves original file
    // For true optimization, upload WebP versions or use Firebase Functions
    return firebaseStorageUrl;
  }

  /// Get URL for detail view (same as original until WebP conversion)
  static String getDetailViewUrl(String firebaseStorageUrl) {
    // Note: Firebase Storage serves original file
    // For true optimization, upload WebP versions or use Firebase Functions
    return firebaseStorageUrl;
  }

  /// Helper to check if we should recommend WebP conversion
  static bool shouldConvertToWebP(String firebaseStorageUrl) {
    return firebaseStorageUrl.toLowerCase().contains('.png') || 
           firebaseStorageUrl.toLowerCase().contains('.jpg') ||
           firebaseStorageUrl.toLowerCase().contains('.jpeg');
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
