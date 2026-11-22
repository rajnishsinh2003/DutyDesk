/// Fallback stub for non-web platforms.
Future<bool> dispatchWebEmail({
  required String url,
  required String to,
  required String subject,
  required String body,
  required String fromName,
}) async {
  return false;
}

