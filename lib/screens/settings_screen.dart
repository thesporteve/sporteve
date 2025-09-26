import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_provider.dart';
import 'feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    // Ensure settings are loaded when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      // Fallback to default version if package info fails
      setState(() {
        _appVersion = '1.0.0';
      });
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
            Expanded(
              child: Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  if (!settings.isLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Appearance'),
                        _buildThemeSection(settings),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('News Preferences'),
                        _buildSportsPreferencesSection(settings),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('Bookmarks'),
                        _buildBookmarksSection(),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('Feedback'),
                        _buildFeedbackSection(),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('About'),
                        _buildAboutSection(),
                      ],
                    ),
                  );
                },
              ),
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
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onPressed: () => context.go('/home'),
          ),
          Expanded(
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSection(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  title: 'Light',
                  icon: Icons.light_mode,
                  isSelected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.updateThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  title: 'Dark',
                  icon: Icons.dark_mode,
                  isSelected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.updateThemeMode(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  title: 'System',
                  icon: Icons.auto_mode,
                  isSelected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.updateThemeMode(ThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsPreferencesSection(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Preferred Sports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (settings.selectedSports.isNotEmpty)
                TextButton(
                  onPressed: settings.clearSportsPreferences,
                  child: Text(
                    'Show All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            settings.showAllSports
                ? 'Currently showing news from all sports. Select specific sports to filter your news feed.'
                : 'Showing news from ${settings.selectedSports.length} selected sports.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          _buildSportsGrid(settings),
        ],
      ),
    );
  }

  Widget _buildSportsGrid(SettingsProvider settings) {
    final sportsWithNames = SettingsProvider.getAvailableSportsWithNames();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sportsWithNames.map((entry) {
        final sportKey = entry.key;
        final sportName = entry.value;
        final isSelected = settings.selectedSports.contains(sportKey);
        
        return InkWell(
          onTap: () => settings.toggleSport(sportKey),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.6),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              sportName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildBookmarksSection() {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.bookmark_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Saved Articles'),
        subtitle: const Text('View your bookmarked articles'),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: () {
          context.push('/bookmarks');
        },
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          // App Information
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('SportEve'),
            subtitle: Text('Your Daily Sports Pulse\nVersion $_appVersion'),
            isThreeLine: true,
          ),
          const Divider(height: 1),
          
          // Contact Us - Required for Play Store compliance
          ListTile(
            leading: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Contact Us'),
            subtitle: const Text('thesporteve@gmail.com'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: () => _launchEmail(),
          ),
          
          // Debug button only visible in debug builds
          if (kDebugMode) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Debug Info'),
              subtitle: const Text('Development tools & diagnostics'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onTap: () => context.go('/debug'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'thesporteve@gmail.com',
      query: 'subject=SportEve App - Support Request',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: Show email address in a dialog if email client is not available
        if (mounted) {
          _showEmailDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showEmailDialog();
      }
    }
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Us'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send us an email at:'),
              const SizedBox(height: 8),
              SelectableText(
                'thesporteve@gmail.com',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.feedback,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Share Feedback'),
            subtitle: const Text('Help us improve SportEve'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
          ),
          // Rate Our App - Hidden until Play Store release
          // const Divider(height: 1),
          // ListTile(
          //   leading: Icon(
          //     Icons.rate_review,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          //   title: const Text('Rate Our App'),
          //   subtitle: const Text('Love SportEve? Rate us on Play Store!'),
          //   trailing: Icon(
          //     Icons.arrow_forward_ios,
          //     size: 16,
          //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          //   ),
          //   onTap: () {
          //     // TODO: Implement app store rating when published
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Opening Play Store...'),
          //         duration: Duration(seconds: 2),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
