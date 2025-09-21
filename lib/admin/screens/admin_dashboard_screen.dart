import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/responsive_layout.dart';
import '../theme/admin_theme.dart';
import 'admin_news_screen.dart';
import 'admin_tournaments_screen.dart';
import 'admin_athletes_screen.dart';
import 'admin_sports_wiki_screen.dart';
import 'admin_content_generation_screen.dart';
import 'admin_content_review_screen.dart';
import 'admin_content_management_screen.dart';
import 'admin_management_screen.dart';
import 'admin_more_screen.dart';
import 'admin_feedback_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  List<AdminNavigationItem> _getNavigationItems(AdminAuthProvider authProvider) {
    return [
      AdminNavigationItem(
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        label: 'News Articles',
        screen: const AdminNewsScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        label: 'Tournaments',
        screen: const AdminTournamentsScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.sports_outlined,
        selectedIcon: Icons.sports,
        label: 'Athletes',
        screen: const AdminAthletesScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books,
        label: 'Sports Wiki',
        screen: const AdminSportsWikiScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.feedback_outlined,
        selectedIcon: Icons.feedback,
        label: 'User Feedback',
        screen: const AdminFeedbackScreen(),
      ),
      // Only show AI content features for super admins
      if (authProvider.isSuperAdmin) ...[
        AdminNavigationItem(
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome,
          label: 'AI Content',
          screen: const AdminContentGenerationScreen(),
        ),
        AdminNavigationItem(
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review,
          label: 'Review Content',
          screen: const AdminContentReviewScreen(),
        ),
        AdminNavigationItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Content Hub',
          screen: const AdminContentManagementScreen(),
        ),
        AdminNavigationItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: 'Admin Management',
          screen: const AdminManagementScreen(),
        ),
      ],
    ];
  }

  // Get mobile-friendly navigation items (max 5 for BottomNavigationBar)
  List<AdminNavigationItem> _getMobileNavigationItems(AdminAuthProvider authProvider) {
    final baseItems = [
      AdminNavigationItem(
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        label: 'News',
        screen: const AdminNewsScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        label: 'Events',
        screen: const AdminTournamentsScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.sports_outlined,
        selectedIcon: Icons.sports,
        label: 'Athletes',
        screen: const AdminAthletesScreen(),
      ),
      AdminNavigationItem(
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books,
        label: 'Wiki',
        screen: const AdminSportsWikiScreen(),
      ),
    ];

    // For super admins, add a combined AI/Admin item that leads to a submenu
    if (authProvider.isSuperAdmin) {
      baseItems.add(
        AdminNavigationItem(
          icon: Icons.more_horiz_outlined,
          selectedIcon: Icons.more_horiz,
          label: 'More',
          screen: const AdminMoreScreen(),
        ),
      );
    }

    return baseItems;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    
    final navigationItems = isMobile 
        ? _getMobileNavigationItems(authProvider)
        : _getNavigationItems(authProvider);
    
    return ResponsiveLayout(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      navigationItems: navigationItems,
      appBarActions: [
        // Admin info and logout
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AdminTheme.secondaryColor,
            child: Text(
              authProvider.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.displayName,
                    style: AdminTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    authProvider.currentAdmin ?? '',
                    style: AdminTheme.caption,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog(context, authProvider);
            }
          },
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AdminAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class AdminNavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const AdminNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}
