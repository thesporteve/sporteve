import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

/// Firebase service class that handles all Firebase operations
/// Currently uses mock data but ready for Firebase integration
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  // Firebase instances
  bool _initialized = false;
  FirebaseFirestore? _firestore;
  
  // Getters
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize Firebase services
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Continue with mock data if Firebase fails
    }
  }

  /// Check if Firebase is available
  bool get isFirebaseAvailable => _initialized && _firestore != null;
}
