import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'network_utils_io.dart' if (dart.library.html) 'network_utils_stub.dart';
import '../firebase_options.dart';
import 'debug_logger.dart';

/// Firebase service class that handles all Firebase operations
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  // Firebase instances
  bool _initialized = false;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseMessaging? _messaging;
  FirebaseFunctions? _functions;
  
  // Getters
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseMessaging get messaging => _messaging ?? FirebaseMessaging.instance;
  FirebaseFunctions get functions => _functions ?? FirebaseFunctions.instance;

  /// Initialize Firebase with enhanced error handling and network checks
  Future<void> initialize() async {
    if (_initialized) return;
    
    DebugLogger.instance.logInfo('Firebase', 'Starting Firebase initialization...');
    
    try {
      // Check internet connectivity first
      await _checkNetworkConnectivity();
      
      DebugLogger.instance.logInfo('Firebase', 'Initializing Firebase app...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(Duration(seconds: 30));
      
      DebugLogger.instance.logSuccess('Firebase', 'Firebase app initialized successfully');
      
      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;
      
      // Enable Firestore offline persistence for better reliability
      try {
        await _firestore!.enablePersistence();
        DebugLogger.instance.logSuccess('Firebase', 'Firestore offline persistence enabled');
      } catch (e) {
        DebugLogger.instance.logWarning('Firebase', 'Firestore persistence already enabled or not supported: $e');
      }
      
      // Initialize Firebase Functions with proper region
      _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      
      // Test Firestore connection
      await _testFirestoreConnection();
      
      _initialized = true;
      
      DebugLogger.instance.logSuccess('Firebase', 'Firebase initialized successfully with all services');
      DebugLogger.instance.logFirebaseStatus(getFirebaseStatus());
    } catch (e) {
      DebugLogger.instance.logError('Firebase', 'Firebase initialization failed: $e');
      _handleInitializationFailure(e);
    }
  }

  /// Check if Firebase is available
  bool get isFirebaseAvailable => _initialized && _firestore != null;

  /// Check network connectivity
  Future<void> _checkNetworkConnectivity() async {
    if (kIsWeb) {
      DebugLogger.instance.logInfo('Network', 'Web platform detected - network check skipped');
      return;
    }
    
    return _checkNetworkConnectivityNative();
  }
  
  /// Native network connectivity check (mobile/desktop only)
  Future<void> _checkNetworkConnectivityNative() async {
    try {
      // This will only run on mobile/desktop where dart:io is available
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 10));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        DebugLogger.instance.logSuccess('Network', 'Network connectivity confirmed');
        return;
      }
    } catch (e) {
      DebugLogger.instance.logError('Network', 'Network connectivity check failed: $e');
      throw Exception('No internet connection available');
    }
  }

  /// Test Firestore connection by attempting to read from a test collection
  Future<void> _testFirestoreConnection() async {
    try {
      DebugLogger.instance.logInfo('Firestore', 'Testing Firestore connection...');
      await _firestore!.collection('_test_')
          .limit(1)
          .get()
          .timeout(Duration(seconds: 15));
      DebugLogger.instance.logSuccess('Firestore', 'Firestore connection test successful');
    } catch (e) {
      DebugLogger.instance.logWarning('Firestore', 'Firestore connection test failed (this is normal if no data exists): $e');
      // Don't throw here as empty collections are normal
    }
  }

  /// Handle initialization failure with detailed logging
  void _handleInitializationFailure(dynamic error) {
    DebugLogger.instance.logError('Firebase', 'Firebase initialization failed with details:');
    DebugLogger.instance.log('   Error: $error');
    DebugLogger.instance.log('   Type: ${error.runtimeType}');
    
    if (error.toString().contains('network')) {
      DebugLogger.instance.log('   Cause: Network connectivity issue');
    } else if (error.toString().contains('timeout')) {
      DebugLogger.instance.log('   Cause: Connection timeout');
    } else if (error.toString().contains('configuration')) {
      DebugLogger.instance.log('   Cause: Firebase configuration issue');
    }
    
    DebugLogger.instance.logWarning('Firebase', 'App will continue with mock data');
  }

  /// Get detailed Firebase status for debugging
  Map<String, dynamic> getFirebaseStatus() {
    return {
      'initialized': _initialized,
      'firestore_available': _firestore != null,
      'auth_available': _auth != null,
      'messaging_available': _messaging != null,
      'functions_available': _functions != null,
      'overall_available': isFirebaseAvailable,
    };
  }
}
