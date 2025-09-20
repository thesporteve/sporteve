import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_feedback.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _feedbackCollection => _firestore.collection('user_feedback');

  /// Submit user feedback
  Future<bool> submitFeedback({
    required int overallRating,
    String? favoriteFeature,
    String? mostUsedSports,
    String? discoverySource,
    required int appPerformanceRating,
    required int contentQualityRating,
    required List<String> desiredFeatures,
    String? improvementSuggestions,
    String? additionalComments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get device and app info
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      final feedback = UserFeedback(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userEmail: user.email ?? '',
        overallRating: overallRating,
        favoriteFeature: favoriteFeature,
        mostUsedSports: mostUsedSports,
        discoverySource: discoverySource,
        appPerformanceRating: appPerformanceRating,
        contentQualityRating: contentQualityRating,
        desiredFeatures: desiredFeatures,
        improvementSuggestions: improvementSuggestions,
        additionalComments: additionalComments,
        appVersion: packageInfo.version,
        deviceInfo: deviceInfo,
        submittedAt: DateTime.now(),
      );

      // Submit the feedback first - this is the critical operation
      await _feedbackCollection.add(feedback.toFirestore());
      print('Feedback submitted successfully');

      // Update user's last feedback date for popup management (non-critical)
      // Use set with merge to create document if it doesn't exist
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastFeedbackDate': Timestamp.fromDate(DateTime.now()),
          'feedbackCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
        print('User feedback tracking updated');
      } catch (userUpdateError) {
        print('Warning: Could not update user feedback tracking: $userUpdateError');
        // Don't fail the entire operation if user tracking fails
      }

      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  /// Check if user should be prompted for feedback
  Future<bool> shouldPromptForFeedback() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return true; // New user, can be prompted

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastFeedbackDate = userData['lastFeedbackDate'] as Timestamp?;
      final feedbackCount = userData['feedbackCount'] as int? ?? 0;

      // Don't prompt if user has already given feedback 3 or more times
      if (feedbackCount >= 3) return false;

      // If no previous feedback, prompt after 3 days of app usage
      if (lastFeedbackDate == null) {
        final accountCreated = user.metadata.creationTime;
        if (accountCreated != null) {
          final daysSinceJoined = DateTime.now().difference(accountCreated).inDays;
          return daysSinceJoined >= 3;
        }
      } else {
        // If previous feedback exists, prompt after 30 days
        final daysSinceLastFeedback = DateTime.now().difference(lastFeedbackDate.toDate()).inDays;
        return daysSinceLastFeedback >= 30;
      }

      return false;
    } catch (e) {
      print('Error checking feedback prompt eligibility: $e');
      return false;
    }
  }

  /// Get all feedback for admin dashboard
  Future<List<UserFeedback>> getAllFeedback() async {
    try {
      final querySnapshot = await _feedbackCollection
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserFeedback.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching feedback: $e');
      return [];
    }
  }

  /// Get feedback analytics
  Future<Map<String, dynamic>> getFeedbackAnalytics() async {
    try {
      final querySnapshot = await _feedbackCollection.get();
      final feedbacks = querySnapshot.docs
          .map((doc) => UserFeedback.fromFirestore(doc))
          .toList();

      if (feedbacks.isEmpty) {
        return {
          'totalCount': 0,
          'averageOverallRating': 0.0,
          'averagePerformanceRating': 0.0,
          'averageContentRating': 0.0,
          'topDesiredFeatures': <String>[],
          'discoverySourceCounts': <String, int>{},
          'ratingDistribution': <int, int>{},
        };
      }

      // Calculate averages
      final avgOverall = feedbacks.map((f) => f.overallRating).reduce((a, b) => a + b) / feedbacks.length;
      final avgPerformance = feedbacks.map((f) => f.appPerformanceRating).reduce((a, b) => a + b) / feedbacks.length;
      final avgContent = feedbacks.map((f) => f.contentQualityRating).reduce((a, b) => a + b) / feedbacks.length;

      // Top desired features
      final allDesiredFeatures = <String>[];
      for (final feedback in feedbacks) {
        allDesiredFeatures.addAll(feedback.desiredFeatures);
      }
      final featureCounts = <String, int>{};
      for (final feature in allDesiredFeatures) {
        featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
      }
      final topFeatures = featureCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Discovery source counts
      final discoveryCounts = <String, int>{};
      for (final feedback in feedbacks) {
        if (feedback.discoverySource != null) {
          final source = feedback.discoverySource!;
          discoveryCounts[source] = (discoveryCounts[source] ?? 0) + 1;
        }
      }

      // Rating distribution
      final ratingDist = <int, int>{};
      for (final feedback in feedbacks) {
        final rating = feedback.overallRating;
        ratingDist[rating] = (ratingDist[rating] ?? 0) + 1;
      }

      return {
        'totalCount': feedbacks.length,
        'averageOverallRating': double.parse(avgOverall.toStringAsFixed(1)),
        'averagePerformanceRating': double.parse(avgPerformance.toStringAsFixed(1)),
        'averageContentRating': double.parse(avgContent.toStringAsFixed(1)),
        'topDesiredFeatures': topFeatures.take(10).map((e) => e.key).toList(),
        'discoverySourceCounts': discoveryCounts,
        'ratingDistribution': ratingDist,
        'recentFeedbacks': feedbacks.take(5).toList(),
      };
    } catch (e) {
      print('Error calculating feedback analytics: $e');
      return {};
    }
  }

  /// Get device information
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      
      if (kIsWeb) {
        final webBrowserInfo = await deviceInfoPlugin.webBrowserInfo;
        return 'Web: ${webBrowserInfo.browserName} ${webBrowserInfo.platform}';
      }
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return 'Android: ${androidInfo.model} (API ${androidInfo.version.sdkInt})';
      }
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return 'iOS: ${iosInfo.model} ${iosInfo.systemVersion}';
      }
      
      return 'Unknown platform';
    } catch (e) {
      return 'Device info unavailable';
    }
  }

  /// Mark feedback prompt as dismissed (to avoid showing again soon)
  Future<void> markFeedbackPromptDismissed() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('users').doc(user.uid).set({
        'lastFeedbackPromptDismissed': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking feedback prompt as dismissed: $e');
    }
  }
}
