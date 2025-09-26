import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/news_article.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_card_list.dart';
import '../forms/news_article_form.dart';
import '../forms/news_article_image_form.dart';
import '../providers/admin_auth_provider.dart';
import 'package:intl/intl.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final AdminDataService _dataService = AdminDataService.instance;
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final articles = await _dataService.getAllNewsArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load articles: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteArticle(String articleId) async {
    final confirmed = await _showDeleteDialog(context);
    if (!confirmed) return;

    try {
      await _dataService.deleteNewsArticle(articleId);
      await _loadArticles(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article deleted successfully'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete article: ${e.toString()}'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _editArticle(NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsArticleForm(
          article: article,
          onSaved: () {
            Navigator.of(context).pop();
            _loadArticles();
          },
        ),
      ),
    );
  }

  void _addArticle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsArticleForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadArticles();
          },
        ),
      ),
    );
  }

  void _addArticleWithImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsArticleImageForm(
          onSaved: () {
            Navigator.of(context).pop();
            _loadArticles();
          },
        ),
      ),
    );
  }

  void _showAddArticleOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Article',
                style: AdminTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.article, color: AdminTheme.primaryColor),
                title: const Text('Add Article'),
                subtitle: const Text('Standard article with text content'),
                onTap: () {
                  Navigator.pop(context);
                  _addArticle();
                },
              ),
              if (authProvider.isSuperAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_photo_alternate, color: AdminTheme.primaryColor),
                  title: const Text('Add Article with Image'),
                  subtitle: const Text('Article with image upload (Super Admin only)'),
                  onTap: () {
                    Navigator.pop(context);
                    _addArticleWithImage();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.orange),
                  title: const Text('🧪 Test Notification'),
                  subtitle: const Text('Send test notification to debug issues'),
                  onTap: () {
                    Navigator.pop(context);
                    _testNotification();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.clear_all, color: Colors.red),
                  title: const Text('🧹 Clear Staging'),
                  subtitle: const Text('Remove all articles from staging collection'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearNewsStaging();
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Builds a processing indicator that shows when articles are being processed
  /// Only shows articles added in the last 10 minutes (actually being processed)
  Widget _buildProcessingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('news_staging')
          .where('submitted_at', 
                 isGreaterThan: Timestamp.fromDate(
                   DateTime.now().subtract(const Duration(minutes: 10))
                 ))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final processingCount = snapshot.data!.docs.length;
        if (processingCount == 0) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🔄 Processing $processingCount article${processingCount > 1 ? 's' : ''}...',
                style: AdminTheme.bodyMedium.copyWith(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Image optimization in progress',
                style: AdminTheme.bodySmall.copyWith(
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _testNotification() async {
    try {
      // Import the notification service
      // You can implement actual test notification logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification feature - to be implemented'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearNewsStaging() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Staging Collection'),
          content: const Text(
            'This will permanently delete all articles in the staging collection. '
            'Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Clearing staging collection...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Call the Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('clearNewsStaging');
      final result = await callable.call();

      // Hide loading and show success
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.data['message'] ?? 'Staging collection cleared successfully'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Refresh the articles list
      await _loadArticles();

    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear staging: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: _buildBody(isDesktop),
      floatingActionButton: Consumer<AdminAuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isSuperAdmin) {
            // Super admins see options button
            return FloatingActionButton.extended(
              onPressed: _showAddArticleOptions,
              icon: const Icon(Icons.add),
              label: const Text('Add Article'),
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            );
          } else {
            // Regular admins see standard add button
            return FloatingActionButton.extended(
              onPressed: _addArticle,
              icon: const Icon(Icons.add),
              label: const Text('Add Article'),
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AdminTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AdminTheme.bodyLarge.copyWith(
                color: AdminTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No articles found',
              style: AdminTheme.titleMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first article to get started',
              style: AdminTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'News Articles',
                style: AdminTheme.titleLarge,
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_articles.length} articles',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: AdminTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadArticles,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Processing Indicator (only shows when articles are being processed)
        _buildProcessingIndicator(),
        
        const Divider(height: 1),
        
        // Content
        Expanded(
          child: isDesktop
              ? _buildDesktopTable()
              : _buildMobileList(),
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final columns = [
      DataColumn(
        label: const Text('Title'),
        onSort: (columnIndex, ascending) {
          setState(() {
            _articles.sort((a, b) => ascending 
                ? a.title.compareTo(b.title)
                : b.title.compareTo(a.title));
          });
        },
      ),
      const DataColumn(label: Text('Author')),
      const DataColumn(label: Text('Category')),
      const DataColumn(label: Text('Published')),
      const DataColumn(label: Text('Views')),
      const DataColumn(label: Text('Actions')),
    ];

    final rows = _articles.map((article) {
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    article.title,
                    style: AdminTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.isBreaking == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminTheme.errorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BREAKING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          DataCell(Text(article.author)),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                article.category,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          DataCell(
            Text(
              DateFormat('MMM dd, yyyy').format(article.publishedAt),
              style: AdminTheme.bodyMedium,
            ),
          ),
          DataCell(
            Text(
              article.views.toString(),
              style: AdminTheme.bodyMedium,
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editArticle(article),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteArticle(article.id),
                  tooltip: 'Delete',
                  color: AdminTheme.errorColor,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return AdminDataTable(
      columns: columns,
      rows: rows,
    );
  }

  Widget _buildMobileList() {
    return AdminCardList<NewsArticle>(
      items: _articles,
      itemBuilder: (article) => _buildMobileArticleCard(article),
    );
  }

  Widget _buildMobileArticleCard(NewsArticle article) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: AdminTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${article.author}',
                        style: AdminTheme.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (article.isBreaking == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminTheme.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BREAKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    article.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMM dd').format(article.publishedAt),
                  style: AdminTheme.caption,
                ),
                const SizedBox(width: 12),
                Text(
                  '${article.views} views',
                  style: AdminTheme.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _editArticle(article),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _deleteArticle(article.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
