import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_feed.dart';

class ContentFeedService {
  static ContentFeedService? _instance;
  static ContentFeedService get instance => _instance ??= ContentFeedService._internal();
  
  ContentFeedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _contentFeedsCollection = 
      FirebaseFirestore.instance.collection('content_feeds');

  /// Get published content feeds (for mobile app)
  Future<List<ContentFeed>> getPublishedContentFeeds() async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('status', isEqualTo: 'published')
          .get();

      // Sort in memory instead of using orderBy to avoid composite index
      final docs = querySnapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (bData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime); // Descending order
      });

      return docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching published content feeds: $e');
      return [];
    }
  }

  /// Get published content feeds by type
  Future<List<ContentFeed>> getPublishedContentByType(ContentType type) async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('status', isEqualTo: 'published')
          .where('type', isEqualTo: type.toFirestore())
          .get();

      // Sort in memory instead of using orderBy to avoid composite index
      final docs = querySnapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (bData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime); // Descending order
      });

      return docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching published content by type: $e');
      return [];
    }
  }

  /// Get published content feeds by sport category
  Future<List<ContentFeed>> getPublishedContentBySport(String sportCategory) async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('status', isEqualTo: 'published')
          .where('sport_category', isEqualTo: sportCategory)
          .get();

      // Sort in memory instead of using orderBy to avoid composite index
      final docs = querySnapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (bData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime); // Descending order
      });

      return docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching published content by sport: $e');
      return [];
    }
  }

  /// Get latest published content (for daily tip banner)
  Future<ContentFeed?> getLatestPublishedContent() async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('status', isEqualTo: 'published')
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      // Sort in memory to find the latest
      final docs = querySnapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = (aData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (bData['published_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime); // Descending order
      });

      return ContentFeed.fromFirestore(docs.first);
    } catch (e) {
      print('Error fetching latest published content: $e');
      return null;
    }
  }

  /// Mark content as read (Phase 2)
  Future<void> markContentAsRead(String contentId) async {
    try {
      await _contentFeedsCollection.doc(contentId).update({
        'view_count': FieldValue.increment(1),
        'last_viewed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking content as read: $e');
    }
  }

  /// Like content (Phase 2)
  Future<void> likeContent(String contentId) async {
    try {
      await _contentFeedsCollection.doc(contentId).update({
        'like_count': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error liking content: $e');
    }
  }

  /// Unlike content (Phase 2)
  Future<void> unlikeContent(String contentId) async {
    try {
      await _contentFeedsCollection.doc(contentId).update({
        'like_count': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error unliking content: $e');
    }
  }

  /// Search published content (Phase 2)
  Future<List<ContentFeed>> searchPublishedContent(String query) async {
    if (query.isEmpty) return getPublishedContentFeeds();
    
    try {
      // Get all published content and filter client-side
      // Firestore doesn't support full-text search natively
      final allContent = await getPublishedContentFeeds();
      
      return allContent.where((content) {
        final searchTerm = query.toLowerCase();
        
        // Search in different content fields based on type
        switch (content.type) {
          case ContentType.parentTip:
            final parentTip = content.parentTipContent;
            return parentTip != null && (
              parentTip.title.toLowerCase().contains(searchTerm) ||
              parentTip.content.toLowerCase().contains(searchTerm)
            );
          case ContentType.didYouKnow:
            final didYouKnow = content.didYouKnowContent;
            return didYouKnow != null && (
              didYouKnow.fact.toLowerCase().contains(searchTerm) ||
              didYouKnow.details.toLowerCase().contains(searchTerm)
            );
          case ContentType.trivia:
            final trivia = content.triviaContent;
            return trivia != null && (
              trivia.question.toLowerCase().contains(searchTerm) ||
              trivia.explanation.toLowerCase().contains(searchTerm)
            );
        }
      }).toList();
    } catch (e) {
      print('Error searching content: $e');
      return [];
    }
  }
}
