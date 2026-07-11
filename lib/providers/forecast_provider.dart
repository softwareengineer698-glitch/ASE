import 'package:flutter/material.dart';
import '../models/forecast_model.dart';
import '../services/forecast_service.dart';
import '../services/enhanced_forecast_service.dart';

/// Provider for managing AI forecast state and data
/// Handles forecast generation, covariate updates, and alert management
class ForecastProvider extends ChangeNotifier {
  final ForecastService _forecastService = ForecastService();
  final EnhancedForecastService _enhancedService = EnhancedForecastService();

  AIForecast? _currentForecast;
  ForecastCovariates? _currentCovariates;
  bool _isLoading = false;
  String? _error;
  bool _useEnhancedService = true; // Toggle between services
  String _selectedModel = 'ARIMA'; // Default forecasting model

  // Getters
  AIForecast? get currentForecast => _currentForecast;
  ForecastCovariates? get currentCovariates => _currentCovariates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasForecast => _currentForecast != null;
  bool get useEnhancedService => _useEnhancedService;
  String get selectedModel => _selectedModel;

  /// Update model type and reload
  Future<void> updateModelType(String donorId, String model) async {
    if (_selectedModel == model) return;
    _selectedModel = model;
    await loadForecast(donorId);
  }

  /// Change enhanced service activation status
  Future<void> setUseEnhancedService(String donorId, bool value) async {
    if (_useEnhancedService == value) return;
    _useEnhancedService = value;
    await loadForecast(donorId);
  }

  /// Load forecast for a donor
  Future<void> loadForecast(String donorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current covariates if not set
      _currentCovariates ??= _forecastService.getCurrentCovariates();

      // Generate forecast using enhanced service if available
      if (_useEnhancedService) {
        // Generate mock historical data for enhanced service
        final historicalData = _generateMockHistoricalData();

        if (_selectedModel == 'ARIMA') {
          _currentForecast = await _enhancedService.generateARIMAForecast(
            donorId,
            historicalData,
            _currentCovariates!,
          );
        } else if (_selectedModel == 'NeuralProphet') {
          _currentForecast =
              await _enhancedService.generateNeuralProphetForecast(
            donorId,
            historicalData,
            _currentCovariates!,
          );
        } else {
          _currentForecast = await _enhancedService.generateProphetForecast(
            donorId,
            historicalData,
            _currentCovariates!,
          );
        }
      } else {
        // Fallback to original service
        _currentForecast = await _forecastService.generateForecast(
          donorId,
          _currentCovariates!,
        );
      }
    } catch (e) {
      // If enhanced service fails, try fallback
      if (_useEnhancedService) {
        try {
          _currentForecast = await _forecastService.generateForecast(
            donorId,
            _currentCovariates!,
          );
        } catch (fallbackError) {
          _error = 'Failed to load forecast: $fallbackError';
          print('Error loading forecast: $fallbackError');
        }
      } else {
        _error = 'Failed to load forecast: $e';
        print('Error loading forecast: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update covariates and regenerate forecast
  Future<void> updateCovariates(
    String donorId,
    ForecastCovariates newCovariates,
  ) async {
    if (_currentCovariates == newCovariates) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCovariates = newCovariates;
      _currentForecast = await _forecastService.updateForecastCovariates(
        _currentForecast ?? AIForecast.empty(),
        newCovariates,
        donorId,
      );
    } catch (e) {
      _error = 'Failed to update forecast: $e';
      print('Error updating forecast: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle holiday covariate
  Future<void> toggleHoliday(String donorId) async {
    if (_currentCovariates == null) return;

    final newCovariates = ForecastCovariates(
      isHoliday: !_currentCovariates!.isHoliday,
      isWeekend: _currentCovariates!.isWeekend,
      weather: _currentCovariates!.weather,
      localEvents: _currentCovariates!.localEvents,
      season: _currentCovariates!.season,
      economicIndex: _currentCovariates!.economicIndex,
    );

    await updateCovariates(donorId, newCovariates);
  }

  /// Update weather covariate
  Future<void> updateWeather(String donorId, WeatherCondition weather) async {
    if (_currentCovariates == null) return;

    final newCovariates = ForecastCovariates(
      isHoliday: _currentCovariates!.isHoliday,
      isWeekend: _currentCovariates!.isWeekend,
      weather: weather,
      localEvents: _currentCovariates!.localEvents,
      season: _currentCovariates!.season,
      economicIndex: _currentCovariates!.economicIndex,
    );

    await updateCovariates(donorId, newCovariates);
  }

  /// Add local event
  Future<void> addLocalEvent(String donorId, String event) async {
    if (_currentCovariates == null) return;

    final newEvents = List<String>.from(_currentCovariates!.localEvents);
    if (!newEvents.contains(event)) {
      newEvents.add(event);

      final newCovariates = ForecastCovariates(
        isHoliday: _currentCovariates!.isHoliday,
        isWeekend: _currentCovariates!.isWeekend,
        weather: _currentCovariates!.weather,
        localEvents: newEvents,
        season: _currentCovariates!.season,
        economicIndex: _currentCovariates!.economicIndex,
      );

      await updateCovariates(donorId, newCovariates);
    }
  }

  /// Remove local event
  Future<void> removeLocalEvent(String donorId, String event) async {
    if (_currentCovariates == null) return;

    final newEvents = List<String>.from(_currentCovariates!.localEvents);
    if (newEvents.remove(event)) {
      final newCovariates = ForecastCovariates(
        isHoliday: _currentCovariates!.isHoliday,
        isWeekend: _currentCovariates!.isWeekend,
        weather: _currentCovariates!.weather,
        localEvents: newEvents,
        season: _currentCovariates!.season,
        economicIndex: _currentCovariates!.economicIndex,
      );

      await updateCovariates(donorId, newCovariates);
    }
  }

  /// Mark alert as read
  void markAlertAsRead(String alertId) {
    if (_currentForecast == null) return;

    final updatedAlerts = _currentForecast!.alerts.map((alert) {
      if (alert.id == alertId) {
        return SurplusAlert(
          id: alert.id,
          date: alert.date,
          severity: alert.severity,
          title: alert.title,
          message: alert.message,
          recommendations: alert.recommendations,
          isRead: true,
        );
      }
      return alert;
    }).toList();

    _currentForecast = AIForecast(
      weeklyForecast: _currentForecast!.weeklyForecast,
      monthlyForecast: _currentForecast!.monthlyForecast,
      alerts: updatedAlerts,
      insights: _currentForecast!.insights,
      covariates: _currentForecast!.covariates,
      lastUpdated: _currentForecast!.lastUpdated,
      modelAccuracy: _currentForecast!.modelAccuracy,
    );

    notifyListeners();
  }

  /// Get unread alerts count
  int get unreadAlertsCount {
    if (_currentForecast == null) return 0;
    return _currentForecast!.alerts.where((alert) => !alert.isRead).length;
  }

  /// Get high priority alerts (high and critical)
  List<SurplusAlert> get highPriorityAlerts {
    if (_currentForecast == null) return [];
    return _currentForecast!.alerts
        .where((alert) =>
            alert.severity == SurplusRiskLevel.high ||
            alert.severity == SurplusRiskLevel.critical)
        .toList();
  }

  /// Get today's forecast point
  ForecastPoint? get todaysForecast {
    if (_currentForecast == null) return null;

    final today = DateTime.now();
    try {
      return _currentForecast!.weeklyForecast.firstWhere((point) =>
          point.date.day == today.day &&
          point.date.month == today.month &&
          point.date.year == today.year);
    } catch (e) {
      return null;
    }
  }

  /// Get tomorrow's forecast point
  ForecastPoint? get tomorrowsForecast {
    if (_currentForecast == null) return null;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    try {
      return _currentForecast!.weeklyForecast.firstWhere((point) =>
          point.date.day == tomorrow.day &&
          point.date.month == tomorrow.month &&
          point.date.year == tomorrow.year);
    } catch (e) {
      return null;
    }
  }

  /// Get weekly chart data for visualization
  List<Map<String, dynamic>> get weeklyChartData {
    if (_currentForecast == null) return [];

    return _currentForecast!.weeklyForecast
        .map((point) => {
              'date': point.formattedDate,
              'surplus': point.predictedSurplus,
              'confidence': point.confidence,
              'riskLevel': point.riskLevel.name,
              'color': point.riskLevel.colorValue,
            })
        .toList();
  }

  /// Get monthly chart data for visualization
  List<Map<String, dynamic>> get monthlyChartData {
    if (_currentForecast == null) return [];

    return _currentForecast!.monthlyForecast
        .asMap()
        .entries
        .map((entry) => {
              'week': 'Week ${entry.key + 1}',
              'surplus': entry.value.predictedSurplus,
              'confidence': entry.value.confidence,
              'riskLevel': entry.value.riskLevel.name,
              'color': entry.value.riskLevel.colorValue,
            })
        .toList();
  }

  /// Get category breakdown for current week
  Map<String, double> get weeklyCategoryBreakdown {
    if (_currentForecast == null) return {};

    final breakdown = <String, double>{};

    for (final point in _currentForecast!.weeklyForecast) {
      for (final entry in point.categoryBreakdown.entries) {
        breakdown[entry.key] = (breakdown[entry.key] ?? 0) + entry.value;
      }
    }

    return breakdown;
  }

  /// Refresh forecast data
  Future<void> refreshForecast(String donorId) async {
    _currentCovariates = _forecastService.getCurrentCovariates();
    await loadForecast(donorId);
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get forecast summary for quick display
  Map<String, dynamic> getForecastSummary() {
    if (_currentForecast == null) {
      return {
        'totalWeeklySurplus': 0.0,
        'averageDailySurplus': 0.0,
        'highRiskDays': 0,
        'modelAccuracy': 0.0,
        'lastUpdated': 'Never',
      };
    }

    final totalWeekly = _currentForecast!.weeklyForecast
        .fold<double>(0, (sum, point) => sum + point.predictedSurplus);

    final highRiskDays = _currentForecast!.weeklyForecast
        .where((point) =>
            point.riskLevel == SurplusRiskLevel.high ||
            point.riskLevel == SurplusRiskLevel.critical)
        .length;

    return {
      'totalWeeklySurplus': totalWeekly,
      'averageDailySurplus': totalWeekly / 7,
      'highRiskDays': highRiskDays,
      'modelAccuracy': _currentForecast!.modelAccuracy,
      'lastUpdated': _formatLastUpdated(_currentForecast!.lastUpdated),
    };
  }

  /// Format last updated time
  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Generate mock historical data for enhanced service
  List<Map<String, dynamic>> _generateMockHistoricalData() {
    final now = DateTime.now();
    final historicalData = <Map<String, dynamic>>[];

    // Generate 365 days of historical data
    for (int i = 365; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final baseSurplus = 10.0 + (i % 30) * 0.5; // Seasonal pattern

      // Add some randomness
      final surplus = baseSurplus + (DateTime.now().millisecond % 10 - 5);

      historicalData.add({
        'date': date.toIso8601String(),
        'surplus': surplus,
        'category': 'Mixed',
        'confidence': 0.8 + (DateTime.now().millisecond % 20) / 100,
      });
    }

    return historicalData;
  }

  /// Toggle between enhanced and fallback service
  void toggleServiceMode() {
    _useEnhancedService = !_useEnhancedService;
    notifyListeners();
  }

  /// Get current service mode
  String get serviceMode => _useEnhancedService ? 'Enhanced AI' : 'Standard';
}
