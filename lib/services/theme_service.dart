import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service class for managing theme persistence and configuration
/// Handles saving/loading theme preferences using SharedPreferences
class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _brightnessKey = 'app_brightness';
  
  /// Available theme variants
  static const List<String> availableThemes = [
    'blue',
    'green', 
    'maroon',
    'pink',
    'purple',
  ];

  /// Get saved theme variant (default: blue)
  Future<String> getThemeVariant() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'blue';
  }

  /// Save theme variant
  Future<void> saveThemeVariant(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  /// Get saved brightness mode (default: system)
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final brightnessString = prefs.getString(_brightnessKey) ?? 'system';
    
    switch (brightnessString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Save brightness mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        modeString = 'system';
        break;
    }
    
    await prefs.setString(_brightnessKey, modeString);
  }

  /// Clear all theme preferences (reset to defaults)
  Future<void> resetThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    await prefs.remove(_brightnessKey);
  }

  /// Check if theme variant is valid
  bool isValidTheme(String theme) {
    return availableThemes.contains(theme);
  }

  /// Get theme display name
  String getThemeDisplayName(String theme) {
    switch (theme) {
      case 'blue':
        return 'Ocean Blue';
      case 'green':
        return 'Nature Green';
      case 'maroon':
        return 'Rich Maroon';
      case 'pink':
        return 'Soft Pink';
      case 'purple':
        return 'Royal Purple';
      default:
        return 'Unknown Theme';
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }
}
