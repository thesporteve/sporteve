import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  trivia,
  parentTip,
  didYouKnow;

  String get displayName {
    switch (this) {
      case ContentType.trivia:
        return 'Trivia';
      case ContentType.parentTip:
        return 'Health Tip';
      case ContentType.didYouKnow:
        return 'Did You Know';
    }
  }

  String get icon {
    switch (this) {
      case ContentType.trivia:
        return '🧠';
      case ContentType.parentTip:
        return '🏥';
      case ContentType.didYouKnow:
        return '💡';
    }
  }

  static ContentType fromString(String value) {
    switch (value) {
      case 'trivia':
        return ContentType.trivia;
      case 'parent_tip':
        return ContentType.parentTip;
      case 'did_you_know':
        return ContentType.didYouKnow;
      default:
        return ContentType.trivia;
    }
  }

  String toFirestore() {
    switch (this) {
      case ContentType.trivia:
        return 'trivia';
      case ContentType.parentTip:
        return 'parent_tip';
      case ContentType.didYouKnow:
        return 'did_you_know';
    }
  }
}

enum ContentStatus {
  generated,
  approved,
  published,
  rejected;

  String get displayName {
    switch (this) {
      case ContentStatus.generated:
        return 'Generated';
      case ContentStatus.approved:
        return 'Approved';
      case ContentStatus.published:
        return 'Published';
      case ContentStatus.rejected:
        return 'Rejected';
    }
  }

  static ContentStatus fromString(String value) {
    switch (value) {
      case 'generated':
        return ContentStatus.generated;
      case 'approved':
        return ContentStatus.approved;
      case 'published':
        return ContentStatus.published;
      case 'rejected':
        return ContentStatus.rejected;
      default:
        return ContentStatus.generated;
    }
  }

  String toFirestore() {
    return toString().split('.').last;
  }
}

enum DifficultyLevel {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  static DifficultyLevel fromString(String value) {
    switch (value) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium;
    }
  }

  String toFirestore() {
    return toString().split('.').last;
  }
}

// Content structure classes
class TriviaContent {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final DifficultyLevel difficulty;

  TriviaContent({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty.toFirestore(),
    };
  }

  factory TriviaContent.fromFirestore(Map<String, dynamic> data) {
    return TriviaContent(
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correct_answer'] ?? '',
      explanation: data['explanation'] ?? '',
      difficulty: DifficultyLevel.fromString(data['difficulty'] ?? 'medium'),
    );
  }
}

class ParentTipContent {
  final String title;
  final List<String> benefits;
  final String content;
  final String ageGroup;

  ParentTipContent({
    required this.title,
    required this.benefits,
    required this.content,
    required this.ageGroup,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'benefits': benefits,
      'content': content,
      'age_group': ageGroup,
    };
  }

  factory ParentTipContent.fromFirestore(Map<String, dynamic> data) {
    return ParentTipContent(
      title: data['title'] ?? '',
      benefits: List<String>.from(data['benefits'] ?? []),
      content: data['content'] ?? '',
      ageGroup: data['age_group'] ?? '',
    );
  }
}

class DidYouKnowContent {
  final String fact;
  final String details;
  final String category;

  DidYouKnowContent({
    required this.fact,
    required this.details,
    required this.category,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'fact': fact,
      'details': details,
      'category': category,
    };
  }

  factory DidYouKnowContent.fromFirestore(Map<String, dynamic> data) {
    return DidYouKnowContent(
      fact: data['fact'] ?? '',
      details: data['details'] ?? '',
      category: data['category'] ?? '',
    );
  }
}

class ContentFeed {
  final String id;
  final ContentType type;
  final ContentStatus status;
  final String sportCategory;

  // Content data (one of these will be populated based on type)
  final TriviaContent? triviaContent;
  final ParentTipContent? parentTipContent;
  final DidYouKnowContent? didYouKnowContent;

  // Generation metadata
  final String generationSource;
  final String? sourceSportsWikiId;
  final String? aiPromptUsed;

  // System fields
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? publishedAt;

  // Analytics
  final int viewCount;
  final int likeCount;

  ContentFeed({
    required this.id,
    required this.type,
    required this.status,
    required this.sportCategory,
    this.triviaContent,
    this.parentTipContent,
    this.didYouKnowContent,
    required this.generationSource,
    this.sourceSportsWikiId,
    this.aiPromptUsed,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.publishedAt,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  // Factory constructor from Firestore document
  factory ContentFeed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final contentType = ContentType.fromString(data['type'] ?? 'trivia');
    
    return ContentFeed(
      id: doc.id,
      type: contentType,
      status: ContentStatus.fromString(data['status'] ?? 'generated'),
      sportCategory: data['sport_category'] ?? '',
      triviaContent: contentType == ContentType.trivia && data['content'] != null
          ? TriviaContent.fromFirestore(data['content'])
          : null,
      parentTipContent: contentType == ContentType.parentTip && data['content'] != null
          ? ParentTipContent.fromFirestore(data['content'])
          : null,
      didYouKnowContent: contentType == ContentType.didYouKnow && data['content'] != null
          ? DidYouKnowContent.fromFirestore(data['content'])
          : null,
      generationSource: data['generation_source'] ?? '',
      sourceSportsWikiId: data['source_sport_wiki_id'],
      aiPromptUsed: data['ai_prompt_used'],
      createdAt: _parseTimestamp(data['created_at']) ?? DateTime.now(),
      approvedAt: _parseTimestamp(data['approved_at']),
      approvedBy: data['approved_by'],
      publishedAt: _parseTimestamp(data['published_at']),
      viewCount: data['view_count'] ?? 0,
      likeCount: data['like_count'] ?? 0,
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
    Map<String, dynamic> contentData;
    
    switch (type) {
      case ContentType.trivia:
        contentData = triviaContent?.toFirestore() ?? {};
        break;
      case ContentType.parentTip:
        contentData = parentTipContent?.toFirestore() ?? {};
        break;
      case ContentType.didYouKnow:
        contentData = didYouKnowContent?.toFirestore() ?? {};
        break;
    }

    return {
      'type': type.toFirestore(),
      'status': status.toFirestore(),
      'sport_category': sportCategory,
      'content': contentData,
      'generation_source': generationSource,
      'source_sport_wiki_id': sourceSportsWikiId,
      'ai_prompt_used': aiPromptUsed,
      'created_at': FieldValue.serverTimestamp(),
      'approved_at': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approved_by': approvedBy,
      'published_at': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'view_count': viewCount,
      'like_count': likeCount,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    Map<String, dynamic> contentData;
    
    switch (type) {
      case ContentType.trivia:
        contentData = triviaContent?.toFirestore() ?? {};
        break;
      case ContentType.parentTip:
        contentData = parentTipContent?.toFirestore() ?? {};
        break;
      case ContentType.didYouKnow:
        contentData = didYouKnowContent?.toFirestore() ?? {};
        break;
    }

    return {
      'id': id,
      'type': type.toFirestore(),
      'status': status.toFirestore(),
      'sport_category': sportCategory,
      'content': contentData,
      'generation_source': generationSource,
      'source_sport_wiki_id': sourceSportsWikiId,
      'ai_prompt_used': aiPromptUsed,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'published_at': publishedAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
    };
  }

  // Get display title based on content type
  String get displayTitle {
    switch (type) {
      case ContentType.trivia:
        return triviaContent?.question ?? 'Trivia Question';
      case ContentType.parentTip:
        return parentTipContent?.title ?? 'Health Tip';
      case ContentType.didYouKnow:
        return didYouKnowContent?.fact ?? 'Did You Know';
    }
  }

  // Get content preview
  String get contentPreview {
    switch (type) {
      case ContentType.trivia:
        return triviaContent?.explanation ?? '';
      case ContentType.parentTip:
        return parentTipContent?.content ?? '';
      case ContentType.didYouKnow:
        return didYouKnowContent?.details ?? '';
    }
  }

  ContentFeed copyWith({
    String? id,
    ContentType? type,
    ContentStatus? status,
    String? sportCategory,
    TriviaContent? triviaContent,
    ParentTipContent? parentTipContent,
    DidYouKnowContent? didYouKnowContent,
    String? generationSource,
    String? sourceSportsWikiId,
    String? aiPromptUsed,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? publishedAt,
    int? viewCount,
    int? likeCount,
  }) {
    return ContentFeed(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      sportCategory: sportCategory ?? this.sportCategory,
      triviaContent: triviaContent ?? this.triviaContent,
      parentTipContent: parentTipContent ?? this.parentTipContent,
      didYouKnowContent: didYouKnowContent ?? this.didYouKnowContent,
      generationSource: generationSource ?? this.generationSource,
      sourceSportsWikiId: sourceSportsWikiId ?? this.sourceSportsWikiId,
      aiPromptUsed: aiPromptUsed ?? this.aiPromptUsed,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  @override
  String toString() {
    return 'ContentFeed{id: $id, type: $type, status: $status, sportCategory: $sportCategory}';
  }
}
