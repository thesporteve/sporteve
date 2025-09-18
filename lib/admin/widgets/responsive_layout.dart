import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import '../theme/admin_theme.dart';

class ResponsiveLayout extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<AdminNavigationItem> navigationItems;
  final List<Widget>? appBarActions;

  const ResponsiveLayout({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.navigationItems,
    this.appBarActions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 24),
            const SizedBox(width: 12),
            const Text('SportEve Admin v1.2 - Fixed Layout'),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                navigationItems[selectedIndex].label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: appBarActions,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // Navigation Rail - Wider for web
          Container(
            width: 280, // Fixed width instead of constraints for better web layout
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onItemTapped,
                labelType: NavigationRailLabelType.none,
                minWidth: 80,
                minExtendedWidth: 280,
                extended: true,
                backgroundColor: Colors.transparent,
                leading: const SizedBox(height: 20),
                destinations: navigationItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon, size: 22),
                        selectedIcon: Icon(item.selectedIcon, size: 22),
                        label: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: navigationItems[selectedIndex].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'SportEve Admin',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: appBarActions,
      ),
      body: navigationItems[selectedIndex].screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: navigationItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon, size: 20),
                activeIcon: Icon(item.selectedIcon, size: 20),
                label: item.label.length > 10 
                    ? '${item.label.substring(0, 10)}...' 
                    : item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
