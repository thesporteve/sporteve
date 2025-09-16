import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/news_article.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Share article with text only
  Future<void> shareArticleText(NewsArticle article) async {
    try {
      final String shareText = _buildShareText(article);
      await Share.share(
        shareText,
        subject: article.title,
      );
    } catch (e) {
      print('Error sharing article text: $e');
    }
  }

  /// Share article with generated image
  Future<void> shareArticleWithImage(
    NewsArticle article, 
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      _showLoadingDialog(context);

      // Generate article image
      final Uint8List? imageBytes = await _generateArticleImage(article, context);
      
      // Hide loading
      Navigator.of(context).pop();

      if (imageBytes != null) {
        // Save image to temporary file
        final String imagePath = await _saveImageToTemp(imageBytes, article.id);
        
        // Share with image
        final String shareText = _buildShareText(article);
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
          subject: article.title,
        );
      } else {
        // Fallback to text sharing
        await shareArticleText(article);
      }
    } catch (e) {
      // Hide loading if still showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      print('Error sharing article with image: $e');
      
      // Fallback to text sharing
      await shareArticleText(article);
    }
  }

  /// Share article URL to specific app
  Future<void> shareToApp(NewsArticle article, String appName) async {
    try {
      final String shareText = _buildShareText(article);
      
      switch (appName.toLowerCase()) {
        case 'whatsapp':
          await Share.share(shareText, subject: 'Check out this sports news!');
          break;
        case 'twitter':
          final String twitterText = '${article.title}\n\nRead more in SportEve app! 🏆';
          await Share.share(twitterText);
          break;
        case 'telegram':
          await Share.share(shareText, subject: article.title);
          break;
        default:
          await Share.share(shareText, subject: article.title);
      }
    } catch (e) {
      print('Error sharing to $appName: $e');
    }
  }

  /// Generate article image from widget
  Future<Uint8List?> _generateArticleImage(
    NewsArticle article, 
    BuildContext context,
  ) async {
    try {
      // TODO: Implement proper widget-to-image conversion
      // For now, returning null to fall back to text sharing
      // This avoids the build error with widgets_to_image package
      print('Image generation temporarily disabled - falling back to text sharing');
      return null;
    } catch (e) {
      print('Error generating article image: $e');
      return null;
    }
  }

  /// Build shareable article widget
  Widget _buildShareableArticleWidget(NewsArticle article, BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App branding
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SportEve',
                    style: TextStyle(
                      color: Color(0xFF083d77),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Article title
            Text(
              article.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Article summary
            Text(
              article.summary,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 20),
            
            // Footer
            Row(
              children: [
                Text(
                  'By ${article.author}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  article.source,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Call to action
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_football, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Read full story in SportEve app',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build share text
  String _buildShareText(NewsArticle article) {
    return '''
🏆 ${article.title}

${article.summary}

📰 Source: ${article.source}
✍️ By ${article.author}

Read the full story in SportEve - Your Ultimate Sports News Hub! 📱
    '''.trim();
  }

  /// Save image to temporary file
  Future<String> _saveImageToTemp(Uint8List imageBytes, String articleId) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'sporteve_article_$articleId.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Creating shareable image...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get available share apps (mock data for UI)
  List<ShareApp> getAvailableShareApps() {
    return [
      ShareApp(
        name: 'WhatsApp',
        icon: Icons.message,
        color: const Color(0xFF25D366),
      ),
      ShareApp(
        name: 'Twitter',
        icon: Icons.alternate_email,
        color: const Color(0xFF1DA1F2),
      ),
      ShareApp(
        name: 'Telegram',
        icon: Icons.send,
        color: const Color(0xFF0088CC),
      ),
      ShareApp(
        name: 'Instagram',
        icon: Icons.camera_alt,
        color: const Color(0xFFE4405F),
      ),
      ShareApp(
        name: 'Facebook',
        icon: Icons.facebook,
        color: const Color(0xFF1877F2),
      ),
      ShareApp(
        name: 'More',
        icon: Icons.more_horiz,
        color: Colors.grey,
      ),
    ];
  }
}

/// Share app model
class ShareApp {
  final String name;
  final IconData icon;
  final Color color;

  ShareApp({
    required this.name,
    required this.icon,
    required this.color,
  });
}
