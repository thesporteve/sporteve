import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

/// Notification service for handling push notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Callback to refresh data when notification is tapped
  Function()? _onNotificationTap;

  /// Set callback to be called when notification is tapped
  void setNotificationTapCallback(Function() callback) {
    _onNotificationTap = callback;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();
      
      // Setup message handlers
      await _setupMessageHandlers();
      
      // Get and log FCM token for testing
      await getFCMToken();
      
      // Subscribe to default topics
      await _subscribeToDefaultTopics();
      
      print('Notification service initialized successfully');
    } catch (e) {
      print('Failed to initialize notification service: $e');
    }
  }

  /// Public method to get FCM token (for testing purposes)
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseService.messaging.getToken();
      print('🔥 FCM Token: $token');
      print('📱 Use this token to send test notifications from Firebase Console');
      return token;
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseService.messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseService.messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Subscribe to default topics
  Future<void> _subscribeToDefaultTopics() async {
    try {
      // Subscribe to general sports news
      await _firebaseService.messaging.subscribeToTopic('sports_news');
      
      // Subscribe to breaking news
      await _firebaseService.messaging.subscribeToTopic('breaking_news');
      
      // Subscribe to AI content notifications
      await _firebaseService.messaging.subscribeToTopic('sports_content');
      await _firebaseService.messaging.subscribeToTopic('content_parent_tip');
      await _firebaseService.messaging.subscribeToTopic('content_did_you_know');
      await _firebaseService.messaging.subscribeToTopic('content_trivia');
      
      print('Subscribed to default topics (news + content feeds)');
    } catch (e) {
      print('Failed to subscribe to default topics: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    
    // TODO: Show in-app notification banner
    _showInAppNotification(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
    
    // Call the refresh callback to update news/content feeds
    _onNotificationTap?.call();
    
    // Extract navigation data
    final data = message.data;
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      print('Navigate to: $screen');
      
      // Handle different types of notifications
      if (screen == 'content_detail' && data.containsKey('content_id')) {
        // Content feed notification - navigate directly to content detail
        final contentId = data['content_id'];
        print('Content notification - navigating to detail: $contentId');
        
        // Store content navigation data for direct navigation
        final contentData = {
          'screen': 'content_detail',
          'content_id': contentId,
          'content_type': data['content_type'] ?? '',
          'sport_category': data['sport_category'] ?? '',
          'route': '/content/$contentId',  // Direct route for immediate navigation
        };
        _storeNavigationData(contentData);
      } else if (screen == 'tips_facts' && data.containsKey('content_id')) {
        // Fallback: Content feed notification - navigate to Tips & Facts with highlight (for backward compatibility)
        final contentId = data['content_id'];
        print('Content notification - highlighting content: $contentId');
        
        // Store content navigation data
        final contentData = {
          'screen': 'tips_facts',
          'content_id': contentId,
          'content_type': data['content_type'] ?? '',
          'sport_category': data['sport_category'] ?? '',
        };
        _storeNavigationData(contentData);
      } else if (screen == 'news_detail' && data.containsKey('article_id')) {
        // News article notification - navigate to news detail
        final articleId = data['article_id'];
        print('News notification - opening article: $articleId');
        
        // Store news navigation data
        final newsData = {
          'screen': 'news_detail',
          'article_id': articleId,
          'category': data['category'],
        };
        _storeNavigationData(newsData);
      } else {
        // Generic navigation
        _storeNavigationData(data);
      }
    }
  }

  /// Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    // TODO: Implement in-app notification banner
    // This could use a package like fluttertoast or a custom overlay
    print('Show in-app notification: ${message.notification?.title}');
  }

  /// Store navigation data for later use
  Future<void> _storeNavigationData(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Store as JSON string for proper parsing
      await prefs.setString('pending_navigation', _encodeNavigationData(data));
      print('📱 Stored navigation data: $data');
    } catch (e) {
      print('Failed to store navigation data: $e');
    }
  }

  /// Get pending navigation data
  Future<Map<String, dynamic>?> getPendingNavigationData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? dataString = prefs.getString('pending_navigation');
      if (dataString != null) {
        // Clear the stored data
        await prefs.remove('pending_navigation');
        // Parse and return the navigation data
        final parsedData = _decodeNavigationData(dataString);
        print('📱 Retrieved navigation data: $parsedData');
        return parsedData;
      }
    } catch (e) {
      print('Failed to get pending navigation data: $e');
    }
    return null;
  }

  /// Encode navigation data as a simple string format
  String _encodeNavigationData(Map<String, dynamic> data) {
    final parts = <String>[];
    data.forEach((key, value) {
      parts.add('$key:$value');
    });
    return parts.join('|');
  }

  /// Decode navigation data from string format
  Map<String, dynamic> _decodeNavigationData(String dataString) {
    final data = <String, dynamic>{};
    final parts = dataString.split('|');
    for (final part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        data[keyValue[0]] = keyValue[1];
      }
    }
    return data;
  }

  /// Subscribe to specific sport category
  Future<void> subscribeToSportCategory(String category) async {
    try {
      String topic = 'sport_${category.toLowerCase()}';
      await _firebaseService.messaging.subscribeToTopic(topic);
      print('Subscribed to sport category: $category');
    } catch (e) {
      print('Failed to subscribe to sport category $category: $e');
    }
  }

  /// Unsubscribe from specific sport category
  Future<void> unsubscribeFromSportCategory(String category) async {
    try {
      String topic = 'sport_${category.toLowerCase()}';
      await _firebaseService.messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from sport category: $category');
    } catch (e) {
      print('Failed to unsubscribe from sport category $category: $e');
    }
  }

  /// Subscribe to team notifications
  Future<void> subscribeToTeam(String teamName) async {
    try {
      String topic = 'team_${teamName.toLowerCase().replaceAll(' ', '_')}';
      await _firebaseService.messaging.subscribeToTopic(topic);
      print('Subscribed to team: $teamName');
    } catch (e) {
      print('Failed to subscribe to team $teamName: $e');
    }
  }

  /// Unsubscribe from team notifications
  Future<void> unsubscribeFromTeam(String teamName) async {
    try {
      String topic = 'team_${teamName.toLowerCase().replaceAll(' ', '_')}';
      await _firebaseService.messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from team: $teamName');
    } catch (e) {
      print('Failed to unsubscribe from team $teamName: $e');
    }
  }


  /// Update user notification preferences
  Future<void> updateNotificationPreferences({
    bool? sportsNews,
    bool? breakingNews,
    bool? matchUpdates,
    bool? teamUpdates,
    List<String>? favoriteSports,
    List<String>? favoriteTeams,
  }) async {
    try {
      Map<String, dynamic> preferences = {
        'sportsNews': sportsNews ?? true,
        'breakingNews': breakingNews ?? true,
        'matchUpdates': matchUpdates ?? false,
        'teamUpdates': teamUpdates ?? false,
        'favoriteSports': favoriteSports ?? [],
        'favoriteTeams': favoriteTeams ?? [],
      };

      // Store in Firebase
      await _firebaseService.firestore
          .collection('userNotificationPreferences')
          .doc(_firebaseService.auth.currentUser?.uid)
          .set(preferences, SetOptions(merge: true));

      // Update topic subscriptions based on preferences
      await _updateTopicSubscriptions(preferences);
      
      print('Notification preferences updated');
    } catch (e) {
      print('Failed to update notification preferences: $e');
    }
  }

  /// Update topic subscriptions based on preferences
  Future<void> _updateTopicSubscriptions(Map<String, dynamic> preferences) async {
    try {
      // Subscribe/unsubscribe to sports news
      if (preferences['sportsNews'] == true) {
        await _firebaseService.messaging.subscribeToTopic('sports_news');
      } else {
        await _firebaseService.messaging.unsubscribeFromTopic('sports_news');
      }

      // Subscribe/unsubscribe to breaking news
      if (preferences['breakingNews'] == true) {
        await _firebaseService.messaging.subscribeToTopic('breaking_news');
      } else {
        await _firebaseService.messaging.unsubscribeFromTopic('breaking_news');
      }

      // Subscribe to favorite sports
      List<String> favoriteSports = List<String>.from(preferences['favoriteSports'] ?? []);
      for (String sport in favoriteSports) {
        await subscribeToSportCategory(sport);
      }

      // Subscribe to favorite teams
      List<String> favoriteTeams = List<String>.from(preferences['favoriteTeams'] ?? []);
      for (String team in favoriteTeams) {
        await subscribeToTeam(team);
      }
    } catch (e) {
      print('Failed to update topic subscriptions: $e');
    }
  }
}
