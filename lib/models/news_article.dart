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
  final int likes;
  final int shares;
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
    this.likes = 0,
    this.shares = 0,
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
      publishedAt: _parseTimestamp(json['publishedAt']),
      imageUrl: json['imageUrl'],
      category: json['category'] ?? '',
      source: json['source'] ?? '',
      sourceUrl: json['sourceUrl'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      readTime: json['readTime'],
      isBreaking: json['isBreaking'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
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
      publishedAt: _parseTimestamp(data['publishedAt']),
      imageUrl: data['imageUrl'] ?? data['image_url'],
      category: data['category'] ?? '',
      source: data['source'] ?? '',
      sourceUrl: data['sourceUrl'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      readTime: data['readTime'],
      isBreaking: data['isBreaking'],
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      shares: data['shares'] ?? 0,
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
      'likes': likes,
      'shares': shares,
      'relatedArticles': relatedArticles,
      'tournamentId': tournamentId,
      'athleteId': athleteId,
    };
  }

  // Helper method to parse different timestamp formats from Firestore
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('Error parsing timestamp string: $timestamp, using current time');
        return DateTime.now();
      }
    } else {
      print('Unknown timestamp type: ${timestamp.runtimeType}, using current time');
      return DateTime.now();
    }
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
    int? likes,
    int? shares,
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
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      relatedArticles: relatedArticles ?? this.relatedArticles,
      tournamentId: tournamentId ?? this.tournamentId,
      athleteId: athleteId ?? this.athleteId,
    );
  }
}

// Removed unused NewsCategory enum - app uses flexible string-based categories instead
