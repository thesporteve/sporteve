import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_feed.dart';
import '../services/content_feed_service.dart';

class DailyTipBanner extends StatefulWidget {
  const DailyTipBanner({super.key});

  @override
  State<DailyTipBanner> createState() => _DailyTipBannerState();
}

class _DailyTipBannerState extends State<DailyTipBanner> {
  ContentFeed? _latestContent;
  bool _isLoading = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadLatestContent();
  }

  Future<void> _loadLatestContent() async {
    try {
      final content = await ContentFeedService.instance.getLatestPublishedContent();
      
      if (content != null) {
        // Check if this content was already dismissed today OR already read
        final isDismissed = await _isContentDismissedToday(content.id);
        final isAlreadyRead = await _isContentAlreadyRead(content.id);
        
        if (mounted) {
          setState(() {
            _latestContent = content;
            _isDismissed = isDismissed || isAlreadyRead; // Hide if dismissed OR already read
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isDismissed = true; // No content to show
          });
        }
      }
    } catch (e) {
      print('Error loading latest content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDismissed = true;
        });
      }
    }
  }

  Future<bool> _isContentDismissedToday(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      final dismissKey = 'dismissed_tip_${contentId}_$today';
      return prefs.getBool(dismissKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isContentAlreadyRead(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readContentKey = 'read_content_$contentId';
      return prefs.getBool(readContentKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markContentAsRead(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readContentKey = 'read_content_$contentId';
      await prefs.setBool(readContentKey, true);
    } catch (e) {
      print('Error marking content as read locally: $e');
    }
  }

  Future<void> _dismissBanner() async {
    if (_latestContent == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dismissKey = 'dismissed_tip_${_latestContent!.id}_$today';
      await prefs.setBool(dismissKey, true);
      
      setState(() {
        _isDismissed = true;
      });
    } catch (e) {
      print('Error dismissing banner: $e');
    }
  }

  Future<void> _viewTip() async {
    if (_latestContent == null) return;
    
    // Mark as read both locally and in Firestore
    await _markContentAsRead(_latestContent!.id);
    ContentFeedService.instance.markContentAsRead(_latestContent!.id);
    
    // Navigate to content detail screen instead of tips-facts screen
    context.push('/content/${_latestContent!.id}', extra: _latestContent);
  }

  @override
  Widget build(BuildContext context) {
    // Temporarily hidden for this version - return empty widget
    return const SizedBox.shrink();
  }

  IconData _getContentIcon() {
    switch (_latestContent!.type) {
      case ContentType.parentTip:
        return Icons.medical_services;
      case ContentType.didYouKnow:
        return Icons.lightbulb_outline;
      case ContentType.trivia:
        return Icons.quiz_outlined;
    }
  }

  String _getContentTypeLabel() {
    switch (_latestContent!.type) {
      case ContentType.parentTip:
        return 'HEALTH TIP';
      case ContentType.didYouKnow:
        return 'DID YOU KNOW';
      case ContentType.trivia:
        return 'TRIVIA';
    }
  }

  String _getContentPreview() {
    switch (_latestContent!.type) {
      case ContentType.parentTip:
        return _latestContent!.parentTipContent?.title ?? '';
      case ContentType.didYouKnow:
        return _latestContent!.didYouKnowContent?.fact ?? '';
      case ContentType.trivia:
        return _latestContent!.triviaContent?.question ?? '';
    }
  }
}
