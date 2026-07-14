import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app localization and language preferences
/// Supports English and Urdu languages with RTL support
class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  String _currentLanguage = _defaultLanguage;
  late Map<String, Map<String, String>> _localizedStrings;

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isUrdu => _currentLanguage == 'ur';
  bool get isRTL => _currentLanguage == 'ur';
  Locale get currentLocale => Locale(_currentLanguage);

  /// Initialize localization service
  Future<void> initialize() async {
    await _loadLanguagePreference();
    _initializeStrings();
  }

  /// Load saved language preference
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      _currentLanguage = _defaultLanguage;
    }
  }

  /// Save language preference
  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLanguage);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await _saveLanguagePreference();
      notifyListeners();
    }
  }

  /// Get localized string
  String getString(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings[_defaultLanguage]?[key] ??
        key;
  }

  /// Get available languages
  List<LanguageOption> getAvailableLanguages() {
    return [
      const LanguageOption(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
      ),
      const LanguageOption(
        code: 'ur',
        name: 'Urdu',
        nativeName: 'اردو',
        flag: '🇵🇰',
      ),
    ];
  }

  /// Initialize localized strings
  void _initializeStrings() {
    _localizedStrings = {
      'en': _englishStrings,
      'ur': _urduStrings,
    };
  }

  /// English strings
  static const Map<String, String> _englishStrings = {
    // App General
    'app_name': 'CareCircle',
    'welcome': 'Welcome',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'cancel': 'Cancel',
    'ok': 'OK',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'filter': 'Filter',
    'refresh': 'Refresh',
    'retry': 'Retry',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'previous': 'Previous',
    'done': 'Done',
    'continue': 'Continue',

    // Navigation
    'home': 'Home',
    'history': 'History',
    'notifications': 'Notifications',
    'profile': 'Profile',
    'settings': 'Settings',
    'dashboard': 'Dashboard',

    // Authentication
    'login': 'Login',
    'logout': 'Logout',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password?',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'sign_out': 'Sign Out',

    // User Roles
    'donor': 'Donor',
    'ngo': 'NGO',
    'admin': 'Admin',
    'user_type': 'User Type',

    // Food & Donations
    'food': 'Food',
    'donation': 'Donation',
    'surplus': 'Surplus',
    'quantity': 'Quantity',
    'category': 'Category',
    'expiry_date': 'Expiry Date',
    'pickup_time': 'Pickup Time',
    'delivery_time': 'Delivery Time',
    'location': 'Location',
    'address': 'Address',
    'description': 'Description',
    'notes': 'Notes',

    // Food Categories
    'vegetables': 'Vegetables',
    'fruits': 'Fruits',
    'grains': 'Grains',
    'dairy': 'Dairy',
    'meat': 'Meat',
    'bakery': 'Bakery',
    'prepared_food': 'Prepared Food',
    'beverages': 'Beverages',

    // Status
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'completed': 'Completed',
    'in_progress': 'In Progress',
    'cancelled': 'Cancelled',
    'expired': 'Expired',

    // Analytics
    'analytics': 'Analytics',
    'reports': 'Reports',
    'statistics': 'Statistics',
    'total_donations': 'Total Donations',
    'total_pickups': 'Total Pickups',
    'impact_score': 'Impact Score',
    'leaderboard': 'Leaderboard',
    'ranking': 'Ranking',
    'achievements': 'Achievements',

    // Notifications
    'new_surplus_available': 'New Surplus Available',
    'pickup_confirmed': 'Pickup Confirmed',
    'delivery_completed': 'Delivery Completed',
    'achievement_unlocked': 'Achievement Unlocked',
    'mark_all_read': 'Mark All as Read',
    'clear_all': 'Clear All',

    // Settings
    'language': 'Language',
    'theme': 'Theme',
    'dark_mode': 'Dark Mode',
    'light_mode': 'Light Mode',
    'notification_settings': 'Notification Settings',
    'privacy': 'Privacy',
    'terms_conditions': 'Terms & Conditions',
    'about': 'About',
    'help': 'Help',
    'contact_us': 'Contact Us',

    // Delivery Confirmation
    'delivery_confirmation': 'Delivery Confirmation',
    'photo_upload': 'Photo Upload',
    'digital_signature': 'Digital Signature',
    'confirm_delivery': 'Confirm Delivery',
    'delivery_verified': 'Delivery Verified',

    // NGO Verification
    'ngo_verification': 'NGO Verification',
    'document_upload': 'Document Upload',
    'verification_pending': 'Verification Pending',
    'verification_approved': 'Verification Approved',
    'verification_rejected': 'Verification Rejected',

    // Forecast
    'ai_forecast': 'AI Forecast',
    'surplus_prediction': 'Surplus Prediction',
    'demand_forecast': 'Demand Forecast',
    'risk_level': 'Risk Level',
    'confidence': 'Confidence',

    // Messages
    'no_data_available': 'No data available',
    'empty_list': 'List is empty',
    'network_error': 'Network error occurred',
    'try_again': 'Please try again',
    'operation_successful': 'Operation completed successfully',
    'operation_failed': 'Operation failed',

    // Time
    'today': 'Today',
    'yesterday': 'Yesterday',
    'tomorrow': 'Tomorrow',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'last_week': 'Last Week',
    'last_month': 'Last Month',

    // Units
    'kg': 'kg',
    'grams': 'grams',
    'liters': 'liters',
    'pieces': 'pieces',
    'boxes': 'boxes',
  };

  /// Urdu strings
  static const Map<String, String> _urduStrings = {
    // App General
    'app_name': 'فوڈ برج',
    'welcome': 'خوش آمدید',
    'loading': 'لوڈ ہو رہا ہے...',
    'error': 'خرابی',
    'success': 'کامیابی',
    'cancel': 'منسوخ',
    'ok': 'ٹھیک ہے',
    'save': 'محفوظ کریں',
    'delete': 'حذف کریں',
    'edit': 'ترمیم',
    'add': 'شامل کریں',
    'search': 'تلاش',
    'filter': 'فلٹر',
    'refresh': 'تازہ کریں',
    'retry': 'دوبارہ کوشش',
    'close': 'بند کریں',
    'back': 'واپس',
    'next': 'اگلا',
    'previous': 'پچھلا',
    'done': 'مکمل',
    'continue': 'جاری رکھیں',

    // Navigation
    'home': 'ہوم',
    'history': 'تاریخ',
    'notifications': 'اطلاعات',
    'profile': 'پروفائل',
    'settings': 'ترتیبات',
    'dashboard': 'ڈیش بورڈ',

    // Authentication
    'login': 'لاگ ان',
    'logout': 'لاگ آؤٹ',
    'register': 'رجسٹر',
    'email': 'ای میل',
    'password': 'پاس ورڈ',
    'confirm_password': 'پاس ورڈ کی تصدیق',
    'forgot_password': 'پاس ورڈ بھول گئے؟',
    'sign_in': 'سائن ان',
    'sign_up': 'سائن اپ',
    'sign_out': 'سائن آؤٹ',

    // User Roles
    'donor': 'عطیہ دہندہ',
    'ngo': 'این جی او',
    'admin': 'ایڈمن',
    'user_type': 'صارف کی قسم',

    // Food & Donations
    'food': 'کھانا',
    'donation': 'عطیہ',
    'surplus': 'اضافی',
    'quantity': 'مقدار',
    'category': 'قسم',
    'expiry_date': 'ختم ہونے کی تاریخ',
    'pickup_time': 'اٹھانے کا وقت',
    'delivery_time': 'ڈیلیوری کا وقت',
    'location': 'مقام',
    'address': 'پتہ',
    'description': 'تفصیل',
    'notes': 'نوٹس',

    // Food Categories
    'vegetables': 'سبزیاں',
    'fruits': 'پھل',
    'grains': 'اناج',
    'dairy': 'دودھ کی مصنوعات',
    'meat': 'گوشت',
    'bakery': 'بیکری',
    'prepared_food': 'تیار کھانا',
    'beverages': 'مشروبات',

    // Status
    'pending': 'زیر التواء',
    'approved': 'منظور',
    'rejected': 'مسترد',
    'completed': 'مکمل',
    'in_progress': 'جاری',
    'cancelled': 'منسوخ',
    'expired': 'ختم',

    // Analytics
    'analytics': 'تجزیات',
    'reports': 'رپورٹس',
    'statistics': 'اعدادوشمار',
    'total_donations': 'کل عطیات',
    'total_pickups': 'کل پک اپس',
    'impact_score': 'اثرات کا سکور',
    'leaderboard': 'لیڈر بورڈ',
    'ranking': 'درجہ بندی',
    'achievements': 'کامیابیاں',

    // Notifications
    'new_surplus_available': 'نیا اضافی کھانا دستیاب',
    'pickup_confirmed': 'پک اپ کی تصدیق',
    'delivery_completed': 'ڈیلیوری مکمل',
    'achievement_unlocked': 'کامیابی حاصل',
    'mark_all_read': 'سب کو پڑھا ہوا نشان لگائیں',
    'clear_all': 'سب صاف کریں',

    // Settings
    'language': 'زبان',
    'theme': 'تھیم',
    'dark_mode': 'ڈارک موڈ',
    'light_mode': 'لائٹ موڈ',
    'notification_settings': 'اطلاعات کی ترتیبات',
    'privacy': 'رازداری',
    'terms_conditions': 'شرائط و ضوابط',
    'about': 'کے بارے میں',
    'help': 'مدد',
    'contact_us': 'ہم سے رابطہ',

    // Delivery Confirmation
    'delivery_confirmation': 'ڈیلیوری کی تصدیق',
    'photo_upload': 'تصویر اپ لوڈ',
    'digital_signature': 'ڈیجیٹل دستخط',
    'confirm_delivery': 'ڈیلیوری کی تصدیق کریں',
    'delivery_verified': 'ڈیلیوری کی تصدیق ہو گئی',

    // NGO Verification
    'ngo_verification': 'این جی او کی تصدیق',
    'document_upload': 'دستاویز اپ لوڈ',
    'verification_pending': 'تصدیق زیر التواء',
    'verification_approved': 'تصدیق منظور',
    'verification_rejected': 'تصدیق مسترد',

    // Forecast
    'ai_forecast': 'اے آئی پیشن گوئی',
    'surplus_prediction': 'اضافی کھانے کی پیشن گوئی',
    'demand_forecast': 'طلب کی پیشن گوئی',
    'risk_level': 'خطرے کی سطح',
    'confidence': 'اعتماد',

    // Messages
    'no_data_available': 'کوئی ڈیٹا دستیاب نہیں',
    'empty_list': 'فہرست خالی ہے',
    'network_error': 'نیٹ ورک کی خرابی',
    'try_again': 'دوبارہ کوشش کریں',
    'operation_successful': 'کارروائی کامیابی سے مکمل',
    'operation_failed': 'کارروائی ناکام',

    // Time
    'today': 'آج',
    'yesterday': 'کل',
    'tomorrow': 'کل',
    'this_week': 'اس ہفتے',
    'this_month': 'اس مہینے',
    'last_week': 'پچھلے ہفتے',
    'last_month': 'پچھلے مہینے',

    // Units
    'kg': 'کلو',
    'grams': 'گرام',
    'liters': 'لیٹر',
    'pieces': 'ٹکڑے',
    'boxes': 'ڈبے',
  };
}

/// Language option model
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
