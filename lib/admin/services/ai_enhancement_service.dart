import 'package:cloud_functions/cloud_functions.dart';
import '../../models/athlete.dart';

/// Service for AI-powered athlete profile enhancement
class AiEnhancementService {
  static AiEnhancementService? _instance;
  static AiEnhancementService get instance => _instance ??= AiEnhancementService._internal();

  AiEnhancementService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Enhance athlete profile using AI
  /// Returns AI-generated data for missing fields only
  Future<AiEnhancementResult> enhanceAthleteProfile({
    required String athleteName,
    required String sport,
    required Map<String, dynamic> currentData,
  }) async {
    try {
      print('🤖 Requesting AI enhancement for: $athleteName ($sport)');
      
      // Call Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('enhanceAthleteProfile');
      final result = await callable.call({
        'athleteName': athleteName,
        'sport': sport,
        'currentData': currentData,
      });

      final data = result.data as Map<String, dynamic>;
      print('📊 AI Enhancement response: ${data['success'] ? 'SUCCESS' : 'FAILED'}');

      if (data['success'] == true) {
        return AiEnhancementResult.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'AI enhancement failed');
      }

    } catch (e) {
      print('❌ AI Enhancement error: $e');
      throw Exception('Failed to enhance athlete profile: $e');
    }
  }

  /// Convert current Athlete object to data map for AI enhancement
  Map<String, dynamic> athleteToCurrentData(Athlete? athlete) {
    if (athlete == null) return {};

    return {
      'name': athlete.name,
      'sport': athlete.sport,
      'isParaAthlete': athlete.isParaAthlete,
      'dob': athlete.dob?.toIso8601String(),
      'placeOfBirth': athlete.placeOfBirth,
      'education': athlete.education,
      'imageUrl': athlete.imageUrl,
      'description': athlete.description,
      'achievements': athlete.achievements.map((a) => a.toJson()).toList(),
      'awards': athlete.awards,
      'funFacts': athlete.funFacts,
    };
  }

  /// Apply AI enhancement results to form controllers and data
  void applyEnhancementToForm({
    required AiEnhancementResult result,
    required Map<String, dynamic> formControllers,
    required Function(String field, dynamic value) onFieldUpdate,
  }) {
    final fields = result.enhancedData.fields;

    // Apply each enhanced field
    fields.forEach((fieldName, value) {
      print('🎯 Applying AI field: $fieldName = $value');
      onFieldUpdate(fieldName, value);
    });
  }
}

/// Result from AI athlete enhancement
class AiEnhancementResult {
  final bool success;
  final String message;
  final AiEnhancedData enhancedData;
  final AiUsageStats? usage;
  final AiErrorInfo? error;

  AiEnhancementResult({
    required this.success,
    required this.message,
    required this.enhancedData,
    this.usage,
    this.error,
  });

  factory AiEnhancementResult.fromJson(Map<String, dynamic> json) {
    return AiEnhancementResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      enhancedData: AiEnhancedData.fromJson(json['enhancedData'] ?? {}),
      usage: json['usage'] != null ? AiUsageStats.fromJson(json['usage']) : null,
      error: json['error'] != null ? AiErrorInfo.fromJson(json['error']) : null,
    );
  }
}

/// AI-enhanced athlete data
class AiEnhancedData {
  final int confidence;
  final bool athleteFound;
  final String sourceReliability;
  final Map<String, dynamic> fields;
  final String notes;

  AiEnhancedData({
    required this.confidence,
    required this.athleteFound,
    required this.sourceReliability,
    required this.fields,
    required this.notes,
  });

  factory AiEnhancedData.fromJson(Map<String, dynamic> json) {
    return AiEnhancedData(
      confidence: json['confidence'] ?? 0,
      athleteFound: json['athlete_found'] ?? false,
      sourceReliability: json['source_reliability'] ?? 'unknown',
      fields: Map<String, dynamic>.from(json['fields'] ?? {}),
      notes: json['notes'] ?? '',
    );
  }

  /// Get confidence color based on percentage
  String get confidenceColor {
    if (confidence >= 80) return 'green';
    if (confidence >= 60) return 'orange';
    return 'red';
  }

  /// Get confidence description
  String get confidenceDescription {
    if (confidence >= 80) return 'High confidence';
    if (confidence >= 60) return 'Moderate confidence';
    if (confidence >= 40) return 'Low confidence';
    return 'Very low confidence';
  }
}

/// AI usage statistics
class AiUsageStats {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  AiUsageStats({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory AiUsageStats.fromJson(Map<String, dynamic> json) {
    return AiUsageStats(
      promptTokens: json['promptTokens'] ?? 0,
      completionTokens: json['completionTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
    );
  }

  /// Estimate cost (approximate GPT-4 pricing)
  double get estimatedCost {
    const inputCostPer1K = 0.03;  // $0.03 per 1K input tokens
    const outputCostPer1K = 0.06; // $0.06 per 1K output tokens
    
    return (promptTokens / 1000 * inputCostPer1K) + 
           (completionTokens / 1000 * outputCostPer1K);
  }
}

/// AI error information
class AiErrorInfo {
  final String code;
  final String details;

  AiErrorInfo({
    required this.code,
    required this.details,
  });

  factory AiErrorInfo.fromJson(Map<String, dynamic> json) {
    return AiErrorInfo(
      code: json['code'] ?? 'unknown',
      details: json['details'] ?? '',
    );
  }
}
