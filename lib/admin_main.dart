import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'admin/providers/admin_auth_provider.dart';
import 'admin/screens/admin_login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/theme/admin_theme.dart';
import 'admin/setup/setup_initial_admins.dart';
import 'admin/setup/setup_sample_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with all services including Functions
    await FirebaseService.instance.initialize();
    
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const SportEveAdminApp());
}

class SportEveAdminApp extends StatelessWidget {
  const SportEveAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAuthProvider(),
      child: MaterialApp(
        title: 'SportEve Admin',
        theme: AdminTheme.lightTheme,
        darkTheme: AdminTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AdminAuthWrapper(),
      ),
    );
  }
}

class AdminAuthWrapper extends StatefulWidget {
  const AdminAuthWrapper({super.key});

  @override
  State<AdminAuthWrapper> createState() => _AdminAuthWrapperState();
}

class _AdminAuthWrapperState extends State<AdminAuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Run setup tasks asynchronously after the app loads
    _runBackgroundSetup();
  }

  Future<void> _runBackgroundSetup() async {
    try {
      print('🔧 Running background setup tasks...');
      
      // Run both setup tasks concurrently
      await Future.wait([
        AdminSetup.setupIfNeeded(),
        SampleDataSetup.setupIfNeeded(),
      ]);
      
      print('✅ Background setup completed');
    } catch (e) {
      print('❌ Background setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const AdminDashboardScreen();
        } else {
          return const AdminLoginScreen();
        }
      },
    );
  }
}
