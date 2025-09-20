import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/news_article.dart';
import '../utils/sports_icons.dart';
import '../services/bookmark_service.dart';
import '../services/like_service.dart';
import '../providers/news_provider.dart';

class NewsPageCard extends StatefulWidget {
  final NewsArticle article;

  const NewsPageCard({
    super.key,
    required this.article,
  });

  @override
  State<NewsPageCard> createState() => _NewsPageCardState();
}

class _NewsPageCardState extends State<NewsPageCard> {
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.article.likes;
    _checkBookmarkStatus();
    _checkLikeStatus();
  }

  /// Check if this article is already liked by the user
  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await LikeService.instance.isArticleLiked(widget.article.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await BookmarkService.instance.isBookmarked(widget.article.id);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      if (_isBookmarked) {
        final success = await BookmarkService.instance.removeBookmark(widget.article.id);
        if (success && mounted) {
          setState(() {
            _isBookmarked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from bookmarks'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final success = await BookmarkService.instance.addBookmark(widget.article);
        if (success && mounted) {
          setState(() {
            _isBookmarked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to bookmarks'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating bookmark: $e'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
      }
    }
  }

  Future<void> _launchSourceUrl(BuildContext context) async {
    if (widget.article.sourceUrl == null || widget.article.sourceUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No source URL available'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(widget.article.sourceUrl!);
      
      // Try to launch URL directly without checking canLaunchUrl first
      // This avoids the component name issue and is more reliable
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      
      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening source...'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // If direct launch fails, try alternative approach
      try {
        final Uri url = Uri.parse(widget.article.sourceUrl!);
        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open source: ${widget.article.source}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Toggle like status and track anonymously
  Future<void> _likeArticle() async {
    if (_isLikeLoading) return;
    
    try {
      setState(() {
        _isLikeLoading = true;
      });
      
      // Toggle the like status using LikeService
      final newLikeStatus = await LikeService.instance.toggleLike(widget.article.id);
      
      // Update Firebase count based on the action
      if (newLikeStatus && !_isLiked) {
        // User just liked the article
        await context.read<NewsProvider>().incrementArticleLikes(widget.article.id);
        
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount += 1;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❤️ Article liked!'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (!newLikeStatus && _isLiked) {
        // User just unliked the article
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('💔 Article unliked'),
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

  /// Share article directly with native share
  Future<void> _shareArticle() async {
    try {
      await context.read<NewsProvider>().incrementArticleShares(widget.article.id);
      
      final String shareText = '''
🏆 ${widget.article.title}

${widget.article.summary}

📰 Source: ${widget.article.source}
✍️ By ${widget.article.author}

Read the full story in SportEve - Your Ultimate Sports News Hub! 📱
      '''.trim();
      
      await Share.share(
        shareText,
        subject: widget.article.title,
      );
    } catch (e) {
      print('Error sharing article: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        // Check if it's a left swipe (negative velocity)
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          _launchSourceUrl(context);
        }
      },
      onDoubleTap: () {
        // Navigate to news detail screen
        context.push('/news/${widget.article.id}');
        
        // Show subtle feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening full article...'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sports Icon
          _buildSportsIcon(),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  _buildCategory(),
                  
                  const SizedBox(height: 4),
                  
                  // Title
                  _buildTitle(),
                  
                  const SizedBox(height: 6),
                  
                  // Summary - Use Expanded to take available space
                  Expanded(
                    child: _buildSummary(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Source
                  _buildSource(),
                  
                  const SizedBox(height: 8),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSportsIcon() {
    final category = widget.article.category.toLowerCase();
    final sportDisplayName = SportsIcons.getSportDisplayName(widget.article.category);

    // Always try to load custom images first, with automatic fallback to icons
    return _buildSportsImage(category, sportDisplayName);
  }

  Widget _buildSportsImage(String category, String sportDisplayName) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    // First, try athlete image if athleteId exists
    if (widget.article.athleteId != null && widget.article.athleteId!.isNotEmpty) {
      final athleteName = newsProvider.getAthleteNameById(widget.article.athleteId);
      if (athleteName != null) {
        return _buildAthleteImage(athleteName, sportDisplayName);
      }
    }
    
    // Fallback to sport image
    return _buildSportImage(category, sportDisplayName);
  }

  Widget _buildAthleteImage(String athleteName, String sportDisplayName) {
    // Format athlete name for image path (e.g., "Neeraj Chopra" -> "neeraj_chopra")
    final formattedName = _formatAthleteNameForImage(athleteName);
    
    // Try athlete image with number 1 first
    final athleteImagePath = 'images/${formattedName}_1.png';
    
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.asset(
          athleteImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If athlete image fails, fallback to sport image
            return _buildSportImage(widget.article.category.toLowerCase(), sportDisplayName);
          },
        ),
      ),
    );
  }

  Widget _buildSportImage(String category, String sportDisplayName) {
    // For now, just try image number 1 to avoid missing asset errors
    final imagePath = 'images/${category}_1.png';

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If category image doesn't exist, show default icon
            return _buildDefaultIconDisplay(sportDisplayName);
          },
        ),
      ),
    );
  }

  String _formatAthleteNameForImage(String athleteName) {
    // Convert to lowercase and replace spaces with underscores
    // Remove special characters and handle multiple spaces
    return athleteName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace one or more spaces with underscore
        .trim();
  }

  Widget _buildDefaultIconDisplay(String sportDisplayName) {
    final iconData = SportsIcons.getSportsIcon(widget.article.category);
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 50,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            sportDisplayName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Text(
      _formatCategory(widget.article.category),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Format category name for better display (fixes underscores and capitalization)
  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')  // Replace underscores with spaces
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  Widget _buildTitle() {
    return Text(
      widget.article.title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSummary() {
    return SingleChildScrollView(
      child: Text(
        widget.article.summary,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontSize: 13,
          height: 1.3,
        ),
        maxLines: null, // Allow text to flow naturally
        overflow: TextOverflow.visible,
      ),
    );
  }


  Widget _buildSource() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source row
        Row(
          children: [
            Text(
              'Source: ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Open source website
              },
              child: Text(
                _getSourceName(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        // Timestamp row
        const SizedBox(height: 2),
        Text(
          _formatTimestamp(widget.article.publishedAt),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date for older articles
      final formatter = DateFormat('MMM dd, yyyy');
      return formatter.format(timestamp);
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Double tap hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Double tap to read',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons
        Row(
          children: [
            _buildActionButton(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              _toggleBookmark,
              isHighlighted: true,
              isLoading: _isBookmarkLoading,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              _isLiked ? Icons.favorite : Icons.favorite_border, 
              _likeArticle,
              color: Colors.red,
              isHighlighted: _isLiked,
              isLoading: _isLikeLoading,
            ),
            const SizedBox(width: 12),
            _buildActionButton(Icons.share, () => _shareArticle()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {bool isHighlighted = false, bool isLoading = false, Color? color}) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? (isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            : Icon(
                icon,
                color: color ?? (isHighlighted ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                size: 20,
              ),
      ),
    );
  }

  String _getSourceName() {
    // Use the actual source from the article if available
    if (widget.article.source.isNotEmpty) {
      return widget.article.source;
    }
    
    // Fallback to category-based source names if no source provided
    switch (widget.article.category.toLowerCase()) {
      case 'football':
        return 'ESPN';
      case 'basketball':
        return 'Bleacher Report';
      case 'soccer':
        return 'The Guardian';
      case 'tennis':
        return 'Tennis.com';
      case 'olympics':
        return 'Olympics.com';
      default:
        return 'Sports News';
    }
  }
}
