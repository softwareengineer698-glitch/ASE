import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  urdu,
}

extension AppLanguageExtension on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.urdu:
        return 'اردو';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.urdu:
        return 'ur';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en', 'US');
      case AppLanguage.urdu:
        return const Locale('ur', 'PK');
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

  Future<void> _loadSavedLanguage() async {
    // Load saved language preferences
    // This would typically load from SharedPreferences
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    _saveLanguage();
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    // Save language preferences
    // This would typically save to SharedPreferences
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
    };

    return translations[_currentLanguage.code]?[key] ?? key;
  }
}
