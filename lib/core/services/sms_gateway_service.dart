import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A multi-channel messaging gateway service that supports SMS and WhatsApp
/// message delivery through configurable external API gateways.
///
/// Supports popular Indian SMS gateways (Msg91, Fast2SMS, Textlocal)
/// and WhatsApp Business API / Twilio WhatsApp.
///
/// Usage:
/// ```dart
/// await SmsGatewayService.sendSms(
///   gatewayUrl: 'https://api.fast2sms.com/dev/bulkV2',
///   apiKey: 'YOUR_API_KEY',
///   recipientPhone: '9876543210',
///   message: 'Your duty has been assigned.',
///   provider: SmsProvider.fast2sms,
/// );
/// ```
class SmsGatewayService {
  /// Send an SMS via the configured gateway provider.
  ///
  /// [gatewayUrl] - The base URL of the SMS gateway API endpoint.
  /// [apiKey] - API key / auth token for the gateway.
  /// [recipientPhone] - The recipient's mobile number (10-digit Indian or full E.164).
  /// [message] - The text content to send.
  /// [provider] - The SMS provider type for request formatting.
  /// [senderId] - Optional sender ID (required by some providers).
  /// [templateId] - Optional DLT template ID for Indian regulatory compliance.
  static Future<SmsDeliveryResult> sendSms({
    required String gatewayUrl,
    required String apiKey,
    required String recipientPhone,
    required String message,
    SmsProvider provider = SmsProvider.generic,
    String? senderId,
    String? templateId,
  }) async {
    if (gatewayUrl.isEmpty || apiKey.isEmpty) {
      return SmsDeliveryResult(
        success: false,
        channel: 'sms',
        error: 'SMS gateway not configured. Set gateway URL and API key in Settings.',
      );
    }

    final cleanPhone = recipientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.length < 10) {
      return SmsDeliveryResult(
        success: false,
        channel: 'sms',
        error: 'Invalid phone number: $recipientPhone',
      );
    }

    try {
      http.Response response;

      switch (provider) {
        case SmsProvider.fast2sms:
          response = await _sendViaFast2Sms(gatewayUrl, apiKey, cleanPhone, message);
          break;
        case SmsProvider.msg91:
          response = await _sendViaMsg91(gatewayUrl, apiKey, cleanPhone, message, senderId, templateId);
          break;
        case SmsProvider.textlocal:
          response = await _sendViaTextlocal(gatewayUrl, apiKey, cleanPhone, message, senderId);
          break;
        case SmsProvider.twilio:
          response = await _sendViaTwilio(gatewayUrl, apiKey, cleanPhone, message, senderId);
          break;
        case SmsProvider.generic:
          response = await _sendViaGenericApi(gatewayUrl, apiKey, cleanPhone, message);
          break;
      }

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('SMS Gateway [${provider.name}]: ${response.statusCode} - ${response.body}');

      return SmsDeliveryResult(
        success: isSuccess,
        channel: 'sms',
        statusCode: response.statusCode,
        responseBody: response.body,
        error: isSuccess ? null : 'Gateway returned HTTP ${response.statusCode}',
      );
    } catch (e) {
      log('SMS Gateway Error: $e');
      return SmsDeliveryResult(
        success: false,
        channel: 'sms',
        error: e.toString(),
      );
    }
  }

  /// Send a WhatsApp message via Twilio WhatsApp API or WhatsApp Business API.
  ///
  /// [gatewayUrl] - WhatsApp Business API endpoint or Twilio WhatsApp endpoint.
  /// [apiKey] - Bearer token or Twilio auth (base64 SID:Token).
  /// [recipientPhone] - Recipient's phone in E.164 format (e.g., +919876543210).
  /// [message] - Text message content.
  /// [templateName] - Optional WhatsApp template name for approved business messages.
  static Future<SmsDeliveryResult> sendWhatsApp({
    required String gatewayUrl,
    required String apiKey,
    required String recipientPhone,
    required String message,
    String? templateName,
  }) async {
    if (gatewayUrl.isEmpty || apiKey.isEmpty) {
      return SmsDeliveryResult(
        success: false,
        channel: 'whatsapp',
        error: 'WhatsApp gateway not configured.',
      );
    }

    final cleanPhone = recipientPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    try {
      final response = await http.post(
        Uri.parse(gatewayUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': cleanPhone,
          'type': templateName != null ? 'template' : 'text',
          if (templateName != null)
            'template': {
              'name': templateName,
              'language': {'code': 'en'},
            }
          else
            'text': {'body': message},
        }),
      );

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('WhatsApp Gateway: ${response.statusCode} - ${response.body}');

      return SmsDeliveryResult(
        success: isSuccess,
        channel: 'whatsapp',
        statusCode: response.statusCode,
        responseBody: response.body,
        error: isSuccess ? null : 'WhatsApp gateway returned HTTP ${response.statusCode}',
      );
    } catch (e) {
      log('WhatsApp Gateway Error: $e');
      return SmsDeliveryResult(
        success: false,
        channel: 'whatsapp',
        error: e.toString(),
      );
    }
  }

  /// Bulk send SMS to multiple recipients.
  ///
  /// Returns a map of phone number → delivery result.
  static Future<Map<String, SmsDeliveryResult>> sendBulkSms({
    required String gatewayUrl,
    required String apiKey,
    required List<String> recipientPhones,
    required String message,
    SmsProvider provider = SmsProvider.generic,
    String? senderId,
  }) async {
    final results = <String, SmsDeliveryResult>{};

    // Fast2SMS supports comma-separated bulk natively
    if (provider == SmsProvider.fast2sms && recipientPhones.length > 1) {
      final result = await sendSms(
        gatewayUrl: gatewayUrl,
        apiKey: apiKey,
        recipientPhone: recipientPhones.join(','),
        message: message,
        provider: provider,
        senderId: senderId,
      );
      for (final phone in recipientPhones) {
        results[phone] = result;
      }
      return results;
    }

    // Sequential delivery for other providers
    for (final phone in recipientPhones) {
      results[phone] = await sendSms(
        gatewayUrl: gatewayUrl,
        apiKey: apiKey,
        recipientPhone: phone,
        message: message,
        provider: provider,
        senderId: senderId,
      );
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return results;
  }

  // ========================
  // Provider-specific implementations
  // ========================

  static Future<http.Response> _sendViaFast2Sms(
    String url, String apiKey, String phone, String message,
  ) {
    return http.post(
      Uri.parse(url.isEmpty ? 'https://www.fast2sms.com/dev/bulkV2' : url),
      headers: {
        'authorization': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'route': 'q',
        'message': message,
        'language': 'english',
        'flash': 0,
        'numbers': phone,
      }),
    );
  }

  static Future<http.Response> _sendViaMsg91(
    String url, String apiKey, String phone, String message, String? senderId, String? templateId,
  ) {
    return http.post(
      Uri.parse(url.isEmpty ? 'https://control.msg91.com/api/v5/flow/' : url),
      headers: {
        'authkey': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'template_id': templateId ?? '',
        'sender': senderId ?? 'DUTYDK',
        'short_url': '0',
        'mobiles': phone.startsWith('91') ? phone : '91$phone',
        'message': message,
      }),
    );
  }

  static Future<http.Response> _sendViaTextlocal(
    String url, String apiKey, String phone, String message, String? senderId,
  ) {
    return http.post(
      Uri.parse(url.isEmpty ? 'https://api.textlocal.in/send/' : url),
      body: {
        'apikey': apiKey,
        'numbers': phone,
        'message': message,
        'sender': senderId ?? 'DUTYDK',
      },
    );
  }

  static Future<http.Response> _sendViaTwilio(
    String url, String apiKey, String phone, String message, String? fromNumber,
  ) {
    return http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $apiKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': phone.startsWith('+') ? phone : '+91$phone',
        'From': fromNumber ?? '',
        'Body': message,
      },
    );
  }

  static Future<http.Response> _sendViaGenericApi(
    String url, String apiKey, String phone, String message,
  ) {
    return http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'message': message,
      }),
    );
  }
}

/// Supported SMS gateway providers.
enum SmsProvider {
  fast2sms,
  msg91,
  textlocal,
  twilio,
  generic,
}

/// Represents the result of an SMS/WhatsApp delivery attempt.
class SmsDeliveryResult {
  final bool success;
  final String channel; // 'sms' or 'whatsapp'
  final int? statusCode;
  final String? responseBody;
  final String? error;

  SmsDeliveryResult({
    required this.success,
    required this.channel,
    this.statusCode,
    this.responseBody,
    this.error,
  });

  @override
  String toString() => 'SmsDeliveryResult(success=$success, channel=$channel, code=$statusCode, error=$error)';
}
