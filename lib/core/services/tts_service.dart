import 'dart:developer';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static FlutterTts? _flutterTts;
  static bool _isInitialized = false;
  static String _currentLangCode = 'en-US';

  static Future<void> _init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts?.setLanguage(_currentLangCode);
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      log('TTS initialization error: $e');
    }
  }

  static Future<void> setLanguage(String langCode) async {
    await _init();
    String ttsLang;
    switch (langCode.toLowerCase()) {
      case 'hi':
        ttsLang = 'hi-IN';
        break;
      case 'gu':
        ttsLang = 'gu-IN';
        break;
      case 'en':
      default:
        ttsLang = 'en-US';
        break;
    }
    _currentLangCode = ttsLang;
    try {
      final isAvailable = await _flutterTts?.isLanguageAvailable(ttsLang);
      if (isAvailable == true) {
        await _flutterTts?.setLanguage(ttsLang);
      } else {
        // Graceful fallback to hi-IN or en-US
        final hiAvailable = await _flutterTts?.isLanguageAvailable('hi-IN');
        if (hiAvailable == true && langCode == 'gu') {
          await _flutterTts?.setLanguage('hi-IN');
        } else {
          await _flutterTts?.setLanguage('en-US');
        }
      }
    } catch (e) {
      log('TTS setLanguage error: $e');
    }
  }

  static Future<void> speak(String text, {String? langCode}) async {
    try {
      if (langCode != null) {
        await setLanguage(langCode);
      } else {
        await _init();
      }
      if (_flutterTts != null) {
        await _flutterTts?.stop();
        await _flutterTts?.speak(text);
      }
    } catch (e) {
      log('TTS speak error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts?.stop();
      }
    } catch (e) {
      log('TTS stop error: $e');
    }
  }

  static Future<void> speakArrivalEvaluation(String performance, String message, {String? localizedText, String? langCode}) async {
    if (localizedText != null && localizedText.isNotEmpty) {
      await speak(localizedText, langCode: langCode);
      return;
    }

    String speechText;
    switch (performance.toLowerCase()) {
      case 'excellent':
        speechText = "Excellent. You reached on time.";
        break;
      case 'good':
        speechText = "Good. You reached slightly late.";
        break;
      case 'needs improvement':
      default:
        speechText = "Needs improvement. Please reach in proper time.";
        break;
    }
    await speak(speechText, langCode: langCode);
  }
}
