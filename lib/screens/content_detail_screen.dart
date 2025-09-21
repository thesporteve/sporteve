import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/content_feed.dart';
import '../services/content_analytics_service.dart';
import '../services/content_like_service.dart';
import '../providers/content_provider.dart';
import '../services/debug_logger.dart';

class ContentDetailScreen extends StatefulWidget {
  final String contentId;
  final ContentFeed? content;

  const ContentDetailScreen({
    super.key,
    required this.contentId,
    this.content,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentFeed? _content;
  bool _isLoading = true;
  String? _error;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      // Use the content passed through the route if available
      if (widget.content != null) {
        print('📱 Using content passed via route: ${widget.content!.id}');
        DebugLogger.instance.logInfo('ContentDetail', 'Using content passed via route: ${widget.content!.id}');
        
        setState(() {
          _content = widget.content;
          _isLoading = false;
        });
        
        // Check like status and track view
        await _checkLikeStatus();
        _trackView();
      } else {
        // Load content by ID from ContentProvider
        print('📱 Loading content by ID: ${widget.contentId}');
        DebugLogger.instance.logInfo('ContentDetail', 'Loading content by ID: ${widget.contentId}');
        
        final contentProvider = context.read<ContentProvider>();
        
        // Check if content is already loaded
        if (contentProvider.allContent.isEmpty) {
          print('📥 Content provider empty, loading content...');
          DebugLogger.instance.logInfo('ContentDetail', 'Content provider empty, loading content...');
          await contentProvider.loadContent();
        }
        
        print('🔍 Searching in ${contentProvider.allContent.length} content items');
        DebugLogger.instance.logInfo('ContentDetail', 'Searching in ${contentProvider.allContent.length} content items');
        
        // Find the content by ID
        final content = contentProvider.allContent
            .where((c) => c.id == widget.contentId)
            .firstOrNull;
        
        if (content != null) {
          print('✅ Found content: ${content.displayTitle} (${content.type})');
          DebugLogger.instance.logSuccess('ContentDetail', 'Found content: ${content.displayTitle} (${content.type})');
          
          setState(() {
            _content = content;
            _isLoading = false;
          });
          
          // Check like status and track view
          await _checkLikeStatus();
          _trackView();
        } else {
          print('❌ Content not found with ID: ${widget.contentId}');
          DebugLogger.instance.logError('ContentDetail', 'Content not found with ID: ${widget.contentId}');
          
          // Debug: Show available content IDs
          final availableIds = contentProvider.allContent.map((c) => c.id).take(5).toList();
          print('📋 Available content IDs (first 5): $availableIds');
          DebugLogger.instance.logInfo('ContentDetail', 'Available content IDs (first 5): $availableIds');
          
          setState(() {
            _error = 'Content not found (ID: ${widget.contentId})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading content: $e');
      DebugLogger.instance.logError('ContentDetail', 'Error loading content: $e');
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _trackView() {
    if (_content != null) {
      ContentAnalyticsService.instance.trackContentView(_content!.id, _content!.type);
    }
  }

  Future<void> _checkLikeStatus() async {
    if (_content == null) return;
    try {
      final isLiked = await ContentLikeService.instance.isContentLiked(_content!.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _likeCount = _content!.likeCount;
        });
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_content == null || _isLikeLoading) return;
    
    try {
      setState(() {
        _isLikeLoading = true;
      });
      
      final newLikeStatus = await ContentLikeService.instance.toggleLike(_content!.id);
      
      if (newLikeStatus && !_isLiked) {
        // User just liked the content
        ContentAnalyticsService.instance.trackContentLike(_content!.id, _content!.type);
        
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
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  Future<void> _shareContent() async {
    if (_content == null) return;
    
    try {
      final shareText = _buildShareText();
      
      // Track share analytics
      ContentAnalyticsService.instance.trackContentShare(
        _content!.id, 
        _content!.type, 
        'native_share'
      );
      
      await Share.share(
        shareText,
        subject: _getContentTypeLabel(),
      );
      
    } catch (e) {
      print('Error sharing content: $e');
    }
  }

  String _buildShareText() {
    switch (_content!.type) {
      case ContentType.parentTip:
        final tip = _content!.parentTipContent!;
        return '👨‍👩‍👧‍👦 ${tip.title}\n\n${tip.content}\n\nShared from SportEve App 🏆\n#ParentingTip #SportEve';
      case ContentType.didYouKnow:
        final fact = _content!.didYouKnowContent!;
        return '💡 Did you know? ${fact.fact}\n\n${fact.details}\n\nShared from SportEve App 🏆\n#DidYouKnow #SportEve';
      case ContentType.trivia:
        final trivia = _content!.triviaContent!;
        return '🧠 Sports Trivia: ${trivia.question}\n\nAnswer: ${trivia.correctAnswer}\n\n${trivia.explanation}\n\nShared from SportEve App 🏆\n#Trivia #SportEve';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _content == null
                  ? _buildNotFoundWidget()
                  : _buildContentDetail(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadContent,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Content not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The content you\'re looking for might have been removed or doesn\'t exist.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentDetail() {
    return CustomScrollView(
      slivers: [
        // App Bar with gradient background
        _buildSliverAppBar(),
        
        // Content Body
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content Header
                _buildContentHeader(),
                
                const SizedBox(height: 16),
                
                // Title
                _buildTitle(),
                
                const SizedBox(height: 16),
                
                // Meta Information
                _buildMetaInfo(),
                
                const SizedBox(height: 24),
                
                // Main Content
                _buildMainContent(),
                
                const SizedBox(height: 32),
                
                // Additional Info (Benefits, Category, etc.)
                _buildAdditionalInfo(),
                
                const SizedBox(height: 32),
                
                // Engagement Stats
                _buildEngagementStats(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _getContentTypeColor(),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getContentTypeColor(),
                _getContentTypeColor().withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getContentTypeIcon(),
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  _getContentTypeLabel(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _shareContent,
          icon: const Icon(Icons.share, color: Colors.white),
        ),
        IconButton(
          onPressed: _toggleLike,
          icon: _isLikeLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
        ),
      ],
    );
  }

  Widget _buildContentHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getContentTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getContentTypeColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _content!.sportCategory.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _getContentTypeColor(),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'PUBLISHED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      _getMainTitle(),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(_content!.publishedAt ?? _content!.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (_content!.approvedBy != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.verified,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'By ${_content!.approvedBy}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _getMainContent(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return _buildParentTipExtras();
      case ContentType.didYouKnow:
        return _buildDidYouKnowExtras();
      case ContentType.trivia:
        return _buildTriviaExtras();
    }
  }

  Widget _buildParentTipExtras() {
    final tip = _content!.parentTipContent!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age Group
        if (tip.ageGroup.isNotEmpty) ...[
          _buildSectionTitle('Recommended Age Group'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tip.ageGroup,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Benefits
        if (tip.benefits.isNotEmpty) ...[
          _buildSectionTitle('Key Benefits'),
          const SizedBox(height: 12),
          ...tip.benefits.asMap().entries.map((entry) {
            final index = entry.key;
            final benefit = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDidYouKnowExtras() {
    final fact = _content!.didYouKnowContent!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fact.category.isNotEmpty) ...[
          _buildSectionTitle('Category'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              fact.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTriviaExtras() {
    final trivia = _content!.triviaContent!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Answer Options'),
        const SizedBox(height: 12),
        ...trivia.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = option == trivia.correctAnswer;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${String.fromCharCode(65 + index)}. ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCorrect 
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCorrect 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                        fontWeight: isCorrect ? FontWeight.w500 : null,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildSectionTitle('Explanation'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            trivia.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: _getContentTypeColor(),
      ),
    );
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(Icons.visibility, '${_content!.viewCount}', 'Views'),
                const SizedBox(width: 24),
                _buildStatItem(Icons.favorite, '$_likeCount', 'Likes'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getContentTypeColor() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return Theme.of(context).colorScheme.primary;
      case ContentType.didYouKnow:
        return const Color(0xFF2196F3);
      case ContentType.trivia:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getContentTypeIcon() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return Icons.family_restroom;
      case ContentType.didYouKnow:
        return Icons.lightbulb_outline;
      case ContentType.trivia:
        return Icons.quiz_outlined;
    }
  }

  String _getContentTypeLabel() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return 'PARENTING TIP';
      case ContentType.didYouKnow:
        return 'DID YOU KNOW';
      case ContentType.trivia:
        return 'TRIVIA';
    }
  }

  String _getMainTitle() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return _content!.parentTipContent?.title ?? '';
      case ContentType.didYouKnow:
        return _content!.didYouKnowContent?.fact ?? '';
      case ContentType.trivia:
        return _content!.triviaContent?.question ?? '';
    }
  }

  String _getMainContent() {
    switch (_content!.type) {
      case ContentType.parentTip:
        return _content!.parentTipContent?.content ?? '';
      case ContentType.didYouKnow:
        return _content!.didYouKnowContent?.details ?? '';
      case ContentType.trivia:
        return 'Select the correct answer from the options below.';
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
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
