import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/news_article.dart';
import '../providers/news_provider.dart';
import '../services/like_service.dart';
import '../services/share_service.dart';
import '../services/firebase_image_service.dart';
import '../providers/settings_provider.dart';

class NewsCard extends StatefulWidget {
  final NewsArticle article;
  final bool isFeatured;

  const NewsCard({
    super.key,
    required this.article,
    this.isFeatured = false,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.article.likes;
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

  /// Toggle like status and track anonymously
  Future<void> _toggleLike() async {
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
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open source: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
      child: Card(
        elevation: widget.isFeatured ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            context.push('/news/${widget.article.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  _buildImage(context),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and Breaking Badge
                        _buildHeader(context),
                        
                        const SizedBox(height: 8),
                        
                        // Title
                        Text(
                          widget.article.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: widget.isFeatured ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Summary
                  if (!widget.isFeatured) ...[
                    Text(
                      widget.article.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Footer
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
        // Swipe indicator removed for cleaner UI - swipe functionality still works
        ],
      ),
    ),
  ),
);
  }

  Widget _buildImage(BuildContext context) {
    // Debug logging for first article image loading
    print('🖼️ Article: ${widget.article.title.substring(0, 20)}... | ImageURL: ${widget.article.imageUrl ?? "NULL"}');
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          // Check if imageUrl is null or empty, show custom image or placeholder
          if (widget.article.imageUrl == null || widget.article.imageUrl!.isEmpty)
            _buildPlaceholderImage(context)
          else
            _buildNetworkImage(context),
          
          // Breaking News Badge (only show on default placeholders, not custom sport images)
          if (widget.article.isBreaking == true && !_hasCustomImage())
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
                child: Text(
                  'BREAKING',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Category Badge (only show on default placeholders, not custom sport images)
          if (!_hasCustomImage())
            Positioned(
              top: 12,
              right: 12, // Consistent positioning since swipe indicator removed
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatCategory(widget.article.category),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Enhanced network image builder with Firebase Storage optimization and better caching
  Widget _buildNetworkImage(BuildContext context) {
    final originalImageUrl = widget.article.imageUrl!;
    // Use optimized thumbnail URL for faster loading
    final optimizedImageUrl = FirebaseImageService.getCardThumbnailUrl(
      originalImageUrl, 
      isFeatured: widget.isFeatured
    );
    
    return CachedNetworkImage(
      imageUrl: optimizedImageUrl,
      width: double.infinity,
      height: widget.isFeatured ? 180 : 260,
      fit: BoxFit.cover,
      
      // Enhanced caching configuration with optimized dimensions
      cacheKey: FirebaseImageService.generateCacheKey(optimizedImageUrl, widget.article.id, prefix: 'card_thumb'),
      memCacheWidth: widget.isFeatured ? 600 : 400,  // Match optimized sizes
      memCacheHeight: widget.isFeatured ? 320 : 240, // Match optimized sizes
      maxWidthDiskCache: widget.isFeatured ? 600 : 400,  // Reduce disk cache size
      maxHeightDiskCache: widget.isFeatured ? 320 : 240, // for faster access
      
      // Loading placeholder with better UX
      placeholder: (context, url) => Container(
        height: widget.isFeatured ? 180 : 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading image...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      
      // Enhanced error handling with fallback to placeholder
      errorWidget: (context, url, error) {
        // Log the error for debugging Firebase Storage issues
        FirebaseImageService.logImageError(url, error);
        print('🚨 Image Load Error: $url | Error: $error');
        
        // If Firebase Storage URL failed, fallback to placeholder image
        return Container(
          height: widget.isFeatured ? 180 : 260,
          child: _buildPlaceholderImage(context),
        );
      },
      
      // Faster progressive loading for better UX
      fadeInDuration: const Duration(milliseconds: 200), // Reduced for snappier feel
      fadeOutDuration: const Duration(milliseconds: 50),  // Reduced for snappier feel
      
      // Network retry configuration for Firebase Storage
      httpHeaders: FirebaseImageService.getFirebaseStorageHeaders(optimizedImageUrl),
      
      // Advanced caching settings for better performance
      cacheManager: null, // Use default manager with better settings
      useOldImageOnUrlChange: true, // Show old image while loading new one
      filterQuality: FilterQuality.low, // Faster rendering for thumbnails
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Category
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _formatCategory(widget.article.category),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Read Time
        Row(
          children: [
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Author Info (Full space, no crowding)
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.article.author.isNotEmpty ? widget.article.author[0].toUpperCase() : 'A',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.article.author,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Row 2: Metadata & Actions  
        Row(
          children: [
            // Published Date
            Text(
              _formatDate(widget.article.publishedAt),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            // Engagement Stats with bullet separator
            if (widget.article.views > 0 || _likeCount > 0 || widget.article.shares > 0) ...[
              Text(
                ' • ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
            
            // Views
            if (widget.article.views > 0) ...[
              Icon(
                Icons.visibility,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 2),
              Text(
                _formatViews(widget.article.views),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
            
            // Likes  
            if (_likeCount > 0) ...[
              if (widget.article.views > 0) ...[
                Text(
                  ' • ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
              Icon(
                Icons.favorite,
                size: 12,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(width: 2),
              Text(
                _formatViews(_likeCount),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
            
            const Spacer(),
            
            // Action Buttons (Right aligned)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                GestureDetector(
                  onTap: _isLikeLoading ? null : () => _toggleLike(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: (_isLiked ? Colors.red : Colors.red.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _isLikeLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isLiked ? Colors.white : Colors.red,
                              ),
                            ),
                          )
                        : Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: _isLiked ? Colors.white : Colors.red,
                          ),
                  ),
                ),
                
                const SizedBox(width: 6),
                
                // Share Button
                GestureDetector(
                  onTap: () => _shareArticle(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.share,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return date.toString();
    }
  }

  /// Share article using ShareService with smart deep linking
  Future<void> _shareArticle(BuildContext context) async {
    try {
      await context.read<NewsProvider>().incrementArticleShares(widget.article.id);
      
      // Use ShareService for smart deep linking
      await ShareService().shareArticleText(widget.article);
    } catch (e) {
      print('Error sharing article: $e');
    }
  }

  /// Format category name using dynamic sports data with static fallback
  String _formatCategory(String category) {
    try {
      // Try to get dynamic display name from SettingsProvider
      final settingsProvider = context.read<SettingsProvider>();
      return settingsProvider.getSportDisplayName(category);
    } catch (e) {
      // Fallback to static formatting if provider not available
      return category
          .replaceAll('_', ' ')  // Replace underscores with spaces
          .split(' ')
          .map((word) => word.isNotEmpty 
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word)
          .join(' ');
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return views.toString();
    }
  }


  Widget _buildPlaceholderImage(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    // First, try athlete image if athleteId exists
    if (widget.article.athleteId != null && widget.article.athleteId!.isNotEmpty) {
      final athleteName = newsProvider.getAthleteNameById(widget.article.athleteId);
      if (athleteName != null) {
        return _buildAthleteImage(context, athleteName);
      }
    }
    
    // Fallback to sport image
    return _buildSportImage(context);
  }

  Widget _buildAthleteImage(BuildContext context, String athleteName) {
    // Format athlete name for image path (e.g., "Neeraj Chopra" -> "neeraj_chopra")
    final formattedName = _formatAthleteNameForImage(athleteName);
    
    // Try athlete image with number 1 first
    final athleteImagePath = 'images/${formattedName}_1.png';
    
    return SizedBox(
      width: double.infinity,
      height: widget.isFeatured ? 180 : 260,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.asset(
          athleteImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If athlete image fails, fallback to sport image
            return _buildSportImage(context);
          },
        ),
      ),
    );
  }

  Widget _buildSportImage(BuildContext context) {
    final category = widget.article.category.toLowerCase();
    
    // For now, just try image number 1 to avoid missing asset errors
    // You can add more images later and increase this number
    final imagePath = 'images/${category}_1.png';
    
    return SizedBox(
      width: double.infinity,
      height: widget.isFeatured ? 180 : 260,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If category image doesn't exist, show default placeholder
            return _buildDefaultPlaceholder(context);
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

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.isFeatured ? 180 : 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'SportEve',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasCustomImage() {
    // Check if article has a custom image URL
    return widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty;
  }
}
