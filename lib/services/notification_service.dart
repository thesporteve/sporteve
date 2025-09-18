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
      
      print('Subscribed to default topics');
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
    
    // Extract navigation data
    final data = message.data;
    if (data.containsKey('screen')) {
      // TODO: Navigate to specific screen
      print('Navigate to: ${data['screen']}');
      
      // Store navigation data for later use
      _storeNavigationData(data);
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
      await prefs.setString('pending_navigation', data.toString());
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
        // TODO: Parse and return the data
        return {};
      }
    } catch (e) {
      print('Failed to get pending navigation data: $e');
    }
    return null;
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
