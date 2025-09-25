import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../models/content_feed.dart';
import '../services/content_like_service.dart';
import '../services/content_analytics_service.dart';

class ContentCard extends StatefulWidget {
  final ContentFeed content;
  final bool isRead;
  final VoidCallback onMarkAsRead;

  const ContentCard({
    super.key,
    required this.content,
    required this.isRead,
    required this.onMarkAsRead,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.content.likeCount;
    _checkLikeStatus();
  }

  /// Check if this content is already liked by the user
  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await ContentLikeService.instance.isContentLiked(widget.content.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('Error checking content like status: $e');
    }
  }

  /// Toggle like status and track anonymously
  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    
    try {
      setState(() {
        _isLikeLoading = true;
      });
      
      // Toggle the like status using ContentLikeService
      final newLikeStatus = await ContentLikeService.instance.toggleLike(widget.content.id);
      
      // Track analytics
      if (newLikeStatus && !_isLiked) {
        // User just liked the content
        ContentAnalyticsService.instance.trackContentLike(widget.content.id, widget.content.type);
        
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount += 1;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❤️ Content liked!'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (!newLikeStatus && _isLiked) {
        // User just unliked the content
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('💔 Content unliked'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Like tracking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle like. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Always mark as read when tapped to remove NEW badge
        // This should be called by parent screen to update isRead state
        widget.onMarkAsRead();
        
        // Small delay to ensure state update processes
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          _showContentDetail(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: widget.isRead ? null : Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and actions
            _buildHeader(context),
            
            // Content preview
            _buildContent(context),
            
            // Footer with metadata
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Content type icon and label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(),
                  size: 16,
                  color: _getTypeColor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getTypeColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // New indicator
          if (!widget.isRead) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEW',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Sport category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.content.sportCategory.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title/Main content
          Text(
            _getMainText(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle/Preview
          if (_getSubText().isNotEmpty) ...[
            Text(
              _getSubText(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Date
          Text(
            _formatDate(widget.content.publishedAt ?? widget.content.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          // Analytics
          if (widget.content.viewCount > 0 || _likeCount > 0) ...[
            const SizedBox(width: 12),
            if (widget.content.viewCount > 0) ...[
              Icon(
                Icons.visibility,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.content.viewCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (_likeCount > 0) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.favorite,
                size: 14,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '$_likeCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
          
          const Spacer(),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share button
              InkWell(
                onTap: _shareContent,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Like button
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: _isLikeLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: _isLiked 
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.content.type) {
      case ContentType.parentTip:
        return Icons.family_restroom;
      case ContentType.didYouKnow:
        return Icons.lightbulb_outline;
      case ContentType.trivia:
        return Icons.quiz_outlined;
    }
  }

  String _getTypeLabel() {
    switch (widget.content.type) {
      case ContentType.parentTip:
        return 'PARENTING TIP';
      case ContentType.didYouKnow:
        return 'DID YOU KNOW';
      case ContentType.trivia:
        return 'TRIVIA';
    }
  }

  Color _getTypeColor(BuildContext context) {
    switch (widget.content.type) {
      case ContentType.parentTip:
        return Theme.of(context).colorScheme.primary;
      case ContentType.didYouKnow:
        return const Color(0xFF2196F3); // Bright Material Blue - much more visible
      case ContentType.trivia:
        return const Color(0xFF9C27B0); // Bright Purple for trivia
    }
  }

  String _getMainText() {
    switch (widget.content.type) {
      case ContentType.parentTip:
        return widget.content.parentTipContent?.title ?? '';
      case ContentType.didYouKnow:
        return widget.content.didYouKnowContent?.fact ?? '';
      case ContentType.trivia:
        return widget.content.triviaContent?.question ?? '';
    }
  }

  String _getSubText() {
    switch (widget.content.type) {
      case ContentType.parentTip:
        final tip = widget.content.parentTipContent?.content ?? '';
        return tip.length > 100 ? '${tip.substring(0, 100)}...' : tip;
      case ContentType.didYouKnow:
        final details = widget.content.didYouKnowContent?.details ?? '';
        return details.length > 100 ? '${details.substring(0, 100)}...' : details;
      case ContentType.trivia:
        return ''; // Don't show answer preview
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _showContentDetail(BuildContext context) {
    context.push('/content/${widget.content.id}', extra: widget.content);
  }

  Future<void> _shareContent() async {
    try {
      final shareText = _getShareText();
      
      // Track share analytics
      ContentAnalyticsService.instance.trackContentShare(
        widget.content.id, 
        widget.content.type, 
        'native_share'
      );
      
      // Use native sharing
      await Share.share(
        shareText,
        subject: _getTypeLabel(),
      );
      
    } catch (e) {
      print('Error sharing content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share content'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getShareText() {
    switch (widget.content.type) {
      case ContentType.parentTip:
        final tip = widget.content.parentTipContent;
        return '${tip?.title}\n\n${tip?.content}\n\nShared from SportEve App 🏆\n#ParentingTip #SportEve';
      case ContentType.didYouKnow:
        final fact = widget.content.didYouKnowContent;
        return 'Did you know? ${fact?.fact}\n\n${fact?.details}\n\nShared from SportEve App 🏆\n#DidYouKnow #SportEve';
      case ContentType.trivia:
        final trivia = widget.content.triviaContent;
        return '🧠 Sports Trivia: ${trivia?.question}\n\nAnswer: ${trivia?.correctAnswer}\n\n${trivia?.explanation}\n\nShared from SportEve App 🏆\n#Trivia #SportEve';
    }
  }
}
