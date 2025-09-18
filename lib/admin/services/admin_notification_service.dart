import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin notification service for queuing push notifications (web-compatible)
/// Actual notification sending will be handled by Firebase Functions
class AdminNotificationService {
  static AdminNotificationService? _instance;
  static AdminNotificationService get instance => _instance ??= AdminNotificationService._();
  
  AdminNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification when new article is published
  /// This will send to multiple topics based on article content
  Future<bool> sendArticleNotification({
    required String title,
    required String summary,
    required String category,
    required String articleId,
    // Breaking news feature disabled per requirement
    // bool isBreaking = false,
  }) async {
    try {
      // Determine topics to send to
      List<String> topics = [];
      
      // Always send to general sports news
      topics.add('sports_news');
      
      // Send to specific sport category
      topics.add('sport_${category.toLowerCase()}');
      
      // Breaking news feature disabled per requirement
      // // Send to breaking news if marked as breaking
      // if (isBreaking) {
      //   topics.add('breaking_news');
      // }

      print('📱 Sending notifications to topics: $topics');

      bool allSuccessful = true;
      
      // Send notification to each topic
      for (String topic in topics) {
        final success = await _sendTopicNotification(
          topic: topic,
          title: _formatNotificationTitle(title, category),
          body: _formatNotificationBody(summary),
          articleId: articleId,
          category: category,
        );
        
        if (!success) {
          allSuccessful = false;
        }
      }

      return allSuccessful;
    } catch (e) {
      print('❌ Error sending article notification: $e');
      return false;
    }
  }

  /// Send notification to a specific topic using Firebase Cloud Functions
  Future<bool> _sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    required String articleId,
    required String category,
  }) async {
    try {
      // Use Firebase Cloud Functions to send the notification
      // This is safer than using the server key directly in the app
      final response = await _firestore
          .collection('notifications')
          .add({
        'topic': topic,
        'title': title,
        'body': body,
        'data': {
          'article_id': articleId,
          'category': category,
          'screen': 'home',
          'action': 'refresh_news',
          'timestamp': FieldValue.serverTimestamp(),
        },
        'created_at': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('✅ Queued notification for topic "$topic": ${response.id}');
      
      // In a real implementation, you'd have a Cloud Function 
      // watching this collection and sending the actual push notifications
      // For now, we'll simulate success
      return true;
    } catch (e) {
      print('❌ Failed to send notification to topic "$topic": $e');
      return false;
    }
  }

  /// Format notification title based on article type
  String _formatNotificationTitle(String title, String category) {
    // Breaking news feature disabled per requirement
    // if (isBreaking) {
    //   return '🚨 BREAKING: ${_truncateText(title, 50)}';
    // }
    
    final sportName = _getCategoryDisplayName(category);
    return '⚽ $sportName: ${_truncateText(title, 45)}';
  }

  /// Format notification body
  String _formatNotificationBody(String summary) {
    return _truncateText(summary, 100);
  }

  /// Get display name for sport category
  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return 'Football';
      case 'soccer':
        return 'Soccer';  
      case 'basketball':
        return 'Basketball';
      case 'cricket':
        return 'Cricket';
      case 'tennis':
        return 'Tennis';
      case 'baseball':
        return 'Baseball';
      case 'hockey':
        return 'Hockey';
      case 'volleyball':
        return 'Volleyball';
      case 'rugby':
        return 'Rugby';
      case 'golf':
        return 'Golf';
      case 'athletics':
        return 'Athletics';
      case 'swimming':
        return 'Swimming';
      case 'boxing':
        return 'Boxing';
      case 'wrestling':
        return 'Wrestling';
      case 'weightlifting':
        return 'Weightlifting';
      case 'gymnastics':
        return 'Gymnastics';
      default:
        return category.split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Truncate text to specified length
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Send a test notification (for debugging)
  Future<bool> sendTestNotification() async {
    try {
      return await _sendTopicNotification(
        topic: 'sports_news',
        title: '🧪 Test Notification from Admin',
        body: 'If you see this, notifications are working perfectly!',
        articleId: 'test_article',
        category: 'test',
      );
    } catch (e) {
      print('❌ Failed to send test notification: $e');
      return false;
    }
  }

  /// Get FCM token for testing (web compatible version)
  Future<String?> getFCMToken() async {
    try {
      // On web, we can't get FCM tokens directly
      // This would be handled by Firebase Functions
      return 'web-admin-token-placeholder';
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('created_at', isGreaterThan: 
              Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))))
          .get();

      Map<String, int> stats = {
        'total': snapshot.docs.length,
        'sent': 0,
        'pending': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['sent'] == true) {
          stats['sent'] = stats['sent']! + 1;
        } else {
          stats['pending'] = stats['pending']! + 1;
        }
      }

      return stats;
    } catch (e) {
      print('❌ Error getting notification stats: $e');
      return {'total': 0, 'sent': 0, 'pending': 0};
    }
  }
}
