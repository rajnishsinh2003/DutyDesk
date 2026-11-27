import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Web implementation using window.dutyDeskSendEmail or HTTP POST.
Future<bool> dispatchWebEmail({
  required String url,
  required String to,
  required String subject,
  required String body,
  required String fromName,
}) async {
  // ── Strategy 1: Native browser fetch via window.dutyDeskSendEmail ──
  try {
    final fn = globalContext['dutyDeskSendEmail'];
    if (fn != null && fn.isA<JSFunction>()) {
      final completer = Completer<bool>();
      final callback = ((JSBoolean success, JSAny? result) {
        if (!completer.isCompleted) {
          completer.complete(success.toDart);
        }
      }).toJS;

      globalContext.callMethodVarArgs(
        'dutyDeskSendEmail'.toJS,
        [
          to.toJS,
          subject.toJS,
          body.toJS,
          fromName.toJS,
          callback,
        ],
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (result) return true;
    }
  } catch (e) {
    debugPrint('dutyDeskSendEmail window call error: $e');
  }

  // ── Strategy 2: Direct HTTP POST (CORS-friendly text/plain) ──
  try {
    final response = await http
        .post(
          Uri.parse(url.trim()),
          headers: {'Content-Type': 'text/plain;charset=utf-8'},
          body: jsonEncode({
            'to': to,
            'subject': subject,
            'body': body,
            'fromName': fromName,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return response.statusCode >= 200 && response.statusCode < 400;
  } catch (e) {
    debugPrint('Web email HTTP dispatch error: $e');
    return false;
  }
}
