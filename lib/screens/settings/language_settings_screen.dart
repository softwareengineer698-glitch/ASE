import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

/// Language settings screen for switching between English and Urdu
/// Supports RTL layout for Urdu language
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('language_settings'.tr()),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'choose_language'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Language Options
                ...AppLanguage.values
                    .map((language) => _buildLanguageOption(
                        language, languageProvider, themeProvider))
                    .toList(),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Language changes will apply immediately across the entire app.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(AppLanguage language,
      LanguageProvider languageProvider, ThemeProvider themeProvider) {
    final isSelected = languageProvider.currentLanguage == language;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          child: Text(
            language == AppLanguage.english ? '🇺🇸' : '🇵🇰',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          language.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: Text(
          language == AppLanguage.english ? 'English' : 'اردو',
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue : Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
        onTap: languageProvider.isLoading
            ? null
            : () async {
                await languageProvider.setLanguage(language, context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == AppLanguage.urdu
                            ? 'زبان اردو میں تبدیل ہو گئی'
                            : 'Language changed to English',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
      ),
    );
  }
}
