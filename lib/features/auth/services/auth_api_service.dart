import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for the Supabase Edge Function `auth-api`.
/// Handles invigilator login, OTP request/verify, and password reset
/// entirely server-side. No Firestore reads for passwords on the client.
class AuthApiService {
  static const String _supabaseUrl = 'https://mihrdepkliehtlekepdc.supabase.co';
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_CM1FBVqHWGS-0WUzq362Kg_M-k3l9XE');

  static final Uri _endpoint =
      Uri.parse('$_supabaseUrl/functions/v1/auth-api');

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_supabaseAnonKey',
        'apikey': _supabaseAnonKey,
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw AuthApiException(
        data['error']?.toString() ?? 'Request failed',
        response.statusCode,
      );
    }

    return data;
  }

  /// Login an invigilator by mobile/resourceId + password.
  /// Returns `{ customToken, userId, userName, role }`.
  static Future<Map<String, dynamic>> loginInvigilator({
    required String identifier,
    required String password,
  }) async {
    return _post({
      'action': 'loginInvigilator',
      'identifier': identifier,
      'password': password,
    });
  }

  /// Request a password-reset OTP for an admin or invigilator.
  /// Returns `{ maskedEmail, docId }`.
  static Future<Map<String, dynamic>> requestPasswordOtp({
    required String identifier,
  }) async {
    return _post({
      'action': 'requestPasswordOtp',
      'identifier': identifier,
    });
  }

  /// Verify the 6-digit OTP.
  /// Returns `{ resetToken }`.
  static Future<Map<String, dynamic>> verifyPasswordOtp({
    required String docId,
    required String otp,
  }) async {
    return _post({
      'action': 'verifyPasswordOtp',
      'docId': docId,
      'otp': otp,
    });
  }

  /// Reset password using the token from verifyPasswordOtp.
  /// Returns `{ success: true }`.
  static Future<Map<String, dynamic>> resetPasswordWithToken({
    required String docId,
    required String resetToken,
    required String newPassword,
  }) async {
    return _post({
      'action': 'resetPasswordWithToken',
      'docId': docId,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }
}

class AuthApiException implements Exception {
  final String message;
  final int statusCode;
  AuthApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
