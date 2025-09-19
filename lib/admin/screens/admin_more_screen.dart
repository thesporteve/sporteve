import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import 'admin_content_generation_screen.dart';
import 'admin_content_review_screen.dart';
import 'admin_content_management_screen.dart';
import 'admin_management_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    
    // Check if user has super admin privileges
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Advanced features for super administrators',
              style: AdminTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, // Adjusted to prevent overflow
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI Content',
                    description: 'Generate trivia, tips & facts',
                    color: Colors.blue,
                    onTap: () => _navigateToScreen(context, const AdminContentGenerationScreen()),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.rate_review,
                    title: 'Review Content',
                    description: 'Review & approve AI content',
                    color: Colors.orange,
                    onTap: () => _navigateToScreen(context, const AdminContentReviewScreen()),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.dashboard,
                    title: 'Content Hub',
                    description: 'Manage all content feeds',
                    color: Colors.green,
                    onTap: () => _navigateToScreen(context, const AdminContentManagementScreen()),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Management',
                    description: 'Manage admin users',
                    color: Colors.purple,
                    onTap: () => _navigateToScreen(context, const AdminManagementScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
