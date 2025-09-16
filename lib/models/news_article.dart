import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String author;
  final DateTime publishedAt;
  final String? imageUrl;
  final String category;
  final String source;
  final String? sourceUrl;
  final List<String>? tags;
  final int? readTime; // in minutes
  final bool? isBreaking;
  final int views;
  final List<String> relatedArticles;
  final String? tournamentId;
  final String? athleteId;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.author,
    required this.publishedAt,
    this.imageUrl,
    required this.category,
    required this.source,
    this.sourceUrl,
    this.tags,
    this.readTime,
    this.isBreaking,
    this.views = 0,
    this.relatedArticles = const [],
    this.tournamentId,
    this.athleteId,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? json['description'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      publishedAt: json['publishedAt'] is DateTime 
          ? json['publishedAt'] 
          : DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['imageUrl'],
      category: json['category'] ?? '',
      source: json['source'] ?? '',
      sourceUrl: json['sourceUrl'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      readTime: json['readTime'],
      isBreaking: json['isBreaking'],
      views: json['views'] ?? 0,
      relatedArticles: List<String>.from(json['relatedArticles'] ?? []),
      tournamentId: json['tournamentId'],
      athleteId: json['athleteId'],
    );
  }

  factory NewsArticle.fromFirestore(String id, Map<String, dynamic> data) {
    return NewsArticle(
      id: id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? data['description'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      publishedAt: data['publishedAt'] is DateTime 
          ? data['publishedAt'] 
          : (data['publishedAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? data['image_url'],
      category: data['category'] ?? '',
      source: data['source'] ?? '',
      sourceUrl: data['sourceUrl'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      readTime: data['readTime'],
      isBreaking: data['isBreaking'],
      views: data['views'] ?? 0,
      relatedArticles: List<String>.from(data['relatedArticles'] ?? []),
      tournamentId: data['tournamentId'],
      athleteId: data['athleteId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'category': category,
      'source': source,
      'sourceUrl': sourceUrl,
      'tags': tags,
      'readTime': readTime,
      'isBreaking': isBreaking,
      'views': views,
      'relatedArticles': relatedArticles,
      'tournamentId': tournamentId,
      'athleteId': athleteId,
    };
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? author,
    DateTime? publishedAt,
    String? imageUrl,
    String? category,
    String? source,
    String? sourceUrl,
    List<String>? tags,
    int? readTime,
    bool? isBreaking,
    int? views,
    List<String>? relatedArticles,
    String? tournamentId,
    String? athleteId,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      tags: tags ?? this.tags,
      readTime: readTime ?? this.readTime,
      isBreaking: isBreaking ?? this.isBreaking,
      views: views ?? this.views,
      relatedArticles: relatedArticles ?? this.relatedArticles,
      tournamentId: tournamentId ?? this.tournamentId,
      athleteId: athleteId ?? this.athleteId,
    );
  }
}

enum NewsCategory {
  football,
  basketball,
  tennis,
  cricket,
  baseball,
  soccer,
  olympics,
  general,
}

extension NewsCategoryExtension on NewsCategory {
  String get displayName {
    switch (this) {
      case NewsCategory.football:
        return 'Football';
      case NewsCategory.basketball:
        return 'Basketball';
      case NewsCategory.tennis:
        return 'Tennis';
      case NewsCategory.cricket:
        return 'Cricket';
      case NewsCategory.baseball:
        return 'Baseball';
      case NewsCategory.soccer:
        return 'Soccer';
      case NewsCategory.olympics:
        return 'Olympics';
      case NewsCategory.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case NewsCategory.football:
        return '🏈';
      case NewsCategory.basketball:
        return '🏀';
      case NewsCategory.tennis:
        return '🎾';
      case NewsCategory.cricket:
        return '🏏';
      case NewsCategory.baseball:
        return '⚾';
      case NewsCategory.soccer:
        return '⚽';
      case NewsCategory.olympics:
        return '🏅';
      case NewsCategory.general:
        return '📰';
    }
  }
}
