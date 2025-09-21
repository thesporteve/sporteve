import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AdminAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentAdminId;
  Map<String, dynamic>? _currentAdminData;
  
  FirebaseFirestore? _firestore;
  
  AdminAuthProvider() {
    _initializeFirestore();
  }
  
  Future<void> _initializeFirestore() async {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      print('Failed to initialize Firestore in AdminAuthProvider: $e');
      if (kIsWeb) {
        print('Web platform detected - Firestore initialization may be delayed');
      }
    }
  }
  

  bool get isAuthenticated => _isAuthenticated;
  String? get currentAdminId => _currentAdminId;
  Map<String, dynamic>? get currentAdminData => _currentAdminData;
  String? get currentAdmin => _currentAdminData?['username']; // For backward compatibility

  /// Login with username/email and password
  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      return await _loginWithFirestore(usernameOrEmail, password);
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Login with Firestore admin collection
  Future<bool> _loginWithFirestore(String usernameOrEmail, String password) async {
    try {
      // Ensure Firestore is initialized
      if (_firestore == null) {
        await _initializeFirestore();
        if (_firestore == null) {
          print('Firestore not available');
          return false;
        }
      }
      
      // Hash the password for comparison
      final hashedPassword = _hashPassword(password);
      
      // Query for admin by username or email
      QuerySnapshot query = await _firestore!
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final username = data['username'] ?? '';
        final email = data['email'] ?? '';
        final storedPasswordHash = data['passwordHash'] ?? '';

        if ((username == usernameOrEmail || email == usernameOrEmail) &&
            storedPasswordHash == hashedPassword) {
          
          // Update last login
          await _firestore!.collection('admins').doc(doc.id).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          _isAuthenticated = true;
          _currentAdminId = doc.id;
          _currentAdminData = data;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Firestore login error: $e');
      return false;
    }
  }


  /// Logout the current admin
  void logout() {
    _isAuthenticated = false;
    _currentAdminId = null;
    _currentAdminData = null;
    notifyListeners();
  }

  /// Check if current user has super admin privileges
  bool get isSuperAdmin => _currentAdminData?['role'] == 'super_admin';
  
  /// Get display name for current admin
  String get displayName => _currentAdminData?['displayName'] ?? 'Unknown';
  
  /// Get username for current admin
  String get username => _currentAdminData?['username'] ?? 'unknown';
  
  /// Get email for current admin
  String get email => _currentAdminData?['email'] ?? '';

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get all active admins (for author selection)
  Future<List<Map<String, dynamic>>> getActiveAdmins() async {
    try {
      print('🔍 AdminAuthProvider: Fetching active admins from Firestore...');
      
      // Ensure Firestore is initialized
      if (_firestore == null) {
        await _initializeFirestore();
        if (_firestore == null) {
          print('Firestore not available');
          return [];
        }
      }
      
      final querySnapshot = await _firestore!
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();
      
      print('📊 Found ${querySnapshot.docs.length} active admin(s) in Firestore');
      
      final admins = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('👤 Admin found: ${data['username']} - ${data['displayName']}');
        
        return {
          'id': doc.id,
          'username': data['username'] ?? '',
          'displayName': data['displayName'] ?? '',
          'email': data['email'] ?? '',
          'role': data['role'] ?? '',
        };
      }).toList();
      
      print('✅ Returning ${admins.length} real admins');
      return admins;
    } catch (e) {
      print('❌ Error fetching active admins: $e');
      return [];
    }
  }

  /// Create a new admin (only for super admins)
  Future<bool> createAdmin({
    required String username,
    required String email,
    required String password,
    required String role,
    required String displayName,
  }) async {
    if (!isSuperAdmin) return false;

    try {
      final hashedPassword = _hashPassword(password);
      
      await _firestore!.collection('admins').add({
        'username': username,
        'email': email,
        'passwordHash': hashedPassword,
        'role': role,
        'displayName': displayName,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _currentAdminId,
      });
      
      return true;
    } catch (e) {
      print('Error creating admin: $e');
      return false;
    }
  }

  /// Update admin status (only for super admins)
  Future<bool> updateAdminStatus(String adminId, bool isActive) async {
    if (!isSuperAdmin) return false;

    try {
      await _firestore!.collection('admins').doc(adminId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentAdminId,
      });
      
      return true;
    } catch (e) {
      print('Error updating admin status: $e');
      return false;
    }
  }

  /// Get all admins (only for super admins)
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    if (!isSuperAdmin) return [];

    try {
      final querySnapshot = await _firestore!.collection('admins').get();
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching all admins: $e');
      return [];
    }
  }

  /// Delete admin (only for super admins)
  Future<bool> deleteAdmin(String adminId) async {
    if (!isSuperAdmin) return false;

    try {
      await _firestore!.collection('admins').doc(adminId).delete();
      return true;
    } catch (e) {
      print('Error deleting admin: $e');
      return false;
    }
  }

  /// Update admin (only for super admins)
  Future<bool> updateAdmin({
    required String adminId,
    required String username,
    required String email,
    required String role,
    required String displayName,
    String? password,
  }) async {
    if (!isSuperAdmin) return false;

    try {
      final updateData = {
        'username': username,
        'email': email,
        'role': role,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentAdminId,
      };

      // Only update password if provided
      if (password != null && password.isNotEmpty) {
        updateData['passwordHash'] = _hashPassword(password);
      }

      await _firestore!.collection('admins').doc(adminId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating admin: $e');
      return false;
    }
  }
}
