import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeVariant {
  white,
  blue,
  green,
  maroon,
  pink,
  purple,
  orange,
}

extension ThemeVariantExtension on ThemeVariant {
  String get displayName {
    switch (this) {
      case ThemeVariant.white:
        return 'Classic White';
      case ThemeVariant.blue:
        return 'Ocean Blue';
      case ThemeVariant.green:
        return 'Nature Green';
      case ThemeVariant.maroon:
        return 'Rich Maroon';
      case ThemeVariant.pink:
        return 'Soft Pink';
      case ThemeVariant.purple:
        return 'Royal Purple';
      case ThemeVariant.orange:
        return 'Sunset Orange';
    }
  }

  Color get primaryColor {
    switch (this) {
      case ThemeVariant.white:
        return const Color(0xFF2196F3);
      case ThemeVariant.blue:
        return const Color(0xFF2196F3);
      case ThemeVariant.green:
        return const Color(0xFF4CAF50);
      case ThemeVariant.maroon:
        return const Color(0xFF8B0000);
      case ThemeVariant.pink:
        return const Color(0xFFE91E63);
      case ThemeVariant.purple:
        return const Color(0xFF9C27B0);
      case ThemeVariant.orange:
        return const Color(0xFFFF9800);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeVariant _currentVariant = ThemeVariant.white;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;

  ThemeVariant get currentVariant => _currentVariant;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String get currentTheme => _currentVariant.name;

  ThemeData get lightTheme => _generateThemeData(Brightness.light);
  ThemeData get darkTheme => _generateThemeData(Brightness.dark);

  Color get primaryColor => _currentVariant.primaryColor;

  List<Map<String, dynamic>> get availableThemes {
    return ThemeVariant.values
        .map((variant) => {
              'name': variant.name,
              'displayName': variant.displayName,
              'primaryColor': variant.primaryColor,
            })
        .toList();
  }

  List<Map<String, dynamic>> get availableThemeModes {
    return [
      {
        'value': ThemeMode.light,
        'name': 'Light Appearance',
        'icon': Icons.brightness_7,
      },
      {
        'value': ThemeMode.dark,
        'name': 'Dark Appearance',
        'icon': Icons.brightness_2,
      },
      {
        'value': ThemeMode.system,
        'name': 'System Default',
        'icon': Icons.brightness_auto,
      },
    ];
  }

  Future<void> initialize() async {
    await _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme variant
      final savedVariant = prefs.getString('theme_variant');
      if (savedVariant != null) {
        final variant = ThemeVariant.values.firstWhere(
          (v) => v.name == savedVariant,
          orElse: () => ThemeVariant.white,
        );
        _currentVariant = variant;
      }

      // Load theme mode
      final savedMode = prefs.getString('theme_mode');
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  void setThemeVariant(ThemeVariant variant) {
    _currentVariant = variant;
    _savePreferences();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_variant', _currentVariant.name);
      await prefs.setString('theme_mode', _themeMode.name);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  void resetTheme() {
    _currentVariant = ThemeVariant.white;
    _themeMode = ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  List<ThemeVariant> get availableVariants => ThemeVariant.values;

  ThemeData _generateThemeData(Brightness brightness) {
    final primaryColor = _currentVariant.primaryColor;
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isLight ? Colors.white : const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isLight ? Colors.white : const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
        elevation: 8,
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
