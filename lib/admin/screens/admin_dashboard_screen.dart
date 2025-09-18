import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/responsive_layout.dart';
import '../theme/admin_theme.dart';
import 'admin_news_screen.dart';
import 'admin_tournaments_screen.dart';
import 'admin_athletes_screen.dart';
import 'admin_management_screen.dart';

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
      // Only show admin management for super admins
      if (authProvider.isSuperAdmin)
        AdminNavigationItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: 'Admin Management',
          screen: const AdminManagementScreen(),
        ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final navigationItems = _getNavigationItems(authProvider);
    
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
