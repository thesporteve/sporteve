import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_feed.dart';
import '../providers/content_provider.dart';
import '../widgets/content_card.dart';
import '../services/content_feed_service.dart';
import '../services/content_analytics_service.dart';

class TipsFactsScreen extends StatefulWidget {
  final String? highlightId;
  
  const TipsFactsScreen({super.key, this.highlightId});

  @override
  State<TipsFactsScreen> createState() => _TipsFactsScreenState();
}

class _TipsFactsScreenState extends State<TipsFactsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Dynamic state variables
  bool _isLoading = false;
  List<ContentFeed> _allContent = [];
  List<ContentFeed> _parentTips = [];
  List<ContentFeed> _didYouKnows = [];
  List<ContentFeed> _filteredContent = [];
  Set<String> _readIds = {};
  String _selectedSport = 'All';
  List<String> _availableSports = []; // Dynamic list based on content

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize content and handle highlighting
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadContent();
      await _loadUserPreferences();
      
      // Highlight specific content if provided - wait for content to load first
      if (widget.highlightId != null) {
        _scrollToContent(widget.highlightId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      
      print('📥 Loading Tips & Facts content...');
      final content = await ContentFeedService.instance.getPublishedContentFeeds();
      final parentTips = content.where((c) => c.type == ContentType.parentTip).toList();
      final didYouKnows = content.where((c) => c.type == ContentType.didYouKnow).toList();
      
      print('✅ Loaded ${content.length} total content items');
      print('👨‍👩‍👧‍👦 Parent Tips: ${parentTips.length}');
      print('💡 Did You Know: ${didYouKnows.length}');
      
      // Generate dynamic sport categories from actual content
      final Set<String> sportsSet = {};
      for (final item in content) {
        if (item.sportCategory.isNotEmpty) {
          sportsSet.add(item.sportCategory);
        }
      }
      
      final List<String> availableSports = ['All', ...sportsSet.toList()..sort()];
      print('🏈 Available sports: $availableSports');
      
      if (widget.highlightId != null) {
        final highlightContent = content.firstWhere(
          (c) => c.id == widget.highlightId,
          orElse: () => throw Exception('Highlight content not found'),
        );
        print('🎯 Found highlight content: ${highlightContent.id} (${highlightContent.type})');
      }
      
      setState(() {
        _allContent = content;
        _parentTips = parentTips;
        _didYouKnows = didYouKnows;
        _filteredContent = content;
        _availableSports = availableSports;
        _isLoading = false;
      });
      
      // Apply initial filters
      _filterContent();
    } catch (e) {
      print('❌ Error loading content: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_content') ?? [];
      
      setState(() {
        _readIds = readIds.toSet();
      });
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  void _filterContent() {
    List<ContentFeed> filtered = _allContent;
    
    // Filter by sport category only
    if (_selectedSport != 'All') {
      filtered = filtered.where((content) => 
        content.sportCategory.toLowerCase() == _selectedSport.toLowerCase()
      ).toList();
    }
    
    // Update parent tips and did you knows lists with filtered content
    final filteredParentTips = filtered.where((c) => c.type == ContentType.parentTip).toList();
    final filteredDidYouKnows = filtered.where((c) => c.type == ContentType.didYouKnow).toList();
    
    setState(() {
      _filteredContent = filtered;
      _parentTips = filteredParentTips;
      _didYouKnows = filteredDidYouKnows;
    });
  }

  void _scrollToContent(String contentId) {
    // Find content and switch to appropriate tab
    try {
      final content = _allContent.firstWhere(
        (c) => c.id == contentId,
        orElse: () => throw Exception('Content not found'),
      );
      
      print('🎯 Scrolling to content: ${content.id}, type: ${content.type}');
      
      // Switch to correct tab (now 0-based with only 2 tabs)
      if (content.type == ContentType.parentTip) {
        _tabController.animateTo(0); // Parenting tab
        print('📱 Switched to Parenting tab');
      } else if (content.type == ContentType.didYouKnow) {
        _tabController.animateTo(1); // Did You Know tab
        print('📱 Switched to Did You Know tab');
      }
      
      // Update state to ensure the content is visible
      setState(() {
        _filterContent();
      });
      
    } catch (e) {
      print('❌ Error scrolling to content $contentId: $e');
    }
  }


  Future<void> _markAsRead(String contentId) async {
    if (_readIds.contains(contentId)) {
      print('📖 Content $contentId already marked as read');
      return;
    }
    
    try {
      print('📖 Marking content as read: $contentId');
      final prefs = await SharedPreferences.getInstance();
      List<String> read = List.from(_readIds);
      read.add(contentId);
      
      await prefs.setStringList('read_content', read);
      
      setState(() {
        _readIds = read.toSet();
      });
      
      print('✅ Content marked as read. Total read: ${_readIds.length}');
      
      // Track analytics
      ContentAnalyticsService.instance.trackContentView(contentId, 
        _allContent.firstWhere((c) => c.id == contentId).type);
      
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSportFilters(),
            _buildTabBar(),
            Expanded(
              child: _buildTabBarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          Text(
            'Tips & Facts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredContent.length} items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilters() {
    // Only show sport filters if there are more than 2 items (All + 1 sport = 2)
    if (_availableSports.length <= 2) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Sport',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableSports.length,
              itemBuilder: (context, index) {
                final sport = _availableSports[index];
                final isSelected = sport == _selectedSport;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSport = sport);
                      _filterContent();
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        tabs: [
          Tab(text: 'Parenting (${_parentTips.length})'),
          Tab(text: 'Did You Know (${_didYouKnows.length})'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentList(_parentTips), // Already filtered in _filterContent()
        _buildContentList(_didYouKnows), // Already filtered in _filterContent()
      ],
    );
  }

  Widget _buildContentList(List<ContentFeed> content) {
    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No content found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _availableSports.length > 2 
                ? 'Try selecting a different sport filter'
                : 'Check back later for more content',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: content.length,
        itemBuilder: (context, index) {
          final item = content[index];
          final isHighlighted = item.id == widget.highlightId;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: isHighlighted ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ) : null,
            child: ContentCard(
              content: item,
              isRead: _readIds.contains(item.id),
              onMarkAsRead: () => _markAsRead(item.id),
            ),
          );
        },
      ),
    );
  }
}
