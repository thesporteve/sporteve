import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/news_provider.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';
import '../services/bookmark_service.dart';
import '../services/firebase_image_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({
    super.key,
    required this.newsId,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  NewsArticle? _article;
  bool _isLoading = true;
  String? _error;
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      final article = await context.read<NewsProvider>().getArticleById(widget.newsId);
      if (mounted) {
        setState(() {
          _article = article;
          _isLoading = false;
          if (article != null) {
          }
        });
        
        // Check bookmark status
        if (article != null) {
          _checkBookmarkStatus();
        }
        
        // Track article view (anonymous, non-blocking)
        if (article != null) {
          _trackArticleView();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Check if article is already bookmarked
  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await BookmarkService.instance.isBookmarked(widget.newsId);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      print('Error checking bookmark status: $e');
    }
  }

  /// Track article view anonymously
  Future<void> _trackArticleView() async {
    try {
      await context.read<NewsProvider>().incrementArticleViews(widget.newsId);
    } catch (e) {
      // Silent failure - view tracking shouldn't affect user experience
      print('View tracking failed: $e');
    }
  }


  /// Toggle bookmark status
  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading || _article == null) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      if (_isBookmarked) {
        await BookmarkService.instance.removeBookmark(_article!.id);
        if (mounted) {
          setState(() {
            _isBookmarked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📖 Removed from bookmarks'),
              backgroundColor: Colors.orange.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await BookmarkService.instance.addBookmark(_article!);
        if (mounted) {
          setState(() {
            _isBookmarked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📚 Added to bookmarks'),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Bookmark toggle failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bookmark. Please try again.'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _article == null
                  ? _buildNotFoundWidget()
                  : _buildArticleContent(),
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
            onPressed: _loadArticle,
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
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Article not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The article you\'re looking for doesn\'t exist or has been removed.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        _buildSliverAppBar(),
        
        // Article Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breaking Badge and Category
                _buildHeader(),
                
                const SizedBox(height: 16),
                
                // Title
                _buildTitle(),
                
                const SizedBox(height: 16),
                
                // Meta Information
                _buildMetaInfo(),
                
                const SizedBox(height: 24),
                
                // Content
                _buildContent(),
                
                const SizedBox(height: 32),
                
                // Tags
                _buildTags(),
                
                const SizedBox(height: 32),
                
                // Related Articles
                _buildRelatedArticles(),
                
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
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Check if image URL exists, otherwise show placeholder
            if (_article!.imageUrl != null && _article!.imageUrl!.isNotEmpty)
              _buildDetailNetworkImage()
            else
              _buildPlaceholderBackground(),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: _isBookmarkLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
          onPressed: _isBookmarkLoading ? null : _toggleBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareArticle,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (_article!.isBreaking == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'BREAKING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _article!.category.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      _article!.title,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            _article!.author.isNotEmpty ? _article!.author[0].toUpperCase() : 'A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _article!.author,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(_article!.publishedAt),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      _article!.content,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTags() {
    if (_article!.tags?.isEmpty != false) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _article!.tags!.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelatedArticles() {
    final relatedArticles = context.read<NewsProvider>().articles
        .where((article) => 
            article.id != _article!.id && 
            article.category == _article!.category)
        .take(3)
        .toList();

    if (relatedArticles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Articles',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedArticles.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NewsCard(article: relatedArticles[index]),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return date.toString();
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

  Future<void> _shareArticle() async {
    if (_article == null) return;
    
    try {
      await context.read<NewsProvider>().incrementArticleShares(_article!.id);
      
      final String shareText = '''
🏆 ${_article!.title}

${_article!.summary}

📰 Source: ${_article!.source}
✍️ By ${_article!.author}

Read the full story in SportEve - Your Ultimate Sports News Hub! 📱
      '''.trim();
      
      await Share.share(
        shareText,
        subject: _article!.title,
      );
    } catch (e) {
      print('Error sharing article: $e');
    }
  }

  /// Enhanced network image builder for detail screen with Firebase Storage optimization
  Widget _buildDetailNetworkImage() {
    final imageUrl = _article!.imageUrl!;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      
      // Enhanced caching configuration
      cacheKey: FirebaseImageService.generateCacheKey(imageUrl, _article!.id, prefix: 'detail'),
      memCacheWidth: FirebaseImageService.getMemoryCacheDimensions(isDetail: true)['width'],
      memCacheHeight: FirebaseImageService.getMemoryCacheDimensions(isDetail: true)['height'],
      
      // Loading placeholder with better UX
      placeholder: (context, url) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading image...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      
      // Enhanced error handling with fallback to placeholder
      errorWidget: (context, url, error) {
        // Log the error for debugging Firebase Storage issues
        FirebaseImageService.logImageError(url, error);
        
        // If Firebase Storage URL failed, fallback to placeholder image
        return _buildPlaceholderBackground();
      },
      
      // Progressive loading for better UX
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 200),
      
      // Network retry configuration for Firebase Storage
      httpHeaders: FirebaseImageService.getFirebaseStorageHeaders(imageUrl),
    );
  }


  Widget _buildPlaceholderBackground() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    // First, try athlete image if athleteId exists
    if (_article!.athleteId != null && _article!.athleteId!.isNotEmpty) {
      final athleteName = newsProvider.getAthleteNameById(_article!.athleteId);
      if (athleteName != null) {
        return _buildAthleteBackgroundImage(athleteName);
      }
    }
    
    // Fallback to sport image
    return _buildSportBackgroundImage();
  }

  Widget _buildAthleteBackgroundImage(String athleteName) {
    // Format athlete name for image path (e.g., "Neeraj Chopra" -> "neeraj_chopra")
    final formattedName = _formatAthleteNameForImage(athleteName);
    
    // Try athlete image with number 1 first
    final athleteImagePath = 'images/${formattedName}_1.png';
    
    return Image.asset(
      athleteImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If athlete image fails, fallback to sport image
        return _buildSportBackgroundImage();
      },
    );
  }

  Widget _buildSportBackgroundImage() {
    final category = _article!.category.toLowerCase();
    
    // For now, just try image number 1 to avoid missing asset errors
    final imagePath = 'images/${category}_1.png';
    
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If category image doesn't exist, show default background
        return _buildDefaultBackground();
      },
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

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports,
            size: 64,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'SportEve',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
