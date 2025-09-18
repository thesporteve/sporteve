import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../services/admin_data_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_card_list.dart';
import '../forms/news_article_form.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      body: _buildBody(isDesktop),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addArticle,
        icon: const Icon(Icons.add),
        label: const Text('Add Article'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
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
