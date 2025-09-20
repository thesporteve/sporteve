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
        // Check if this content was already dismissed today
        final isDismissed = await _isContentDismissedToday(content.id);
        
        if (mounted) {
          setState(() {
            _latestContent = content;
            _isDismissed = isDismissed;
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
    
    // Mark as read
    ContentFeedService.instance.markContentAsRead(_latestContent!.id);
    
    // Navigate to tips screen with this content highlighted
    context.push('/tips-facts?highlight=${_latestContent!.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isDismissed || _latestContent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _viewTip,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon based on content type
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getContentIcon(),
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Content preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getContentTypeLabel(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        _getContentPreview(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Dismiss button
                InkWell(
                  onTap: _dismissBanner,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getContentIcon() {
    switch (_latestContent!.type) {
      case ContentType.parentTip:
        return Icons.family_restroom;
      case ContentType.didYouKnow:
        return Icons.lightbulb_outline;
      case ContentType.trivia:
        return Icons.quiz_outlined;
    }
  }

  String _getContentTypeLabel() {
    switch (_latestContent!.type) {
      case ContentType.parentTip:
        return 'PARENTING TIP';
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
