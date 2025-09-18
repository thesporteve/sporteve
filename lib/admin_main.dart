import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'admin/providers/admin_auth_provider.dart';
import 'admin/screens/admin_login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/theme/admin_theme.dart';
import 'admin/setup/setup_initial_admins.dart';
import 'admin/setup/setup_sample_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up initial admin accounts if they don't exist
    await AdminSetup.setupIfNeeded();
    
    // Set up sample data (tournaments & athletes) if they don't exist
    await SampleDataSetup.setupIfNeeded();
    
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

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

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
