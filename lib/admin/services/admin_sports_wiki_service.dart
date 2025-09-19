import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/sport_wiki.dart';
import '../../services/firebase_service.dart';

class AdminSportsWikiService {
  static AdminSportsWikiService? _instance;
  static AdminSportsWikiService get instance => _instance ??= AdminSportsWikiService._internal();
  
  AdminSportsWikiService._internal();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _collection => _firestore.collection('sports_wiki');

  // Get all sports wiki entries
  Future<List<SportWiki>> getAllSportsWiki() async {
    try {
      print('Fetching all sports wiki entries from Firestore...');
      final querySnapshot = await _collection
          .orderBy('name')
          .get();

      print('Found ${querySnapshot.docs.length} sports wiki entries');
      
      return querySnapshot.docs
          .map((doc) => SportWiki.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching sports wiki entries: $e');
      // Try without orderBy as fallback
      try {
        final querySnapshot = await _collection.get();
        return querySnapshot.docs
            .map((doc) => SportWiki.fromFirestore(doc))
            .toList();
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  // Get single sports wiki entry by ID
  Future<SportWiki?> getSportsWikiById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return SportWiki.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching sports wiki entry $id: $e');
      return null;
    }
  }

  // Add new sports wiki entry
  Future<String> addSportsWikiEntry(SportWiki sportsWiki) async {
    try {
      final docRef = await _collection.add(sportsWiki.toFirestore());
      print('✅ Added sports wiki entry: ${sportsWiki.name} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding sports wiki entry: $e');
      throw Exception('Failed to add sports wiki entry: $e');
    }
  }

  // Update existing sports wiki entry
  Future<void> updateSportsWikiEntry(String id, SportWiki sportsWiki) async {
    try {
      final updateData = sportsWiki.toFirestore();
      updateData['last_updated'] = FieldValue.serverTimestamp();
      
      await _collection.doc(id).update(updateData);
      print('✅ Updated sports wiki entry: $id');
    } catch (e) {
      print('❌ Error updating sports wiki entry: $e');
      throw Exception('Failed to update sports wiki entry: $e');
    }
  }

  // Delete sports wiki entry
  Future<void> deleteSportsWikiEntry(String id) async {
    try {
      // Get the entry first to clean up images
      final entry = await getSportsWikiById(id);
      
      // Delete associated images from storage
      if (entry?.images != null) {
        await _deleteImagesFromStorage(entry!.images!);
      }
      
      // Delete the document
      await _collection.doc(id).delete();
      print('✅ Deleted sports wiki entry: $id');
    } catch (e) {
      print('❌ Error deleting sports wiki entry: $e');
      throw Exception('Failed to delete sports wiki entry: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage({
    required String sportName,
    required String imageType, // hero, equipment, action_1, etc.
    required Uint8List imageData,
    required String fileName,
  }) async {
    try {
      // Clean sport name for storage path
      final cleanSportName = sportName.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      
      // Create storage path
      final path = 'sports_wiki/$cleanSportName/${imageType}_$fileName';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(path);
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'sport': sportName,
          'imageType': imageType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(imageData, metadata);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Uploaded image: $path');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Deleted image: $imageUrl');
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Don't throw error as image might already be deleted
    }
  }

  // Delete multiple images from storage
  Future<void> _deleteImagesFromStorage(Map<String, String> images) async {
    for (final imageUrl in images.values) {
      if (imageUrl.isNotEmpty) {
        await deleteImage(imageUrl);
      }
    }
  }

  // Generate thumbnail (optional - for future enhancement)
  Future<String?> uploadThumbnail({
    required String sportName,
    required String imageType,
    required Uint8List thumbnailData,
  }) async {
    try {
      final cleanSportName = sportName.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      
      final path = 'sports_wiki/$cleanSportName/${imageType}_thumbnail.jpg';
      final ref = _storage.ref().child(path);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'sport': sportName,
          'imageType': '${imageType}_thumbnail',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(thumbnailData, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Uploaded thumbnail: $path');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading thumbnail: $e');
      return null;
    }
  }

  // Helper method to determine content type
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  // Get storage usage for a sport (optional - for admin insights)
  Future<Map<String, int>> getStorageUsage(String sportName) async {
    try {
      final cleanSportName = sportName.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      
      final listResult = await _storage.ref()
          .child('sports_wiki/$cleanSportName')
          .listAll();
      
      int totalSize = 0;
      int fileCount = listResult.items.length;
      
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += (metadata.size ?? 0).toInt();
      }
      
      return {
        'fileCount': fileCount,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
      };
    } catch (e) {
      print('Error getting storage usage: $e');
      return {'fileCount': 0, 'totalSizeBytes': 0, 'totalSizeMB': 0};
    }
  }

  // Search sports wiki entries
  Future<List<SportWiki>> searchSportsWiki(String query) async {
    if (query.isEmpty) return getAllSportsWiki();
    
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia or similar
      final allEntries = await getAllSportsWiki();
      
      return allEntries.where((entry) {
        final searchTerm = query.toLowerCase();
        return entry.name.toLowerCase().contains(searchTerm) ||
               entry.category.toLowerCase().contains(searchTerm) ||
               entry.type.toLowerCase().contains(searchTerm) ||
               entry.description.toLowerCase().contains(searchTerm) ||
               (entry.tags?.any((tag) => tag.toLowerCase().contains(searchTerm)) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching sports wiki: $e');
      return [];
    }
  }

  // Get sports wiki entries by category
  Future<List<SportWiki>> getSportsWikiByCategory(String category) async {
    try {
      final querySnapshot = await _collection
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs
          .map((doc) => SportWiki.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching sports wiki by category: $e');
      return [];
    }
  }

  // Get sports wiki entries by type
  Future<List<SportWiki>> getSportsWikiByType(String type) async {
    try {
      final querySnapshot = await _collection
          .where('type', isEqualTo: type)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs
          .map((doc) => SportWiki.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching sports wiki by type: $e');
      return [];
    }
  }

  // Validate sport name uniqueness
  Future<bool> isNameUnique(String name, {String? excludeId}) async {
    try {
      final querySnapshot = await _collection
          .where('name', isEqualTo: name)
          .get();
      
      // If no documents found, name is unique
      if (querySnapshot.docs.isEmpty) return true;
      
      // If editing existing entry, check if the found document is the same one being edited
      if (excludeId != null && querySnapshot.docs.length == 1) {
        return querySnapshot.docs.first.id == excludeId;
      }
      
      return false;
    } catch (e) {
      print('Error checking name uniqueness: $e');
      return false;
    }
  }
}
