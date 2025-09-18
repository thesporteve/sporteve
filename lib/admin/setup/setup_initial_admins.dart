import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// One-time setup script to create initial admin accounts in Firestore
/// Run this once to set up your admin accounts, then remove/comment it out
class AdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create initial admin accounts
  static Future<void> createInitialAdmins() async {
    try {
      print('Setting up initial admin accounts...');

      // Create main admin
      await _firestore.collection('admins').add({
        'username': 'admin',
        'email': 'admin@sporteve.com',
        'passwordHash': _hashPassword('sporteve2024'),
        'role': 'admin',
        'displayName': 'Admin User',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      });

      // Create super admin
      await _firestore.collection('admins').add({
        'username': 'super_admin',
        'email': 'superadmin@sporteve.com',
        'passwordHash': _hashPassword('sporteve_super_2024'),
        'role': 'super_admin',
        'displayName': 'Super Admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
      });

      print('✅ Initial admin accounts created successfully!');
      print('Admin credentials:');
      print('  Username: admin | Password: sporteve2024');
      print('  Username: super_admin | Password: sporteve_super_2024');
      print('');
      print('🔐 Remember to change these passwords in production!');
      
    } catch (e) {
      print('❌ Error setting up admin accounts: $e');
    }
  }

  /// Check if any admin accounts exist
  static Future<bool> adminAccountsExist() async {
    try {
      final querySnapshot = await _firestore.collection('admins').limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin accounts: $e');
      return false;
    }
  }

  /// Run setup only if no admin accounts exist
  static Future<void> setupIfNeeded() async {
    try {
      final exists = await adminAccountsExist();
      if (!exists) {
        print('No admin accounts found. Setting up initial accounts...');
        await createInitialAdmins();
      } else {
        print('Admin accounts already exist. Skipping setup.');
      }
    } catch (e) {
      print('Error in setup: $e');
    }
  }
}
