import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

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
  
  // Getters
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseMessaging get messaging => _messaging ?? FirebaseMessaging.instance;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;
      _initialized = true;
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Continue with sample data if Firebase fails
    }
  }

  /// Check if Firebase is available
  bool get isFirebaseAvailable => _initialized && _firestore != null;
}
