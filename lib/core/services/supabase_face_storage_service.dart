import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for uploading and retrieving multi-angle biometric face photos
/// to/from Supabase Storage, and synchronizing links with Firebase Firestore.
class SupabaseFaceStorageService {
  static const String supabaseUrl = 'https://mihrdepkliehtlekepdc.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1paHJkZXBrbGllaHRsZWtlcGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE2MTY1OTksImV4cCI6MjEwNzE5MjU5OX0.P_3B09sPtWSh3kaIZU-H7MiaBJ6FIAlvkGQZ5kA6SXw';
  static const String bucketName = 'invigilator-faces';

  /// Uploads a single face angle image to Supabase Storage.
  /// [angleName] should be 'front', 'left', or 'right'.
  /// Returns the permanent public image URL.
  static Future<String> uploadFaceImage({
    required String invigilatorId,
    required String angleName,
    required Uint8List imageBytes,
  }) async {
    final cleanId = invigilatorId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = 'faces/$cleanId/${angleName.toLowerCase()}.jpg';
    final uploadEndpoint = '$supabaseUrl/storage/v1/object/$bucketName/$filePath';

    try {
      final response = await http.post(
        Uri.parse(uploadEndpoint),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'apikey': anonKey,
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true',
        },
        body: imageBytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final publicUrl = getPublicUrl(invigilatorId: cleanId, angleName: angleName);
        debugPrint('Supabase Storage: Uploaded $angleName for $cleanId -> $publicUrl');
        return publicUrl;
      } else {
        throw Exception(
          'Supabase upload failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('SupabaseFaceStorageService error: $e');
      rethrow;
    }
  }

  /// Constructs the public CDN URL for an enrolled face photo.
  static String getPublicUrl({
    required String invigilatorId,
    required String angleName,
  }) {
    final cleanId = invigilatorId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '$supabaseUrl/storage/v1/object/public/$bucketName/faces/$cleanId/${angleName.toLowerCase()}.jpg';
  }

  /// Saves the complete 3-angle face enrollment records into Firebase Firestore.
  static Future<void> saveEnrollmentToFirebase({
    required String invigilatorDocId,
    required String frontUrl,
    required String leftUrl,
    required String rightUrl,
    String? enrolledBy,
  }) async {
    final data = {
      'isFaceEnrolled': true,
      'facePhotoUrl': frontUrl, // Primary portrait
      'faceFrontUrl': frontUrl,
      'faceLeftUrl': leftUrl,
      'faceRightUrl': rightUrl,
      'faceAngleUrls': {
        'front': frontUrl,
        'left': leftUrl,
        'right': rightUrl,
      },
      'faceEnrolledAt': FieldValue.serverTimestamp(),
      if (enrolledBy != null) 'faceEnrolledBy': enrolledBy,
    };

    // Update in invigilators collection
    await FirebaseFirestore.instance
        .collection('invigilators')
        .doc(invigilatorDocId)
        .set(data, SetOptions(merge: true));

    // Also update in users collection if doc exists
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(invigilatorDocId)
          .get();
      if (userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(invigilatorDocId)
            .set(data, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}

