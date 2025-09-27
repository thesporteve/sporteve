import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/news_provider.dart';
import '../providers/settings_provider.dart';
import '../models/news_article.dart';
import '../models/user.dart';
import '../widgets/news_page_card.dart';
import '../widgets/daily_tip_banner.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentPage = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState called');
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🏠 PostFrameCallback - calling NewsProvider.loadNews()');
      context.read<NewsProvider>().loadNews();
    });
  }

  Future<void> _loadUserData() async {
    if (_authService.isSignedIn) {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    }
  }



  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 HomeScreen build method called');
    return PopScope(
      // Only allow app to close if we're at the top (first article)
      canPop: _currentPage == 0,
      onPopInvoked: (didPop) async {
        if (!didPop && _currentPage > 0) {
          // User pressed back while scrolled down - scroll to top and refresh
          print('🔄 Back pressed while scrolled down - going to top and refreshing');
          
          // Animate back to top smoothly
          await _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // Trigger non-blocking refresh for fresh content
          if (mounted) {
            context.read<NewsProvider>().refreshInBackground();
          }
        }
        // If didPop is true or _currentPage == 0, normal back behavior happens (app backgrounds)
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Consumer2<NewsProvider, SettingsProvider>(
          builder: (context, newsProvider, settingsProvider, child) {
            print('🏠 HomeScreen Consumer builder - isLoading: ${newsProvider.isLoading}, error: ${newsProvider.error}');
            if (newsProvider.isLoading) {
              print('🏠 Showing loading indicator');
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              );
            }

            if (newsProvider.error != null) {
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsProvider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Use refresh() method which calls loadNews with forceRefresh: true
                        newsProvider.refresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Apply sports filtering based on user preferences
            final articles = newsProvider.filteredArticles.where((article) {
              // If settings aren't loaded yet, show all articles
              if (!settingsProvider.isLoaded) return true;
              
              // If no sports preferences selected, show all articles
              if (settingsProvider.showAllSports) return true;
              
              // Filter by selected sports
              return settingsProvider.shouldShowSport(article.category);
            }).toList();
            if (articles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No articles found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsProvider.selectedTournamentId != null
                          ? 'No articles available for this tournament'
                          : !settingsProvider.showAllSports
                              ? 'No news found for your selected sports'
                              : 'No articles available right now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Action buttons based on the type of empty state
                    if (newsProvider.selectedTournamentId != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          newsProvider.clearTournamentFilter();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('All News'),
                      )
                    else if (!settingsProvider.showAllSports)
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/settings');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Adjust Sports Preferences'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              settingsProvider.clearSportsPreferences();
                            },
                            child: Text(
                              'Show all sports news',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () async {
                          await newsProvider.loadNews(forceRefresh: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Non-blocking Refresh Status Bar (Option A - Top indicator)
                if (newsProvider.isRefreshing) 
                  _buildRefreshStatusBar(),
                
                // Tournament Filter Chips (always show if filter is active OR tournaments exist)
                if (newsProvider.selectedTournamentId != null || newsProvider.liveTournaments.isNotEmpty)
                  _buildTournamentFilterChips(context, newsProvider, settingsProvider),
                
                // Daily Tip Banner
                const DailyTipBanner(),
                
                // News Pages (Vertical PageView)
                Expanded(
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          // Add haptic feedback for better UX
                          HapticFeedback.lightImpact();
                          // Use non-blocking background refresh - user can keep reading
                          await newsProvider.refreshInBackground();
                        },
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        strokeWidth: 3,
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                            // Preload adjacent images for faster loading
                            _preloadAdjacentImages(articles, index);
                          },
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            return NewsPageCard(article: articles[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Navigation
                _buildBottomNavigation(),
              ],
            );
          },
        ),
      ),
      ), // Close PopScope
    );
  }

  /// Non-intrusive top status bar for background refresh
  Widget _buildRefreshStatusBar() {
    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Updating feed...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentFilterChips(BuildContext context, NewsProvider newsProvider, SettingsProvider settingsProvider) {
    // Filter tournaments based on user's sports preferences
    final filteredTournaments = newsProvider.liveTournaments.where((tournament) {
      // If settings aren't loaded, show all tournaments
      if (!settingsProvider.isLoaded) return true;
      
      // If no sports preferences selected, show all tournaments  
      if (settingsProvider.showAllSports) return true;
      
      // Show tournaments that match user's selected sports
      // Handle 'all' sportType for multi-sport tournaments
      if (tournament.sportType.toLowerCase() == 'all') return true;
      
      return settingsProvider.shouldShowSport(tournament.sportType);
    }).toList();
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredTournaments.length + 1, // +1 for "All" chip
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip to clear filter
            final isSelected = newsProvider.selectedTournamentId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  'All',
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!isSelected) {
                    newsProvider.clearTournamentFilter();
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }
          
          // Check if we have tournaments before accessing the array
          if (index - 1 >= filteredTournaments.length) {
            return const SizedBox.shrink();
          }
          
          final tournament = filteredTournaments[index - 1];
          final isSelected = newsProvider.selectedTournamentId == tournament.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tournament.name,
                style: TextStyle(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  newsProvider.setTournamentFilter(tournament.id);
                } else {
                  newsProvider.clearTournamentFilter();
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.newspaper, 'News', true, _onNewsTabPressed),
          _buildNavItem(Icons.search, 'Search', false, () {
            context.push('/search');
          }),
          _buildNavItem(Icons.lightbulb_outlined, 'Tips & Facts', false, () {
            context.push('/tips-facts');
          }),
          _buildNavItem(Icons.settings, 'Settings', false, () {
            context.push('/settings');
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle News tab press - scroll to top and refresh (similar to back button behavior)
  Future<void> _onNewsTabPressed() async {
    if (_currentPage > 0) {
      // User is scrolled down - animate to top and refresh
      print('🔄 News tab pressed while scrolled down - going to top and refreshing');
      
      // Animate back to top smoothly
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
      
      // Trigger non-blocking refresh for fresh content
      if (mounted) {
        context.read<NewsProvider>().refreshInBackground();
      }
    } else {
      // User is already at top - just refresh
      print('🔄 News tab pressed at top - refreshing');
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      // Trigger refresh
      if (mounted) {
        context.read<NewsProvider>().refreshInBackground();
      }
    }
  }

  /// Preload images for adjacent articles to improve loading speed
  void _preloadAdjacentImages(List<NewsArticle> articles, int currentIndex) {
    // Preload next image (prioritize next since users swipe up)
    if (currentIndex + 1 < articles.length) {
      final nextArticle = articles[currentIndex + 1];
      if (nextArticle.imageUrl != null && nextArticle.imageUrl!.isNotEmpty) {
        try {
          precacheImage(CachedNetworkImageProvider(nextArticle.imageUrl!), context);
        } catch (e) {
          print('Error preloading next image: $e');
        }
      }
    }
    
    // Preload previous image (lower priority)
    if (currentIndex - 1 >= 0) {
      final prevArticle = articles[currentIndex - 1];
      if (prevArticle.imageUrl != null && prevArticle.imageUrl!.isNotEmpty) {
        try {
          precacheImage(CachedNetworkImageProvider(prevArticle.imageUrl!), context);
        } catch (e) {
          print('Error preloading previous image: $e');
        }
      }
    }
  }

}
