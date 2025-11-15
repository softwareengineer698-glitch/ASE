import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../providers/theme_provider.dart';

/// Language settings screen for switching between English and Urdu
/// Supports RTL layout for Urdu language
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late LocalizationService _localizationService;

  @override
  void initState() {
    super.initState();
    _localizationService = LocalizationService();
    _localizationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ChangeNotifierBuilder<LocalizationService>(
          notifier: _localizationService,
          builder: (context, localizationService) {
            return Directionality(
              textDirection: localizationService.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(localizationService.getString('language')),
                  leading: IconButton(
                    icon: Icon(localizationService.isRTL ? Icons.arrow_forward : Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(localizationService, themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Language Options
                      _buildLanguageOptions(localizationService, themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // RTL Demo
                      if (localizationService.isUrdu)
                        _buildRTLDemo(localizationService, themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Language Info
                      _buildLanguageInfo(localizationService, themeProvider),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCard(LocalizationService localizationService, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: themeProvider.primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizationService.getString('language'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your preferred language',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeProvider.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: themeProvider.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Language changes will apply immediately across the entire app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.primaryColor,
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
  }

  Widget _buildLanguageOptions(LocalizationService localizationService, ThemeProvider themeProvider) {
    final languages = localizationService.getAvailableLanguages();
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Languages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
          ),
          ...languages.map((language) => _buildLanguageOption(
            language,
            localizationService,
            themeProvider,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    LanguageOption language,
    LocalizationService localizationService,
    ThemeProvider themeProvider,
  ) {
    final isSelected = localizationService.currentLanguage == language.code;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected 
          ? themeProvider.primaryColor 
          : Colors.grey[300],
        child: Text(
          language.flag,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        language.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? themeProvider.primaryColor : null,
        ),
      ),
      subtitle: Text(
        language.nativeName,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? themeProvider.primaryColor : Colors.grey[600],
        ),
      ),
      trailing: isSelected 
        ? Icon(Icons.check_circle, color: themeProvider.primaryColor)
        : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
      onTap: () => _changeLanguage(language.code, localizationService),
    );
  }

  Widget _buildRTLDemo(LocalizationService localizationService, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_textdirection_r_to_l, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'RTL Layout Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اردو میں خوش آمدید!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'یہ ایپ اردو زبان میں دائیں سے بائیں (RTL) لے آؤٹ کا استعمال کرتا ہے۔',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageInfo(LocalizationService localizationService, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Language Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Current Language', _getCurrentLanguageName(localizationService)),
            _buildInfoRow('Text Direction', localizationService.isRTL ? 'Right to Left (RTL)' : 'Left to Right (LTR)'),
            _buildInfoRow('Supported Languages', '2 (English, Urdu)'),
            _buildInfoRow('Auto-save', 'Enabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguageName(LocalizationService localizationService) {
    final languages = localizationService.getAvailableLanguages();
    final current = languages.firstWhere(
      (lang) => lang.code == localizationService.currentLanguage,
      orElse: () => languages.first,
    );
    return '${current.name} (${current.nativeName})';
  }

  void _changeLanguage(String languageCode, LocalizationService localizationService) {
    localizationService.changeLanguage(languageCode);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          languageCode == 'ur' 
            ? 'زبان اردو میں تبدیل ہو گئی'
            : 'Language changed to English',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Helper widget for ChangeNotifier
class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  final T notifier;
  final Widget Function(BuildContext context, T notifier) builder;

  const ChangeNotifierBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  State<ChangeNotifierBuilder<T>> createState() => _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier> extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }
}
