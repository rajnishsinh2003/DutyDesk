import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// DEPRECATED: Supabase storage is no longer used for facial biometrics.
/// DutyDesk has migrated to deep on-device face embeddings (MobileFaceNet + ML Kit)
/// stored directly as numeric vectors in Cloud Firestore.
///
/// SECURITY NOTICE:
/// The previously hardcoded anon key has been removed from source control.
/// Ensure you rotate the Supabase anon key in your Supabase project settings immediately.
@Deprecated('Use FaceEmbeddingService and Cloud Firestore embeddings instead.')
class SupabaseFaceStorageService {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mihrdepkliehtlekepdc.supabase.co',
  );

  /// Loaded from compile-time environment or config — never hardcoded in source control.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String bucketName = 'invigilator-faces';

  /// Legacy upload method (Deprecated).
  @Deprecated('Face images are no longer uploaded to Supabase.')
  static Future<String> uploadFaceImage({
    required String invigilatorId,
    required String angleName,
    required Uint8List imageBytes,
  }) async {
    if (anonKey.isEmpty) {
      throw StateError(
        'Supabase anon key is not configured. Biometric storage has migrated to Cloud Firestore embeddings.',
      );
    }
    final cleanId = invigilatorId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = 'faces/$cleanId/${angleName.toLowerCase()}.jpg';
    final uploadEndpoint = '$supabaseUrl/storage/v1/object/$bucketName/$filePath';

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
      return getPublicUrl(invigilatorId: cleanId, angleName: angleName);
    } else {
      throw Exception('Supabase upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Legacy public URL generator (Deprecated).
  @Deprecated('Biometric verification uses Cloud Firestore embeddings instead.')
  static String getPublicUrl({
    required String invigilatorId,
    required String angleName,
  }) {
    final cleanId = invigilatorId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '$supabaseUrl/storage/v1/object/public/$bucketName/faces/$cleanId/${angleName.toLowerCase()}.jpg';
  }

  /// Legacy Firebase sync (Deprecated).
  @Deprecated('Use FaceEmbeddingService to save numeric embeddings directly.')
  static Future<void> saveEnrollmentToFirebase({
    required String invigilatorDocId,
    required String frontUrl,
    required String leftUrl,
    required String rightUrl,
    String? enrolledBy,
  }) async {
    // Deprecated no-op
  }
}
