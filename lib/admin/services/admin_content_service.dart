import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/content_feed.dart';
import '../../models/content_generation_request.dart';
import '../../services/firebase_service.dart';

class AdminContentService {
  static AdminContentService? _instance;
  static AdminContentService get instance => _instance ??= AdminContentService._internal();
  
  AdminContentService._internal();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Collection references
  CollectionReference get _contentFeedsCollection => _firestore.collection('content_feeds');
  CollectionReference get _generationRequestsCollection => _firestore.collection('content_generation_requests');

  // ==================== CONTENT GENERATION ====================

  /// Request AI to generate content
  Future<ContentGenerationRequest> requestContentGeneration({
    required GenerationRequestType requestType,
    required String sportCategory,
    required int quantity,
    required String requestedBy,
    required String adminEmail,
    DifficultyLevel? difficultyLevel,
    String? ageGroup,
    String? sourceType,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      // Create generation request document
      final request = ContentGenerationRequest(
        id: '',
        requestType: requestType,
        sportCategory: sportCategory,
        quantity: quantity,
        status: GenerationStatus.pending,
        requestedBy: requestedBy,
        generatedContentIds: [],
        createdAt: DateTime.now(),
        difficultyLevel: difficultyLevel,
        ageGroup: ageGroup,
        sourceType: sourceType,
        additionalParams: additionalParams,
      );

      final docRef = await _generationRequestsCollection.add(request.toFirestore());
      
      // Call Cloud Function to process generation
      await _functions.httpsCallable('generateUserContent').call({
        'requestId': docRef.id,
        'contentType': requestType.toFirestore(),
        'sportCategory': sportCategory,
        'quantity': quantity,
        'difficulty': difficultyLevel?.toFirestore(),
        'ageGroup': ageGroup,
        'sourceType': sourceType ?? 'mixed',
        'additionalParams': additionalParams,
        'adminEmail': adminEmail,
      });

      print('✅ Content generation request created: ${docRef.id}');
      return request.copyWith(id: docRef.id);
    } catch (e) {
      print('❌ Error requesting content generation: $e');
      throw Exception('Failed to request content generation: $e');
    }
  }

  /// Get all generation requests
  Future<List<ContentGenerationRequest>> getAllGenerationRequests() async {
    try {
      final querySnapshot = await _generationRequestsCollection
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentGenerationRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching generation requests: $e');
      return [];
    }
  }

  /// Get generation request by ID
  Future<ContentGenerationRequest?> getGenerationRequestById(String id) async {
    try {
      final doc = await _generationRequestsCollection.doc(id).get();
      if (doc.exists) {
        return ContentGenerationRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching generation request $id: $e');
      return null;
    }
  }

  /// Get active generation requests
  Future<List<ContentGenerationRequest>> getActiveGenerationRequests() async {
    try {
      // Query for processing requests (most important)
      final processingSnapshot = await _generationRequestsCollection
          .where('status', isEqualTo: 'processing')
          .orderBy('created_at', descending: true)
          .get();

      // Query for pending requests
      final pendingSnapshot = await _generationRequestsCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      // Combine results
      final List<ContentGenerationRequest> requests = [];
      
      requests.addAll(processingSnapshot.docs
          .map((doc) => ContentGenerationRequest.fromFirestore(doc)));
      requests.addAll(pendingSnapshot.docs
          .map((doc) => ContentGenerationRequest.fromFirestore(doc)));

      // Sort combined results by created_at descending
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return requests;
    } catch (e) {
      print('Error fetching active generation requests: $e');
      return [];
    }
  }

  // ==================== CONTENT FEEDS MANAGEMENT ====================

  /// Get all content feeds
  Future<List<ContentFeed>> getAllContentFeeds() async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching content feeds: $e');
      return [];
    }
  }

  /// Get content feeds by status
  Future<List<ContentFeed>> getContentFeedsByStatus(ContentStatus status) async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('status', isEqualTo: status.toFirestore())
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching content feeds by status: $e');
      return [];
    }
  }

  /// Get pending content for review
  Future<List<ContentFeed>> getPendingContentForReview() async {
    return getContentFeedsByStatus(ContentStatus.generated);
  }

  /// Get content feeds by type
  Future<List<ContentFeed>> getContentFeedsByType(ContentType type) async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('type', isEqualTo: type.toFirestore())
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching content feeds by type: $e');
      return [];
    }
  }

  /// Get content feeds by sport category
  Future<List<ContentFeed>> getContentFeedsBySport(String sportCategory) async {
    try {
      final querySnapshot = await _contentFeedsCollection
          .where('sport_category', isEqualTo: sportCategory)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentFeed.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching content feeds by sport: $e');
      return [];
    }
  }

  /// Search content feeds
  Future<List<ContentFeed>> searchContentFeeds(String query) async {
    if (query.isEmpty) return getAllContentFeeds();
    
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia
      final allFeeds = await getAllContentFeeds();
      
      return allFeeds.where((feed) {
        final searchTerm = query.toLowerCase();
        return feed.displayTitle.toLowerCase().contains(searchTerm) ||
               feed.contentPreview.toLowerCase().contains(searchTerm) ||
               feed.sportCategory.toLowerCase().contains(searchTerm);
      }).toList();
    } catch (e) {
      print('Error searching content feeds: $e');
      return [];
    }
  }

  /// Get single content feed by ID
  Future<ContentFeed?> getContentFeedById(String id) async {
    try {
      final doc = await _contentFeedsCollection.doc(id).get();
      if (doc.exists) {
        return ContentFeed.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching content feed $id: $e');
      return null;
    }
  }

  /// Update content feed
  Future<void> updateContentFeed(String id, ContentFeed contentFeed) async {
    try {
      final updateData = contentFeed.toFirestore();
      updateData['updated_at'] = FieldValue.serverTimestamp();
      
      await _contentFeedsCollection.doc(id).update(updateData);
      print('✅ Updated content feed: $id');
    } catch (e) {
      print('❌ Error updating content feed: $e');
      throw Exception('Failed to update content feed: $e');
    }
  }

  /// Approve content feed
  Future<void> approveContentFeed(String id, String approvedBy) async {
    try {
      await _contentFeedsCollection.doc(id).update({
        'status': ContentStatus.approved.toFirestore(),
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': approvedBy,
      });
      
      print('✅ Approved content feed: $id');
    } catch (e) {
      print('❌ Error approving content feed: $e');
      throw Exception('Failed to approve content feed: $e');
    }
  }

  /// Reject content feed
  Future<void> rejectContentFeed(String id) async {
    try {
      await _contentFeedsCollection.doc(id).update({
        'status': ContentStatus.rejected.toFirestore(),
      });
      
      print('✅ Rejected content feed: $id');
    } catch (e) {
      print('❌ Error rejecting content feed: $e');
      throw Exception('Failed to reject content feed: $e');
    }
  }

  /// Publish content feed
  Future<void> publishContentFeed(String id) async {
    try {
      await _contentFeedsCollection.doc(id).update({
        'status': ContentStatus.published.toFirestore(),
        'published_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Published content feed: $id');
    } catch (e) {
      print('❌ Error publishing content feed: $e');
      throw Exception('Failed to publish content feed: $e');
    }
  }

  /// Bulk approve content feeds
  Future<void> bulkApproveContentFeeds(List<String> ids, String approvedBy) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in ids) {
        final docRef = _contentFeedsCollection.doc(id);
        batch.update(docRef, {
          'status': ContentStatus.approved.toFirestore(),
          'approved_at': FieldValue.serverTimestamp(),
          'approved_by': approvedBy,
        });
      }
      
      await batch.commit();
      print('✅ Bulk approved ${ids.length} content feeds');
    } catch (e) {
      print('❌ Error bulk approving content feeds: $e');
      throw Exception('Failed to bulk approve content feeds: $e');
    }
  }

  /// Bulk publish content feeds
  Future<void> bulkPublishContentFeeds(List<String> ids) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in ids) {
        final docRef = _contentFeedsCollection.doc(id);
        batch.update(docRef, {
          'status': ContentStatus.published.toFirestore(),
          'published_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Bulk published ${ids.length} content feeds');
    } catch (e) {
      print('❌ Error bulk publishing content feeds: $e');
      throw Exception('Failed to bulk publish content feeds: $e');
    }
  }

  /// Delete content feed
  Future<void> deleteContentFeed(String id) async {
    try {
      await _contentFeedsCollection.doc(id).delete();
      print('✅ Deleted content feed: $id');
    } catch (e) {
      print('❌ Error deleting content feed: $e');
      throw Exception('Failed to delete content feed: $e');
    }
  }

  /// Bulk delete content feeds
  Future<void> bulkDeleteContentFeeds(List<String> ids) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in ids) {
        final docRef = _contentFeedsCollection.doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      print('✅ Bulk deleted ${ids.length} content feeds');
    } catch (e) {
      print('❌ Error bulk deleting content feeds: $e');
      throw Exception('Failed to bulk delete content feeds: $e');
    }
  }

  // ==================== ANALYTICS ====================

  /// Get content statistics
  Future<Map<String, int>> getContentStatistics() async {
    try {
      final allContent = await getAllContentFeeds();
      
      final stats = <String, int>{
        'total': allContent.length,
        'generated': 0,
        'approved': 0,
        'published': 0,
        'rejected': 0,
        'trivia': 0,
        'parent_tips': 0,
        'did_you_know': 0,
      };

      for (final content in allContent) {
        // Count by status
        switch (content.status) {
          case ContentStatus.generated:
            stats['generated'] = (stats['generated'] ?? 0) + 1;
            break;
          case ContentStatus.approved:
            stats['approved'] = (stats['approved'] ?? 0) + 1;
            break;
          case ContentStatus.published:
            stats['published'] = (stats['published'] ?? 0) + 1;
            break;
          case ContentStatus.rejected:
            stats['rejected'] = (stats['rejected'] ?? 0) + 1;
            break;
        }

        // Count by type
        switch (content.type) {
          case ContentType.trivia:
            stats['trivia'] = (stats['trivia'] ?? 0) + 1;
            break;
          case ContentType.parentTip:
            stats['parent_tips'] = (stats['parent_tips'] ?? 0) + 1;
            break;
          case ContentType.didYouKnow:
            stats['did_you_know'] = (stats['did_you_know'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting content statistics: $e');
      return {};
    }
  }

  /// Get sport-wise content distribution
  Future<Map<String, int>> getSportWiseDistribution() async {
    try {
      final allContent = await getAllContentFeeds();
      final distribution = <String, int>{};

      for (final content in allContent) {
        final sport = content.sportCategory;
        distribution[sport] = (distribution[sport] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error getting sport-wise distribution: $e');
      return {};
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get available sports for content generation (from sports wiki)
  Future<List<String>> getAvailableSportsForGeneration() async {
    try {
      final sportsWikiSnapshot = await _firestore
          .collection('sports_wiki')
          .get();

      return sportsWikiSnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching available sports: $e');
      return [
        'cricket', 'football', 'basketball', 'tennis', 'badminton', 
        'swimming', 'athletics', 'hockey', 'volleyball', 'kabaddi'
      ];
    }
  }

  /// Test Cloud Function connection
  Future<bool> testCloudFunctionConnection() async {
    try {
      final result = await _functions.httpsCallable('generateUserContent').call({
        'test': true,
      });
      
      print('✅ Cloud Function connection test successful: ${result.data}');
      return true;
    } catch (e) {
      print('❌ Cloud Function connection test failed: $e');
      return false;
    }
  }
}
