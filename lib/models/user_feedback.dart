import 'package:cloud_firestore/cloud_firestore.dart';

class UserFeedback {
  final String id;
  final String userId;
  final String userEmail;
  final int overallRating;
  final String? favoriteFeature;
  final String? mostUsedSports;
  final String? discoverySource;
  final int appPerformanceRating;
  final int contentQualityRating;
  final List<String> desiredFeatures;
  final String? improvementSuggestions;
  final String? additionalComments;
  final String appVersion;
  final String deviceInfo;
  final DateTime submittedAt;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.overallRating,
    this.favoriteFeature,
    this.mostUsedSports,
    this.discoverySource,
    required this.appPerformanceRating,
    required this.contentQualityRating,
    required this.desiredFeatures,
    this.improvementSuggestions,
    this.additionalComments,
    required this.appVersion,
    required this.deviceInfo,
    required this.submittedAt,
  });

  factory UserFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFeedback(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      overallRating: data['overallRating'] ?? 0,
      favoriteFeature: data['favoriteFeature'],
      mostUsedSports: data['mostUsedSports'],
      discoverySource: data['discoverySource'],
      appPerformanceRating: data['appPerformanceRating'] ?? 0,
      contentQualityRating: data['contentQualityRating'] ?? 0,
      desiredFeatures: List<String>.from(data['desiredFeatures'] ?? []),
      improvementSuggestions: data['improvementSuggestions'],
      additionalComments: data['additionalComments'],
      appVersion: data['appVersion'] ?? '',
      deviceInfo: data['deviceInfo'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'overallRating': overallRating,
      'favoriteFeature': favoriteFeature,
      'mostUsedSports': mostUsedSports,
      'discoverySource': discoverySource,
      'appPerformanceRating': appPerformanceRating,
      'contentQualityRating': contentQualityRating,
      'desiredFeatures': desiredFeatures,
      'improvementSuggestions': improvementSuggestions,
      'additionalComments': additionalComments,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
