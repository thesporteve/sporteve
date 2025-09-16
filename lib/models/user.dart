import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? profilePic;
  final String role; // 'admin' or 'standard'
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profilePic,
    required this.role,
    required this.createdAt,
  });

  // Create User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profilePic: data['profile_pic'],
      role: data['role'] ?? 'standard',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profile_pic'],
      role: map['role'] ?? 'standard',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert User to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'profile_pic': profilePic,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isStandard => role == 'standard';

  // Create copy with updated fields
  User copyWith({
    String? email,
    String? name,
    String? profilePic,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
