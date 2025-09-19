import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_feed.dart';
import '../services/admin_content_service.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import 'package:intl/intl.dart';

class AdminContentReviewScreen extends StatefulWidget {
  const AdminContentReviewScreen({super.key});

  @override
  State<AdminContentReviewScreen> createState() => _AdminContentReviewScreenState();
}

class _AdminContentReviewScreenState extends State<AdminContentReviewScreen> {
  final AdminContentService _contentService = AdminContentService.instance;
  
  List<ContentFeed> _pendingContent = [];
  List<ContentFeed> _filteredContent = [];
  Set<String> _selectedItems = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedContentType = 'All';
  String _selectedSport = 'All';

  final List<String> _contentTypes = ['All', 'Trivia', 'Parent Tip', 'Did You Know'];

  @override
  void initState() {
    super.initState();
    _loadPendingContent();
  }

  Future<void> _loadPendingContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pendingContent = await _contentService.getPendingContentForReview();
      
      setState(() {
        _pendingContent = pendingContent;
        _filteredContent = pendingContent;
        _isLoading = false;
        _selectedItems.clear();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pending content: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterContent() {
    setState(() {
      _filteredContent = _pendingContent.where((content) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            content.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            content.contentPreview.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            content.sportCategory.toLowerCase().contains(_searchQuery.toLowerCase());

        // Content type filter
        final matchesType = _selectedContentType == 'All' ||
            (_selectedContentType == 'Trivia' && content.type == ContentType.trivia) ||
            (_selectedContentType == 'Parent Tip' && content.type == ContentType.parentTip) ||
            (_selectedContentType == 'Did You Know' && content.type == ContentType.didYouKnow);

        // Sport filter
        final matchesSport = _selectedSport == 'All' ||
            content.sportCategory.toLowerCase() == _selectedSport.toLowerCase();

        return matchesSearch && matchesType && matchesSport;
      }).toList();
    });
  }

  Future<void> _approveContent(String id, String title) async {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    try {
      await _contentService.approveContentFeed(id, authProvider.currentAdmin ?? 'unknown');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved: "$title"'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
      
      _loadPendingContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectContent(String id, String title) async {
    try {
      await _contentService.rejectContentFeed(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected: "$title"'),
            backgroundColor: AdminTheme.warningColor,
          ),
        );
      }
      
      _loadPendingContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _bulkApprove() async {
    if (_selectedItems.isEmpty) return;

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    try {
      await _contentService.bulkApproveContentFeeds(
        _selectedItems.toList(),
        authProvider.currentAdmin ?? 'unknown',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved ${_selectedItems.length} items'),
            backgroundColor: AdminTheme.successColor,
          ),
        );
      }
      
      _loadPendingContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk approval failed: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _bulkReject() async {
    if (_selectedItems.isEmpty) return;

    try {
      // Note: AdminContentService doesn't have bulkRejectContentFeeds method
      // We'll need to reject them individually
      for (final id in _selectedItems) {
        await _contentService.rejectContentFeed(id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected ${_selectedItems.length} items'),
            backgroundColor: AdminTheme.warningColor,
          ),
        );
      }
      
      _loadPendingContent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk rejection failed: $e'),
            backgroundColor: AdminTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showContentDetails(ContentFeed content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(content.type.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content.type.displayName,
                style: AdminTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentPreview(content),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectContent(content.id, content.displayTitle);
            },
            style: TextButton.styleFrom(foregroundColor: AdminTheme.errorColor),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _approveContent(content.id, content.displayTitle);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.successColor),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(ContentFeed content) {
    switch (content.type) {
      case ContentType.trivia:
        final trivia = content.triviaContent!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question:', style: AdminTheme.titleSmall),
            Text(trivia.question, style: AdminTheme.bodyMedium),
            const SizedBox(height: 12),
            
            Text('Options:', style: AdminTheme.titleSmall),
            ...trivia.options.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                children: [
                  Text('${String.fromCharCode(65 + entry.key)})', 
                       style: AdminTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.value, style: AdminTheme.bodyMedium)),
                  if (entry.value == trivia.correctAnswer)
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            )),
            const SizedBox(height: 12),
            
            Text('Explanation:', style: AdminTheme.titleSmall),
            Text(trivia.explanation, style: AdminTheme.bodyMedium),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Difficulty: ${trivia.difficulty.displayName}',
                style: AdminTheme.bodySmall,
              ),
            ),
          ],
        );

      case ContentType.parentTip:
        final tip = content.parentTipContent!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title:', style: AdminTheme.titleSmall),
            Text(tip.title, style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Text('Benefits:', style: AdminTheme.titleSmall),
            ...tip.benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(benefit, style: AdminTheme.bodyMedium)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            
            Text('Content:', style: AdminTheme.titleSmall),
            Text(tip.content, style: AdminTheme.bodyMedium),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Age Group: ${tip.ageGroup}',
                style: AdminTheme.bodySmall,
              ),
            ),
          ],
        );

      case ContentType.didYouKnow:
        final fact = content.didYouKnowContent!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fact:', style: AdminTheme.titleSmall),
            Text(fact.fact, style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Text('Details:', style: AdminTheme.titleSmall),
            Text(fact.details, style: AdminTheme.bodyMedium),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Category: ${fact.category}',
                style: AdminTheme.bodySmall,
              ),
            ),
          ],
        );
    }
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
              hintText: 'Search content to review...',
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
          
          // Filters and actions
          Row(
            children: [
              // Content type filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentType,
                  decoration: const InputDecoration(
                    labelText: 'Content Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _contentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContentType = value!;
                    });
                    _filterContent();
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Selection counter and bulk actions
              if (_selectedItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    '${_selectedItems.length} selected',
                    style: AdminTheme.bodyMedium.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                ElevatedButton.icon(
                  onPressed: _bulkApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                
                OutlinedButton.icon(
                  onPressed: _bulkReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.errorColor,
                    side: BorderSide(color: AdminTheme.errorColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _loadPendingContent,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(ContentFeed content) {
    final isSelected = _selectedItems.contains(content.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AdminTheme.primaryColor, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showContentDetails(content),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Selection checkbox
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.add(content.id);
                          } else {
                            _selectedItems.remove(content.id);
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    
                    // Content type icon and sport
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
                    
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _approveContent(content.id, content.displayTitle),
                          icon: const Icon(Icons.check_circle),
                          color: AdminTheme.successColor,
                          tooltip: 'Approve',
                        ),
                        IconButton(
                          onPressed: () => _rejectContent(content.id, content.displayTitle),
                          icon: const Icon(Icons.cancel),
                          color: AdminTheme.errorColor,
                          tooltip: 'Reject',
                        ),
                      ],
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
                const SizedBox(height: 8),
                
                // Metadata
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Generated ${DateFormat('MMM dd, HH:mm').format(content.createdAt)}',
                      style: AdminTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (content.generationSource == 'sports_wiki')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Wiki',
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
        ),
      ),
    );
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

    // Check if we need mobile AppBar (when accessed via navigation)
    final screenWidth = MediaQuery.of(context).size.width;
    final needsAppBar = screenWidth < 600;

    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      appBar: needsAppBar ? AppBar(
        title: const Text('Review Content'),
        backgroundColor: AdminTheme.primaryColor,
        foregroundColor: Colors.white,
      ) : null,
      body: Column(
        children: [
          _buildFiltersBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading content for review...'),
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
                              onPressed: _loadPendingContent,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredContent.isEmpty
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
                                  _pendingContent.isEmpty 
                                      ? 'No content pending review'
                                      : 'No content matches your search',
                                  style: AdminTheme.titleLarge.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _pendingContent.isEmpty
                                      ? 'Generate some content to get started'
                                      : 'Try adjusting your search or filters',
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
      ),
    );
  }
}
