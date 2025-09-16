import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'providers/news_provider.dart';
import 'screens/home_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.instance.initialize();
  
  runApp(const SportEveApp());
}

class SportEveApp extends StatelessWidget {
  const SportEveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          return MaterialApp.router(
            title: 'SportEve',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
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
    final publicRoutes = ['/', '/home', '/signin', '/search', '/bookmarks', '/admin'];
    
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
      path: '/admin',
      builder: (context, state) => const AdminPanelScreen(),
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
