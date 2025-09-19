import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_feed.dart';

enum GenerationRequestType {
  bulkTrivia,
  singleParentTip,
  sportFacts,
  mixedContent;

  String get displayName {
    switch (this) {
      case GenerationRequestType.bulkTrivia:
        return 'Bulk Trivia';
      case GenerationRequestType.singleParentTip:
        return 'Parent Tip';
      case GenerationRequestType.sportFacts:
        return 'Sport Facts';
      case GenerationRequestType.mixedContent:
        return 'Mixed Content';
    }
  }

  static GenerationRequestType fromString(String value) {
    switch (value) {
      case 'bulk_trivia':
        return GenerationRequestType.bulkTrivia;
      case 'single_parent_tip':
        return GenerationRequestType.singleParentTip;
      case 'sport_facts':
        return GenerationRequestType.sportFacts;
      case 'mixed_content':
        return GenerationRequestType.mixedContent;
      default:
        return GenerationRequestType.bulkTrivia;
    }
  }

  String toFirestore() {
    switch (this) {
      case GenerationRequestType.bulkTrivia:
        return 'bulk_trivia';
      case GenerationRequestType.singleParentTip:
        return 'single_parent_tip';
      case GenerationRequestType.sportFacts:
        return 'sport_facts';
      case GenerationRequestType.mixedContent:
        return 'mixed_content';
    }
  }
}

enum GenerationStatus {
  pending,
  processing,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case GenerationStatus.pending:
        return 'Pending';
      case GenerationStatus.processing:
        return 'Processing';
      case GenerationStatus.completed:
        return 'Completed';
      case GenerationStatus.failed:
        return 'Failed';
    }
  }

  static GenerationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return GenerationStatus.pending;
      case 'processing':
        return GenerationStatus.processing;
      case 'completed':
        return GenerationStatus.completed;
      case 'failed':
        return GenerationStatus.failed;
      default:
        return GenerationStatus.pending;
    }
  }

  String toFirestore() {
    return toString().split('.').last;
  }
}

class ContentGenerationRequest {
  final String id;
  final GenerationRequestType requestType;
  final String sportCategory;
  final int quantity;
  final GenerationStatus status;
  final String requestedBy;
  final List<String> generatedContentIds;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  
  // Generation parameters
  final DifficultyLevel? difficultyLevel;
  final String? ageGroup;
  final String? sourceType; // 'sports_wiki', 'online_research', 'mixed'
  final Map<String, dynamic>? additionalParams;

  ContentGenerationRequest({
    required this.id,
    required this.requestType,
    required this.sportCategory,
    required this.quantity,
    required this.status,
    required this.requestedBy,
    required this.generatedContentIds,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.difficultyLevel,
    this.ageGroup,
    this.sourceType,
    this.additionalParams,
  });

  // Factory constructor from Firestore document
  factory ContentGenerationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ContentGenerationRequest(
      id: doc.id,
      requestType: GenerationRequestType.fromString(data['request_type'] ?? 'bulk_trivia'),
      sportCategory: data['sport_category'] ?? '',
      quantity: data['quantity'] ?? 1,
      status: GenerationStatus.fromString(data['status'] ?? 'pending'),
      requestedBy: data['requested_by'] ?? '',
      generatedContentIds: List<String>.from(data['generated_content_ids'] ?? []),
      createdAt: _parseTimestamp(data['created_at']) ?? DateTime.now(),
      completedAt: _parseTimestamp(data['completed_at']),
      errorMessage: data['error_message'],
      difficultyLevel: data['difficulty_level'] != null 
          ? DifficultyLevel.fromString(data['difficulty_level']) 
          : null,
      ageGroup: data['age_group'],
      sourceType: data['source_type'],
      additionalParams: data['additional_params'] != null 
          ? Map<String, dynamic>.from(data['additional_params']) 
          : null,
    );
  }

  // Helper method to parse different timestamp formats
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $timestamp');
        return null;
      }
    } else {
      print('Unknown timestamp type: ${timestamp.runtimeType}');
      return null;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'request_type': requestType.toFirestore(),
      'sport_category': sportCategory,
      'quantity': quantity,
      'status': status.toFirestore(),
      'requested_by': requestedBy,
      'generated_content_ids': generatedContentIds,
      'created_at': FieldValue.serverTimestamp(),
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'error_message': errorMessage,
      'difficulty_level': difficultyLevel?.toFirestore(),
      'age_group': ageGroup,
      'source_type': sourceType,
      'additional_params': additionalParams,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_type': requestType.toFirestore(),
      'sport_category': sportCategory,
      'quantity': quantity,
      'status': status.toFirestore(),
      'requested_by': requestedBy,
      'generated_content_ids': generatedContentIds,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'difficulty_level': difficultyLevel?.toFirestore(),
      'age_group': ageGroup,
      'source_type': sourceType,
      'additional_params': additionalParams,
    };
  }

  // Get progress percentage
  double get progressPercentage {
    switch (status) {
      case GenerationStatus.pending:
        return 0.0;
      case GenerationStatus.processing:
        return 0.5;
      case GenerationStatus.completed:
        return 1.0;
      case GenerationStatus.failed:
        return 0.0;
    }
  }

  // Get progress text
  String get progressText {
    switch (status) {
      case GenerationStatus.pending:
        return 'Waiting to start...';
      case GenerationStatus.processing:
        return 'Generating content...';
      case GenerationStatus.completed:
        return 'Generated ${generatedContentIds.length} of $quantity items';
      case GenerationStatus.failed:
        return 'Failed: ${errorMessage ?? 'Unknown error'}';
    }
  }

  // Check if request is still active
  bool get isActive {
    return status == GenerationStatus.pending || status == GenerationStatus.processing;
  }

  // Get duration since created
  Duration get duration {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(createdAt);
  }

  ContentGenerationRequest copyWith({
    String? id,
    GenerationRequestType? requestType,
    String? sportCategory,
    int? quantity,
    GenerationStatus? status,
    String? requestedBy,
    List<String>? generatedContentIds,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    DifficultyLevel? difficultyLevel,
    String? ageGroup,
    String? sourceType,
    Map<String, dynamic>? additionalParams,
  }) {
    return ContentGenerationRequest(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      sportCategory: sportCategory ?? this.sportCategory,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      generatedContentIds: generatedContentIds ?? this.generatedContentIds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      ageGroup: ageGroup ?? this.ageGroup,
      sourceType: sourceType ?? this.sourceType,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }

  @override
  String toString() {
    return 'ContentGenerationRequest{id: $id, type: $requestType, sport: $sportCategory, quantity: $quantity, status: $status}';
  }
}
