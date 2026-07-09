import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  urdu,
  romanUrdu,
}

extension AppLanguageExtension on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.urdu:
        return 'اردو';
      case AppLanguage.romanUrdu:
        return 'Roman Urdu';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.urdu:
        return 'ur';
      case AppLanguage.romanUrdu:
        return 'ru';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.urdu:
        return const Locale('ur');
      case AppLanguage.romanUrdu:
        return const Locale('ru');
    }
  }
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  bool _isLoading = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  Locale get currentLocale => _currentLanguage.locale;

  Future<void> initialize() async {
    await _loadSavedLanguage();
  }

  // Initialize with EasyLocalization context
  Future<void> initializeWithContext(BuildContext context) async {
    await _loadSavedLanguage();
    // Sync with EasyLocalization
    await context.setLocale(_currentLanguage.locale);
    notifyListeners();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('app_language') ?? 'en';

      if (savedLanguageCode == 'ru') {
        _currentLanguage = AppLanguage.romanUrdu;
      } else if (savedLanguageCode == 'ur') {
        _currentLanguage = AppLanguage.urdu;
      } else {
        _currentLanguage = AppLanguage.english;
      }

      debugPrint('Loaded saved language: ${_currentLanguage.code}');
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      _currentLanguage = AppLanguage.english;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language, BuildContext context) async {
    if (_currentLanguage == language) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Update the current language
      _currentLanguage = language;

      // Save to SharedPreferences
      await _saveLanguage();

      // Change EasyLocalization locale - this is the key part
      await context.setLocale(language.locale);

      // Force a complete app rebuild
      _isLoading = false;
      notifyListeners();

      // Additional rebuild to ensure all widgets refresh
      if (context.mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            notifyListeners();
          }
        });
      }

      debugPrint('Language changed to: ${language.code}');
    } catch (e) {
      debugPrint('Error setting language: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', _currentLanguage.code);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  List<AppLanguage> get availableLanguages => AppLanguage.values;

  // Translation helper method
  String translate(String key) {
    // This is a simple implementation - in a real app you'd use
    // a proper localization system like flutter_localizations
    final translations = {
      'en': {
        'home': 'Home',
        'profile': 'Profile',
        'settings': 'Settings',
        'notifications': 'Notifications',
        'surplus': 'Surplus',
        'pickups': 'Pickups',
        'dashboard': 'Dashboard',
        'edit_profile': 'Edit Profile',
        'save_changes': 'Save Changes',
        'cancel': 'Cancel',
        'language': 'Language',
        'theme': 'Theme',
        'logout': 'Logout',
      },
      'ur': {
        'home': 'گھر',
        'profile': 'پروفائل',
        'settings': 'ترتیبات',
        'notifications': 'اطلاعات',
        'surplus': 'اضافی خوراک',
        'pickups': 'پک اپ',
        'dashboard': 'ڈیش بورڈ',
        'edit_profile': 'پروفائل میں تبدیلی',
        'save_changes': 'تبدیلیاں محفوظ کریں',
        'cancel': 'منسوخ',
        'language': 'زبان',
        'theme': 'تھیم',
        'logout': 'لاگ آؤٹ',
      },
      'ru': {
        'home': 'Ghar',
        'profile': 'Profile',
        'settings': 'Settings',
        'notifications': 'Notifications',
        'surplus': 'Izafi Khurak',
        'pickups': 'Pickups',
        'dashboard': 'Dashboard',
        'edit_profile': 'Profile Update Karein',
        'save_changes': 'Tabdeeliyan Mehfooz Karein',
        'cancel': 'Mansookh Karein',
        'language': 'Zuban',
        'theme': 'Theme',
        'logout': 'Logout',
      },
    };

    return translations[_currentLanguage.code]?[key] ?? key;
  }
}
