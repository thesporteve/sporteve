import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'providers/news_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/content_provider.dart';
import 'models/content_feed.dart';
import 'screens/home_screen.dart';
import 'screens/custom_splash_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tips_facts_screen.dart';
import 'screens/content_detail_screen.dart';
import 'screens/debug_screen.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/debug_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler - must be top level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done
  await Firebase.initializeApp();
  print('🔥 Background message received: ${message.messageId}');
  print('📩 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.instance.initialize();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Push Notifications
  await NotificationService.instance.initialize();
  
  runApp(const SportEveApp());
}

class SportEveApp extends StatelessWidget {
  const SportEveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: Consumer2<NewsProvider, SettingsProvider>(
        builder: (context, newsProvider, settingsProvider, child) {
          // Initialize settings on first run
          if (!settingsProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              settingsProvider.loadSettings();
            });
          }
          
          // Set up notification handling and check for pending navigation
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            NotificationService.instance.setNotificationTapCallback(() {
              print('📱 Notification tapped - refreshing news feed...');
              newsProvider.refresh();
              // Handle any pending navigation from notification tap
              _handlePendingNavigation(context);
            });
            
            // Check for pending navigation when app starts
            await _handlePendingNavigation(context);
          });
          
          return MaterialApp.router(
            title: 'SportEve',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.isLoaded ? settingsProvider.themeMode : ThemeMode.dark,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authService = AuthService();
    final isSignedIn = authService.isSignedIn;
    final currentLocation = state.matchedLocation;
    
    // Protected routes that require authentication
    final protectedRoutes = ['/profile'];
    final publicRoutes = ['/', '/home', '/signin', '/search', '/bookmarks', '/settings', '/debug'];
    
    // Check if current route is protected
    final isProtectedRoute = protectedRoutes.any((route) => 
        currentLocation.startsWith(route));
    
    // Check if current route is public (including news detail routes)
    final isPublicRoute = publicRoutes.contains(currentLocation) || 
                         currentLocation.startsWith('/news/');
    
    // If trying to access protected route without being signed in, redirect to signin
    if (!isSignedIn && isProtectedRoute) {
      return '/signin';
    }
    
    // If signed in and trying to access signin, redirect to home
    if (isSignedIn && currentLocation == '/signin') {
      return '/home';
    }
    
    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CustomSplashScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/tips-facts',
      builder: (context, state) {
        final highlightId = state.uri.queryParameters['highlight'];
        return TipsFactsScreen(highlightId: highlightId);
      },
    ),
    GoRoute(
      path: '/news/:id',
      builder: (context, state) {
        final newsId = state.pathParameters['id']!;
        return NewsDetailScreen(newsId: newsId);
      },
    ),
    GoRoute(
      path: '/content/:id',
      builder: (context, state) {
        final contentId = state.pathParameters['id']!;
        final content = state.extra as ContentFeed?;
        return ContentDetailScreen(contentId: contentId, content: content);
      },
    ),
    GoRoute(
      path: '/debug',
      builder: (context, state) => const DebugScreen(),
    ),
  ],
);

/// Handle pending navigation from notifications
Future<void> _handlePendingNavigation(BuildContext context) async {
  try {
    final navigationData = await NotificationService.instance.getPendingNavigationData();
    if (navigationData != null && navigationData.isNotEmpty) {
      print('📱 Processing pending navigation: $navigationData');
      DebugLogger.instance.logInfo('Navigation', 'Processing pending navigation: $navigationData');
      
      final screen = navigationData['screen'] as String?;
      
      if (screen == 'content_detail') {
        // Navigate to content detail screen
        final contentId = navigationData['content_id'] as String?;
        final contentType = navigationData['content_type'] as String?;
        
        if (contentId != null) {
          print('📱 Navigating to content detail: $contentId (type: $contentType)');
          DebugLogger.instance.logInfo('Navigation', 'Content detail navigation: ID=$contentId, type=$contentType');
          
          // Ensure providers are loaded before navigation
          Future.delayed(const Duration(milliseconds: 800), () async {
            if (context.mounted) {
              try {
                // Pre-load content provider to ensure content is available
                final contentProvider = Provider.of<ContentProvider>(context, listen: false);
                if (contentProvider.allContent.isEmpty) {
                  DebugLogger.instance.logInfo('Navigation', 'Loading content before navigation');
                  await contentProvider.loadContent();
                }
                
                DebugLogger.instance.logSuccess('Navigation', 'Navigating to /content/$contentId');
                context.push('/content/$contentId');
              } catch (e) {
                DebugLogger.instance.logError('Navigation', 'Failed to navigate to content: $e');
                print('❌ Navigation error: $e');
              }
            }
          });
        }
      } else if (screen == 'news_detail') {
        // Navigate to news detail screen
        final articleId = navigationData['article_id'] as String?;
        if (articleId != null) {
          print('📱 Navigating to news detail: $articleId');
          DebugLogger.instance.logInfo('Navigation', 'News detail navigation: $articleId');
          
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              DebugLogger.instance.logSuccess('Navigation', 'Navigating to /news/$articleId');
              context.push('/news/$articleId');
            }
          });
        }
      } else if (screen == 'tips_facts') {
        // Navigate to tips & facts with highlight
        final contentId = navigationData['content_id'] as String?;
        print('📱 Navigating to tips & facts with highlight: $contentId');
        DebugLogger.instance.logInfo('Navigation', 'Tips & Facts navigation with highlight: $contentId');
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            if (contentId != null) {
              DebugLogger.instance.logSuccess('Navigation', 'Navigating to /tips-facts?highlight=$contentId');
              context.push('/tips-facts?highlight=$contentId');
            } else {
              DebugLogger.instance.logSuccess('Navigation', 'Navigating to /tips-facts');
              context.push('/tips-facts');
            }
          }
        });
      } else {
        print('❓ Unknown navigation screen: $screen');
        DebugLogger.instance.logWarning('Navigation', 'Unknown navigation screen: $screen');
      }
    } else {
      DebugLogger.instance.logInfo('Navigation', 'No pending navigation data');
    }
  } catch (e) {
    print('❌ Error handling pending navigation: $e');
    DebugLogger.instance.logError('Navigation', 'Error handling pending navigation: $e');
  }
}
