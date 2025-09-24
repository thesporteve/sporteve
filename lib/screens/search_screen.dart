import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/news_provider.dart';
import '../providers/settings_provider.dart';
import '../models/news_article.dart';
import '../widgets/news_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<NewsArticle> _searchResults = [];
  List<NewsArticle> _filteredResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  // Enhanced search features
  List<String> _recentSearches = [];
  List<String> _searchSuggestions = [];
  String _selectedCategory = 'All';
  DateTime? _searchStartTime;
  bool _showSuggestions = false;
  
  // Categories for filtering - dynamically loaded from supported sports
  List<String> _categories = ['All'];
  
  
  // Smart suggestions based on category
  final Map<String, List<String>> _categorySuggestions = {
    'Basketball': ['NBA', 'NCAA', 'playoffs', 'draft', 'MVP', 'trade'],
    'Football': ['NFL', 'draft', 'playoffs', 'Super Bowl', 'trade', 'injury'],
    'Soccer': ['Premier League', 'Champions League', 'World Cup', 'transfer', 'goal'],
    'Tennis': ['Wimbledon', 'US Open', 'Australian Open', 'French Open', 'ranking'],
    'Baseball': ['MLB', 'World Series', 'trade deadline', 'draft', 'home run'],
  };
  
  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
    _loadRecentSearches();
    _loadSupportedSports();
    // Delay auto-focus slightly to prevent keyboard overlap issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    });
  }
  
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('recent_searches') ?? [];
      setState(() {
        _recentSearches = recent.take(5).toList(); // Keep last 5 searches
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }
  
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recent = List.from(_recentSearches);
      
      // Remove if already exists
      recent.remove(query);
      // Add to beginning
      recent.insert(0, query);
      // Keep only last 10
      recent = recent.take(10).toList();
      
      await prefs.setStringList('recent_searches', recent);
      setState(() {
        _recentSearches = recent.take(5).toList();
      });
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }
  
  void _generateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();
    
    // Add category-specific suggestions
    for (final category in _categorySuggestions.keys) {
      final categorySugs = _categorySuggestions[category] ?? [];
      suggestions.addAll(
        categorySugs.where((sug) => sug.toLowerCase().contains(lowerQuery))
      );
    }
    
    
    // Add recent searches that match
    suggestions.addAll(
      _recentSearches.where((recent) => recent.toLowerCase().contains(lowerQuery))
    );
    
    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Dismiss keyboard before disposing
    _searchFocusNode.unfocus();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query, {bool saveToHistory = true}) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
        _isSearching = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _searchStartTime = DateTime.now();
    });

    try {
      // Save to recent searches
      if (saveToHistory) {
        await _saveRecentSearch(query);
      }
      
      // Use NewsProvider's cached articles for faster search
      final newsProvider = context.read<NewsProvider>();
      
      // If we don't have cached articles, load them first
      if (newsProvider.articles.isEmpty) {
        await newsProvider.loadNews();
      }
      
      // Enhanced search through cached articles
      final results = newsProvider.articles.where((article) =>
          article.title.toLowerCase().contains(query.toLowerCase()) ||
          article.summary.toLowerCase().contains(query.toLowerCase()) ||
          article.content.toLowerCase().contains(query.toLowerCase()) ||
          article.category.toLowerCase().contains(query.toLowerCase()) ||
          article.category.toLowerCase().contains(query.toLowerCase())).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _filteredResults = _applyFilters(results);
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _filteredResults = [];
          _isSearching = false;
        });
      }
    }
  }
  
  List<NewsArticle> _applyFilters(List<NewsArticle> results) {
    if (_selectedCategory == 'All') {
      return results;
    }
    
    return results.where((article) =>
        article.category.toLowerCase() == _selectedCategory.toLowerCase() ||
        article.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }
  
  void _selectCategory(String category) {
    // Clear search text when category is selected to hide chips below search bar
    _searchController.clear();
    _searchFocusNode.unfocus();
    
    setState(() {
      _selectedCategory = category;
      _showSuggestions = false;
    });
    
    // If not "All", perform a search for articles in that category
    if (category != 'All') {
      _performSearchByCategory(category);
    } else {
      // Clear results when "All" is selected
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
    }
  }

  void _onSearchChanged(String value) {
    // Cancel the previous timer
    _debounceTimer?.cancel();
    
    // Generate suggestions immediately
    _generateSearchSuggestions(value);
    
    // Start a new timer for search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        _performSearch(value);
      }
    });
    
    // Update UI immediately to show/hide clear button
    setState(() {});
  }
  
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
    _searchFocusNode.unfocus();
  }

  Future<void> _performSearchByCategory(String category) async {
    setState(() {
      _isSearching = true;
      _searchStartTime = DateTime.now();
    });

    try {
      // Use NewsProvider's cached articles for faster search
      final newsProvider = context.read<NewsProvider>();
      
      // If we don't have cached articles, load them first
      if (newsProvider.articles.isEmpty) {
        await newsProvider.loadNews();
      }
      
      // Filter by category only
      final results = newsProvider.articles.where((article) =>
          article.category.toLowerCase() == category.toLowerCase()).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _filteredResults = results; // No need to apply additional filters since we're already filtering by category
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _filteredResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _loadSupportedSports() {
    // Load supported sports from SettingsProvider
    final supportedSports = SettingsProvider.availableSports
        .map((sport) => SettingsProvider.getSportDisplayName(sport))
        .toList();
    supportedSports.sort(); // Sort alphabetically
    
    setState(() {
      _categories = ['All', ...supportedSports];
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // Ensure keyboard is dismissed when navigating back
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        // Dismiss keyboard when tapping outside
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside search field
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // App Bar with Search
                _buildSearchAppBar(),
                
                // Category Filters (only show when searching)
                if (_searchController.text.isNotEmpty && !_showSuggestions)
                  _buildCategoryFilters(),
                
                // Search Results
                Expanded(
                  child: _buildSearchResults(),
                ),
              ],
            ),
            
            // Search Suggestions Overlay
            if (_showSuggestions)
              _buildSuggestionsOverlay(),
          ],
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildSearchAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Clear search before going back
                  context.read<NewsProvider>().clearSearch();
                  context.pop();
                },
              ),
              Text(
                'Search',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search sports news...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _selectCategory(category),
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
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 120, // Below search bar
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _searchSuggestions.length,
          separatorBuilder: (context, index) => Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final suggestion = _searchSuggestions[index];
            return ListTile(
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              title: Text(
                suggestion,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              onTap: () => _selectSuggestion(suggestion),
              dense: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (_filteredResults.isEmpty) {
      return _buildNoResultsState();
    }

    final searchTime = _searchStartTime != null 
        ? DateTime.now().difference(_searchStartTime!).inMilliseconds / 1000
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count and search time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_filteredResults.length} results found in ${searchTime.toStringAsFixed(2)}s',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredResults.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewsCard(
                  article: _filteredResults[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 60,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover Sports News',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find articles, match updates, and breaking news',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Browse by Sport section hidden for simplified search experience
          // const SizedBox(height: 32),
          
          
          // Recent Searches (if any)
          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _recentSearches.map((recent) => ListTile(
                leading: Icon(Icons.history, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
                title: Text(
                  recent,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 16),
                onTap: () => _selectSuggestion(recent),
                dense: true,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No articles found for "${_searchController.text}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Search suggestions hidden for simplified search experience
            // Column(...)
            
            const SizedBox(height: 16),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Tips:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check your spelling\n• Try different keywords\n• Use broader terms\n• Remove filters if applied',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
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
}
