import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'chatbot_api_service.dart';

class DocumentUploadService {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mihrdepkliehtlekepdc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String bucketName = 'chatbot-docs';

  /// Uploads a PDF, DOCX, or TXT file to Supabase Storage (`chatbot-docs` bucket)
  /// and creates a `chatbot_documents` record in Firestore with `status: 'uploaded'`
  /// to trigger the Cloud Function extraction & embedding pipeline.
  static Future<String> uploadFileDocument({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String title,
    required String description,
    required String category,
    required List<String> audience,
    required String uploadedBy,
    void Function(double progress)? onProgress,
  }) async {
    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not configured. Pass --dart-define=SUPABASE_ANON_KEY=your_key when building.',
      );
    }

    final db = FirebaseFirestore.instance;
    final docRef = db.collection('chatbot_documents').doc();
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '${docRef.id}_$safeFileName';
    final uploadEndpoint = '$supabaseUrl/storage/v1/object/$bucketName/$storagePath';

    onProgress?.call(0.25);

    final response = await http.post(
      Uri.parse(uploadEndpoint),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
        'Content-Type': mimeType,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Supabase upload failed (${response.statusCode}): ${response.body}',
      );
    }

    onProgress?.call(0.85);

    final storageUrl = '$supabaseUrl/storage/v1/object/public/$bucketName/$storagePath';

    await docRef.set({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'audience': audience.isEmpty ? ['public'] : audience,
      'sourceType': 'file',
      'storageProvider': 'supabase',
      'storagePath': storagePath,
      'storageUrl': storageUrl,
      'mimeType': mimeType,
      'sizeBytes': bytes.length,
      'status': 'uploaded',
      'chunkCount': 0,
      'enabled': true,
      'version': 1,
      'uploadedBy': uploadedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    onProgress?.call(0.95);
    await ChatbotApiService.processDocument(docRef.id);
    onProgress?.call(1.0);
    return docRef.id;
  }

  /// Creates a pasted-text document directly in Firestore (`sourceType: 'text'`).
  static Future<String> createTextDocument({
    required String title,
    required String description,
    required String category,
    required List<String> audience,
    required String rawText,
    required String uploadedBy,
  }) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection('chatbot_documents').doc();
    await docRef.set({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'audience': audience.isEmpty ? ['public'] : audience,
      'sourceType': 'text',
      'rawText': rawText.trim(),
      'mimeType': 'text/plain',
      'sizeBytes': rawText.trim().length,
      'status': 'uploaded',
      'chunkCount': 0,
      'enabled': true,
      'version': 1,
      'uploadedBy': uploadedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ChatbotApiService.processDocument(docRef.id);
    return docRef.id;
  }
}
