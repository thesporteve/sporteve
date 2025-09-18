import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'providers/news_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
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
      ],
      child: Consumer2<NewsProvider, SettingsProvider>(
        builder: (context, newsProvider, settingsProvider, child) {
          // Initialize settings on first run
          if (!settingsProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              settingsProvider.loadSettings();
            });
          }
          
          // Set up notification tap callback to refresh news
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.instance.setNotificationTapCallback(() {
              print('📱 Notification tapped - refreshing news feed...');
              newsProvider.refresh();
            });
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
    final publicRoutes = ['/', '/home', '/signin', '/search', '/bookmarks', '/settings'];
    
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
      builder: (context, state) => const SplashScreen(),
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
      path: '/news/:id',
      builder: (context, state) {
        final newsId = state.pathParameters['id']!;
        return NewsDetailScreen(newsId: newsId);
      },
    ),
  ],
);
