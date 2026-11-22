import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

/// Web implementation using native browser fetch or XMLHttpRequest.
Future<bool> dispatchWebEmail({
  required String url,
  required String to,
  required String subject,
  required String body,
  required String fromName,
}) async {
  // ── Strategy 1: Native browser fetch via window.dutyDeskSendEmail ──
  try {
    if (js.context.hasProperty('dutyDeskSendEmail')) {
      final completer = Completer<bool>();
      js.context.callMethod('dutyDeskSendEmail', [
        to,
        subject,
        body,
        fromName,
        js.allowInterop((bool success, dynamic result) {
          if (!completer.isCompleted) {
            completer.complete(success);
          }
        }),
      ]);

      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (result) return true;
    }
  } catch (e) {
    html.window.console.warn('dutyDeskSendEmail window call error: $e');
  }

  // ── Strategy 2: Direct dart:html HttpRequest (CORS-friendly text/plain) ──
  try {
    final completer = Completer<bool>();
    final xhr = html.HttpRequest();
    xhr.open('POST', url, async: true);
    xhr.setRequestHeader('Content-Type', 'text/plain;charset=utf-8');

    xhr.onLoad.listen((_) {
      final status = xhr.status ?? 0;
      if (!completer.isCompleted) {
        completer.complete(status >= 200 && status < 400);
      }
    });

    xhr.onError.listen((e) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final payload = jsonEncode({
      'to': to,
      'subject': subject,
      'body': body,
      'fromName': fromName,
    });

    xhr.send(payload);

    return await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => false,
    );
  } catch (e) {
    html.window.console.error('HttpRequest dispatch error: $e');
    return false;
  }
}

