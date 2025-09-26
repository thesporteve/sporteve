import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/content_feed.dart';
import '../services/admin_content_service.dart';
import '../../services/content_analytics_service.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import 'content_edit_screen.dart';
import 'package:intl/intl.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() => _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState extends State<AdminContentManagementScreen> with SingleTickerProviderStateMixin {
  final AdminContentService _contentService = AdminContentService.instance;
  
  late TabController _tabController;
  List<ContentFeed> _allContent = [];
  List<ContentFeed> _filteredContent = [];
  Map<String, int> _statistics = {};
  Map<String, int> _sportDistribution = {};
  
  // Analytics data
  Map<String, dynamic> _analyticsStats = {};
  List<ContentFeed> _topPerformingContent = [];
  Map<String, int> _performanceBySport = {};
  Map<String, int> _performanceByType = {};
  List<Map<String, dynamic>> _recentInteractions = [];
  
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedContentType = 'All';
  String _selectedStatus = 'All';
  String _selectedSport = 'All';

  final List<String> _contentTypes = ['All', 'Trivia', 'Health Tip', 'Did You Know'];
  final List<String> _statusTypes = ['All', 'Generated', 'Approved', 'Published', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allContent = await _contentService.getAllContentFeeds();
      final statistics = await _contentService.getContentStatistics();
      final sportDistribution = await _contentService.getSportWiseDistribution();
      
      // Load analytics data
      await _loadAnalyticsData();

      setState(() {
        _allContent = allContent;
        _filteredContent = allContent;
        _statistics = statistics;
        _sportDistribution = sportDistribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load content data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalyticsData() async {
    try {
      // Load overall performance stats
      final stats = await ContentAnalyticsService.instance.getContentPerformanceStats();
      
      // Load top performing content
      final publishedContent = await _contentService.getContentFeedsByStatus(ContentStatus.published);
      final sortedContent = List<ContentFeed>.from(publishedContent);
      sortedContent.sort((a, b) => (b.viewCount + b.likeCount * 2).compareTo(a.viewCount + a.likeCount * 2));
      
      // Load recent interactions
      final recentInteractions = await _getRecentInteractions();
      
      _analyticsStats = stats;
      _topPerformingContent = sortedContent.take(10).toList();
      _performanceBySport = Map<String, int>.from(stats['performance_by_sport'] ?? {});
      _performanceByType = Map<String, int>.from(stats['performance_by_type'] ?? {});
      _recentInteractions = recentInteractions;
    } catch (e) {
      print('❌ Error loading analytics data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentInteractions() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('user_interactions')
          .orderBy('timestamp', descending: true)
          .limit(20);
      
      final snapshot = await query.get();
      
      List<Map<String, dynamic>> interactions = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Get content details
        try {
          final contentDoc = await FirebaseFirestore.instance
              .collection('content_feeds')
              .doc(data['content_id'])
              .get();
          
          if (contentDoc.exists) {
            final contentData = contentDoc.data() as Map<String, dynamic>;
            interactions.add({
              'action': data['action'],
              'content_type': data['content_type'],
              'timestamp': data['timestamp'],
              'content_title': _getContentTitle(contentData),
              'sport_category': contentData['sport_category'],
            });
          }
        } catch (e) {
          print('Error loading content for interaction: $e');
        }
      }
      
      return interactions;
    } catch (e) {
      print('Error loading recent interactions: $e');
      return [];
    }
  }

  String _getContentTitle(Map<String, dynamic> contentData) {
    final type = ContentType.fromString(contentData['type'] ?? '');
    final content = contentData['content'] as Map<String, dynamic>? ?? {};
    
    switch (type) {
      case ContentType.parentTip:
        return content['title'] ?? 'Untitled Health Tip';
      case ContentType.didYouKnow:
        return content['fact']?.substring(0, 50) ?? 'Did You Know Fact';
      case ContentType.trivia:
        return content['question']?.substring(0, 50) ?? 'Trivia Question';
    }
  }

  void _filterContent() {
    setState(() {
      _filteredContent = _allContent.where((content) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            content.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            content.contentPreview.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            content.sportCategory.toLowerCase().contains(_searchQuery.toLowerCase());

        // Content type filter
        final matchesType = _selectedContentType == 'All' ||
            (_selectedContentType == 'Trivia' && content.type == ContentType.trivia) ||
            (_selectedContentType == 'Health Tip' && content.type == ContentType.parentTip) ||
            (_selectedContentType == 'Did You Know' && content.type == ContentType.didYouKnow);

        // Status filter
        final matchesStatus = _selectedStatus == 'All' ||
            (_selectedStatus == 'Generated' && content.status == ContentStatus.generated) ||
            (_selectedStatus == 'Approved' && content.status == ContentStatus.approved) ||
            (_selectedStatus == 'Published' && content.status == ContentStatus.published) ||
            (_selectedStatus == 'Rejected' && content.status == ContentStatus.rejected);

        // Sport filter
        final matchesSport = _selectedSport == 'All' ||
            content.sportCategory.toLowerCase() == _selectedSport.toLowerCase();

        return matchesSearch && matchesType && matchesStatus && matchesSport;
      }).toList();
    });
  }

  Future<void> _updateContentStatus(String id, ContentStatus newStatus, String title) async {
    try {
      switch (newStatus) {
        case ContentStatus.published:
          await _contentService.publishContentFeed(id);
          break;
        case ContentStatus.approved:
          await _contentService.approveContentFeed(id, 'admin');
          break;
        case ContentStatus.rejected:
          await _contentService.rejectContentFeed(id);
          break;
        case ContentStatus.generated:
          // Can't revert to generated status
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "$title" to ${newStatus.displayName}'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }

      _loadContentData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  void _editContent(ContentFeed content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentEditScreen(
          content: content,
          onContentUpdated: () {
            _loadContentData(); // Refresh the list
          },
        ),
      ),
    );
  }

  Future<void> _deleteContent(String id, String title) async {
    final confirmed = await _showDeleteDialog(title);
    if (!confirmed) return;

    try {
      await _contentService.deleteContentFeed(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "$title"'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }

      _loadContentData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "$title"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AdminTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Overview',
            style: AdminTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Stats cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2, // Adjusted to prevent overflow
            children: [
              _buildStatCard(
                'Total Content',
                _statistics['total']?.toString() ?? '0',
                Icons.library_books,
                AdminTheme.primaryColor,
              ),
              _buildStatCard(
                'Published',
                _statistics['published']?.toString() ?? '0',
                Icons.publish,
                AdminTheme.successColor,
              ),
              _buildStatCard(
                'Pending Review',
                _statistics['generated']?.toString() ?? '0',
                Icons.pending,
                AdminTheme.warningColor,
              ),
              _buildStatCard(
                'Approved',
                _statistics['approved']?.toString() ?? '0',
                Icons.check_circle,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Content type breakdown
          Text(
            'Content Types',
            style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Trivia Questions',
                  _statistics['trivia']?.toString() ?? '0',
                  Icons.quiz,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Health Tips',
                  _statistics['parent_tips']?.toString() ?? '0',
                  Icons.medical_services,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Did You Know',
                  _statistics['did_you_know']?.toString() ?? '0',
                  Icons.lightbulb,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Top sports
          if (_sportDistribution.isNotEmpty) ...[
            Text(
              'Content by Sport',
              style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: _sportDistribution.entries.take(5).map((entry) {
                  final maxCount = _sportDistribution.values.reduce((a, b) => a > b ? a : b);
                  final percentage = entry.value / maxCount;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            entry.key,
                            style: AdminTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value.toString(),
                          style: AdminTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AdminTheme.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AdminTheme.bodySmall.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search all content...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterContent();
            },
          ),
          const SizedBox(height: 12),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _contentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedContentType = value!);
                    _filterContent();
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusTypes.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _filterContent();
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              ElevatedButton.icon(
                onPressed: _loadContentData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return Column(
      children: [
        _buildFiltersBar(),
        Expanded(
          child: _filteredContent.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No content matches your filters',
                        style: AdminTheme.titleLarge.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: AdminTheme.bodyMedium.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredContent.length,
                  itemBuilder: (context, index) {
                    return _buildContentCard(_filteredContent[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContentCard(ContentFeed content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Content type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(content.type.icon),
                      const SizedBox(width: 4),
                      Text(
                        content.type.displayName,
                        style: AdminTheme.bodySmall.copyWith(
                          color: AdminTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Sport badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.sportCategory,
                    style: AdminTheme.bodySmall.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(content.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content.status.displayName,
                    style: AdminTheme.bodySmall.copyWith(
                      color: _getStatusColor(content.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Actions menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    // Only show edit option for unpublished content
                    if (content.status != ContentStatus.published)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (content.status == ContentStatus.approved)
                      const PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.publish, size: 18),
                            SizedBox(width: 8),
                            Text('Publish'),
                          ],
                        ),
                      ),
                    if (content.status == ContentStatus.generated)
                      const PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18),
                            SizedBox(width: 8),
                            Text('Approve'),
                          ],
                        ),
                      ),
                    if (content.status != ContentStatus.rejected)
                      const PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 18),
                            SizedBox(width: 8),
                            Text('Reject'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editContent(content);
                        break;
                      case 'publish':
                        _updateContentStatus(content.id, ContentStatus.published, content.displayTitle);
                        break;
                      case 'approve':
                        _updateContentStatus(content.id, ContentStatus.approved, content.displayTitle);
                        break;
                      case 'reject':
                        _updateContentStatus(content.id, ContentStatus.rejected, content.displayTitle);
                        break;
                      case 'delete':
                        _deleteContent(content.id, content.displayTitle);
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content preview
            Text(
              content.displayTitle,
              style: AdminTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            Text(
              content.contentPreview,
              style: AdminTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Metadata row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created ${DateFormat('MMM dd, yyyy').format(content.createdAt)}',
                  style: AdminTheme.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                
                if (content.viewCount > 0) ...[
                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${content.viewCount} views',
                    style: AdminTheme.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const Spacer(),
                
                if (content.generationSource == 'sports_wiki')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Wiki Source',
                      style: AdminTheme.bodySmall.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.generated:
        return AdminTheme.warningColor;
      case ContentStatus.approved:
        return Colors.blue;
      case ContentStatus.published:
        return AdminTheme.successColor;
      case ContentStatus.rejected:
        return AdminTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has super admin privileges
    final authProvider = Provider.of<AdminAuthProvider>(context);
    if (!authProvider.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AdminTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is only available to super administrators.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'All Content', icon: Icon(Icons.list)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading content management...'),
                ],
              ),
            )
          : _error != null
              ? Center(
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
                        'Error loading content',
                        style: AdminTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AdminTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadContentData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    SingleChildScrollView(
                      child: _buildStatsOverview(),
                    ),
                    
                    // All Content Tab
                    _buildContentList(),
                    
                    // Analytics Tab
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats Cards
          _buildAnalyticsOverallStats(),
          
          const SizedBox(height: 24),
          
          // Performance Charts Row
          Row(
            children: [
              Expanded(child: _buildAnalyticsPerformanceBySport()),
              const SizedBox(width: 16),
              Expanded(child: _buildAnalyticsPerformanceByType()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top Performing Content
          _buildAnalyticsTopContent(),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildAnalyticsRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverallStats() {
    final totalContent = _analyticsStats['total_content'] ?? 0;
    final totalViews = _analyticsStats['total_views'] ?? 0;
    final totalLikes = _analyticsStats['total_likes'] ?? 0;
    final totalShares = _analyticsStats['total_shares'] ?? 0;
    final avgViews = _analyticsStats['average_views_per_content'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Overview',
          style: AdminTheme.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAnalyticsStatCard('Total Content', totalContent.toString(), Icons.article, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsStatCard('Total Views', _formatAnalyticsNumber(totalViews), Icons.visibility, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsStatCard('Total Likes', _formatAnalyticsNumber(totalLikes), Icons.favorite, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsStatCard('Total Shares', _formatAnalyticsNumber(totalShares), Icons.share, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAnalyticsStatCard('Avg Views/Content', avgViews.toStringAsFixed(1), Icons.trending_up, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsStatCard('Engagement Rate', '${_calculateAnalyticsEngagementRate()}%', Icons.analytics, Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: Container()), // Spacer
            const SizedBox(width: 12),
            Expanded(child: Container()), // Spacer
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPerformanceBySport() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance by Sport', style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._performanceBySport.entries.take(5).map((entry) {
            final maxValue = _performanceBySport.values.isNotEmpty ? _performanceBySport.values.reduce((a, b) => a > b ? a : b) : 1;
            final percentage = (entry.value / maxValue).clamp(0.0, 1.0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: TextStyle(fontSize: 12)),
                      Text(_formatAnalyticsNumber(entry.value), style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(_getAnalyticsSportColor(entry.key)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPerformanceByType() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance by Type', style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._performanceByType.entries.map((entry) {
            final maxValue = _performanceByType.values.isNotEmpty ? _performanceByType.values.reduce((a, b) => a > b ? a : b) : 1;
            final percentage = (entry.value / maxValue).clamp(0.0, 1.0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getAnalyticsContentTypeDisplayName(entry.key), style: TextStyle(fontSize: 12)),
                      Text(_formatAnalyticsNumber(entry.value), style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(_getAnalyticsTypeColor(entry.key)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTopContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Performing Content', style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topPerformingContent.take(5).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final content = _topPerformingContent[index];
              final title = _getAnalyticsContentTitleFromFeed(content);
              final engagementScore = content.viewCount + (content.likeCount * 2);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getAnalyticsTypeColor(content.type.toFirestore()),
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  title.length > 40 ? '${title.substring(0, 40)}...' : title,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text('${content.sportCategory} • ${_getAnalyticsContentTypeDisplayName(content.type.toFirestore())}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Score: $engagementScore', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${content.viewCount} views • ${content.likeCount} likes', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent User Activity', style: AdminTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentInteractions.take(10).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final interaction = _recentInteractions[index];
              final action = interaction['action'] as String;
              final contentTitle = interaction['content_title'] as String;
              final timestamp = interaction['timestamp'] as Timestamp;
              final sport = interaction['sport_category'] as String;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getAnalyticsActionColor(action),
                  child: Icon(_getAnalyticsActionIcon(action), color: Colors.white, size: 18),
                ),
                title: Text(
                  '${_getAnalyticsActionText(action)} "${contentTitle.length > 25 ? '${contentTitle.substring(0, 25)}...' : contentTitle}"',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text('$sport • ${_formatAnalyticsTimestamp(timestamp)}', style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        ],
      ),
    );
  }

  // Analytics helper methods
  String _formatAnalyticsNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _calculateAnalyticsEngagementRate() {
    final totalViews = _analyticsStats['total_views'] ?? 0;
    final totalLikes = _analyticsStats['total_likes'] ?? 0;
    final totalShares = _analyticsStats['total_shares'] ?? 0;
    
    if (totalViews == 0) return '0.0';
    return (((totalLikes + totalShares) / totalViews) * 100).toStringAsFixed(1);
  }

  Color _getAnalyticsSportColor(String sport) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    return colors[sport.hashCode % colors.length];
  }

  Color _getAnalyticsTypeColor(String type) {
    switch (type) {
      case 'parent_tip': return Colors.blue;
      case 'did_you_know': return Colors.green;
      case 'trivia': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getAnalyticsContentTypeDisplayName(String type) {
    switch (type) {
      case 'parent_tip': return 'Health Tips';
      case 'did_you_know': return 'Did You Know';
      case 'trivia': return 'Trivia';
      default: return type;
    }
  }

  String _getAnalyticsContentTitleFromFeed(ContentFeed content) {
    switch (content.type) {
      case ContentType.parentTip: return content.parentTipContent?.title ?? 'Untitled';
      case ContentType.didYouKnow: return content.didYouKnowContent?.fact ?? 'Did You Know';
      case ContentType.trivia: return content.triviaContent?.question ?? 'Trivia Question';
    }
  }

  Color _getAnalyticsActionColor(String action) {
    switch (action) {
      case 'view': return Colors.blue;
      case 'like': return Colors.red;
      case 'share': return Colors.green;
      case 'bookmark': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getAnalyticsActionIcon(String action) {
    switch (action) {
      case 'view': return Icons.visibility;
      case 'like': return Icons.favorite;
      case 'share': return Icons.share;
      case 'bookmark': return Icons.bookmark;
      default: return Icons.help;
    }
  }

  String _getAnalyticsActionText(String action) {
    switch (action) {
      case 'view': return 'Viewed';
      case 'like': return 'Liked';
      case 'share': return 'Shared';
      case 'bookmark': return 'Bookmarked';
      default: return action;
    }
  }

  String _formatAnalyticsTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
