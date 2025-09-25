import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Safe lazy initialization - only access when Firebase is ready
  firebase_auth.FirebaseAuth get _firebaseAuth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Temporarily comment out serverClientId to test basic flow
    // serverClientId: '281561259389-f419lu49ls5ita67or3hpvsftdq7b1ps.apps.googleusercontent.com',
  );

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  // Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with Google
  Future<app_user.User?> signInWithGoogle() async {
    try {
      // Ensure clean state
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      
      print('Starting fresh Google Sign-In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        print('User cancelled Google Sign-In');
        return null;
      }

      print('Google Sign-In successful for: ${googleUser.email}');
      print('Google user ID: ${googleUser.id}');

      // Obtain the auth details from the request
      print('Requesting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Access token available: ${googleAuth.accessToken != null}');
      print('ID token available: ${googleAuth.idToken != null}');
      
      if (googleAuth.idToken != null) {
        print('ID Token length: ${googleAuth.idToken!.length}');
      } else {
        print('ID Token is null - this will cause Firebase Auth to fail');
      }
      
      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to obtain Google authentication tokens');
        print('AccessToken: ${googleAuth.accessToken}');
        print('IdToken: ${googleAuth.idToken}');
        
        // Try to get tokens again
        try {
          final freshAuth = await googleUser.authentication;
          print('Retry - Access token available: ${freshAuth.accessToken != null}');
          print('Retry - ID token available: ${freshAuth.idToken != null}');
          
          if (freshAuth.accessToken == null || freshAuth.idToken == null) {
            print('Still failed to get tokens after retry');
            return null;
          }
          
          // Use the fresh tokens
          final credential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: freshAuth.accessToken,
            idToken: freshAuth.idToken,
          );
          
          final firebase_auth.UserCredential userCredential = 
              await _firebaseAuth.signInWithCredential(credential);
          
          final firebase_auth.User? firebaseUser = userCredential.user;
          
          if (firebaseUser != null) {
            print('Firebase authentication successful with retry for: ${firebaseUser.email}');
            return await _createOrUpdateUser(firebaseUser);
          }
          
        } catch (retryError) {
          print('Retry failed: $retryError');
        }
        
        return null;
      }

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        print('Firebase authentication successful for: ${firebaseUser.email}');
        // Create or update user in Firestore
        return await _createOrUpdateUser(firebaseUser);
      }
      
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      // Try to get more details about the error
      if (e.toString().contains('PigeonUserDetails')) {
        print('This appears to be a version compatibility issue with Google Sign-In');
      }
      return null;
    }
  }

  // Create or update user in Firestore
  Future<app_user.User?> _createOrUpdateUser(firebase_auth.User firebaseUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        // User exists, return the existing user data
        return app_user.User.fromFirestore(userDoc);
      } else {
        // New user, create user document
        final newUser = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          profilePic: firebaseUser.photoURL,
          role: 'standard', // Default role
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print('Error creating/updating user: $e');
      return null;
    }
  }

  // Get current app user data from Firestore
  Future<app_user.User?> getCurrentUser() async {
    try {
      final firebaseUser = currentFirebaseUser;
      if (firebaseUser == null) return null;
      
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return app_user.User.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? profilePic,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (name != null) {
        updateData['name'] = name;
        // Also update Firebase Auth profile
        await currentFirebaseUser?.updateDisplayName(name);
      }
      
      if (profilePic != null) {
        updateData['profile_pic'] = profilePic;
        // Also update Firebase Auth profile
        await currentFirebaseUser?.updatePhotoURL(profilePic);
      }
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentFirebaseUser != null;
  
  // Get user ID
  String? get currentUserId => currentFirebaseUser?.uid;
}
