import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../../core/providers/language_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context)!;

    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'nativeName': 'English'},
      {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'nativeName': 'Hindi'},
      {'code': 'gu', 'name': 'ગુજરાતી', 'flag': '🇮🇳', 'nativeName': 'Gujarati'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.language),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.selectLanguage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentLocale.languageCode == lang['code'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF007A87)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await ref
                          .read(languageProvider.notifier)
                          .setLanguageCode(lang['code']!);
                      if (context.mounted) {
                        final newS = S.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(newS.languageChangedSuccess),
                              ],
                            ),
                            backgroundColor: const Color(0xFF007A87),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF007A87)
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (lang['nativeName'] != lang['name'])
                                  Text(
                                    lang['nativeName']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: lang['code']!,
                            // ignore: deprecated_member_use
                            groupValue: currentLocale.languageCode,
                            activeColor: const Color(0xFF007A87),
                            // ignore: deprecated_member_use
                            onChanged: (val) async {
                              if (val != null) {
                                await ref
                                    .read(languageProvider.notifier)
                                    .setLanguageCode(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
