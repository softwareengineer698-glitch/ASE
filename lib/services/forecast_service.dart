import 'dart:math';
import '../models/forecast_model.dart';

/// Service for generating AI-powered surplus forecasts
/// Simulates machine learning predictions for food surplus patterns
class ForecastService {
  static const List<String> _foodCategories = [
    'Fruits', 'Vegetables', 'Grains', 'Dairy', 'Prepared Food', 'Bakery'
  ];

  static const List<String> _contributingFactors = [
    'Seasonal demand patterns',
    'Holiday shopping trends',
    'Weather conditions',
    'Local events',
    'Economic factors',
    'Supply chain disruptions',
    'Consumer behavior changes',
  ];

  /// Generate comprehensive AI forecast for a donor
  Future<AIForecast> generateForecast(
    String donorId,
    ForecastCovariates covariates,
  ) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final now = DateTime.now();
    final random = Random();

    // Generate weekly forecast (next 7 days)
    final weeklyForecast = <ForecastPoint>[];
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      weeklyForecast.add(_generateForecastPoint(date, covariates, random));
    }

    // Generate monthly forecast (next 30 days, weekly aggregates)
    final monthlyForecast = <ForecastPoint>[];
    for (int week = 1; week <= 4; week++) {
      final weekStart = now.add(Duration(days: week * 7));
      monthlyForecast.add(_generateForecastPoint(weekStart, covariates, random, isWeekly: true));
    }

    // Generate alerts based on forecast
    final alerts = _generateAlerts(weeklyForecast, random);

    // Generate insights
    final insights = _generateInsights(weeklyForecast, monthlyForecast, covariates);

    // Calculate model accuracy (simulated)
    final modelAccuracy = 0.78 + random.nextDouble() * 0.15; // 78-93% accuracy

    return AIForecast(
      weeklyForecast: weeklyForecast,
      monthlyForecast: monthlyForecast,
      alerts: alerts,
      insights: insights,
      covariates: covariates.toMap(),
      lastUpdated: now,
      modelAccuracy: modelAccuracy,
    );
  }

  /// Generate forecast point for a specific date
  ForecastPoint _generateForecastPoint(
    DateTime date,
    ForecastCovariates covariates,
    Random random, {
    bool isWeekly = false,
  }) {
    // Base surplus prediction (kg)
    double baseSurplus = isWeekly ? 25.0 + random.nextDouble() * 50 : 5.0 + random.nextDouble() * 15;

    // Apply covariate effects
    if (covariates.isHoliday) baseSurplus *= 1.4; // 40% more on holidays
    if (covariates.isWeekend) baseSurplus *= 1.2; // 20% more on weekends
    if (covariates.weather == WeatherCondition.rainy) baseSurplus *= 0.8; // 20% less in rain
    if (covariates.localEvents.isNotEmpty) baseSurplus *= 1.3; // 30% more during events

    // Add seasonal effects
    switch (covariates.season) {
      case SeasonType.winter:
        baseSurplus *= 1.1; // More surplus in winter
        break;
      case SeasonType.summer:
        baseSurplus *= 0.9; // Less surplus in summer
        break;
      default:
        break;
    }

    // Determine risk level
    SurplusRiskLevel riskLevel;
    if (baseSurplus > 40) {
      riskLevel = SurplusRiskLevel.critical;
    } else if (baseSurplus > 25) {
      riskLevel = SurplusRiskLevel.high;
    } else if (baseSurplus > 15) {
      riskLevel = SurplusRiskLevel.medium;
    } else {
      riskLevel = SurplusRiskLevel.low;
    }

    // Generate confidence (higher for nearer dates)
    final daysFromNow = date.difference(DateTime.now()).inDays;
    final confidence = (0.95 - (daysFromNow * 0.05)).clamp(0.6, 0.95);

    // Select contributing factors
    final factors = <String>[];
    factors.addAll(_contributingFactors.take(2 + random.nextInt(3)));

    // Generate category breakdown
    final categoryBreakdown = <String, double>{};
    double remaining = baseSurplus;
    for (int i = 0; i < _foodCategories.length - 1; i++) {
      final portion = remaining * (0.1 + random.nextDouble() * 0.3);
      categoryBreakdown[_foodCategories[i]] = portion;
      remaining -= portion;
    }
    categoryBreakdown[_foodCategories.last] = remaining.clamp(0, double.infinity);

    return ForecastPoint(
      date: date,
      predictedSurplus: baseSurplus,
      confidence: confidence,
      riskLevel: riskLevel,
      contributingFactors: factors,
      categoryBreakdown: categoryBreakdown,
    );
  }

  /// Generate surplus alerts based on forecast
  List<SurplusAlert> _generateAlerts(List<ForecastPoint> forecast, Random random) {
    final alerts = <SurplusAlert>[];
    
    for (int i = 0; i < forecast.length; i++) {
      final point = forecast[i];
      
      // Generate alerts for high and critical risk days
      if (point.riskLevel == SurplusRiskLevel.high || point.riskLevel == SurplusRiskLevel.critical) {
        alerts.add(SurplusAlert(
          id: 'alert_${i}_${point.date.millisecondsSinceEpoch}',
          date: point.date,
          severity: point.riskLevel,
          title: point.riskLevel == SurplusRiskLevel.critical 
            ? 'Critical Surplus Alert' 
            : 'High Surplus Warning',
          message: 'Predicted ${point.predictedSurplus.toStringAsFixed(1)}kg surplus on ${point.formattedDate}',
          recommendations: _getRecommendations(point.riskLevel),
          isRead: false,
        ));
      }
    }

    return alerts;
  }

  /// Generate AI insights from forecast data
  ForecastInsights _generateInsights(
    List<ForecastPoint> weekly,
    List<ForecastPoint> monthly,
    ForecastCovariates covariates,
  ) {
    final totalWeeklySurplus = weekly.fold<double>(0, (sum, point) => sum + point.predictedSurplus);
    final avgDailySurplus = totalWeeklySurplus / 7;
    
    // Primary insight
    String primaryInsight;
    if (avgDailySurplus > 20) {
      primaryInsight = 'High surplus period ahead. Consider increasing donation frequency.';
    } else if (avgDailySurplus > 10) {
      primaryInsight = 'Moderate surplus expected. Good time for planned donations.';
    } else {
      primaryInsight = 'Low surplus period. Focus on efficient resource management.';
    }

    // Key trends
    final keyTrends = <String>[];
    if (covariates.isHoliday) {
      keyTrends.add('Holiday season increases surplus by 40%');
    }
    if (covariates.localEvents.isNotEmpty) {
      keyTrends.add('Local events boost surplus production');
    }
    keyTrends.add('${covariates.season.displayName} seasonal patterns detected');
    keyTrends.add('Weather impact: ${covariates.weather.displayName} conditions');

    // Recommendations
    final recommendations = <String>[];
    if (totalWeeklySurplus > 100) {
      recommendations.add('Schedule multiple donation pickups this week');
      recommendations.add('Contact additional NGO partners');
    } else {
      recommendations.add('Maintain regular donation schedule');
    }
    recommendations.add('Monitor ${_getHighestCategory(weekly)} category closely');

    // Waste reduction potential
    final wasteReductionPotential = totalWeeklySurplus * 0.85; // 85% can be saved through donations

    // Seasonal patterns
    final seasonalPatterns = <String, String>{
      covariates.season.displayName: _getSeasonalPattern(covariates.season),
      'Weather Impact': _getWeatherPattern(covariates.weather),
    };

    return ForecastInsights(
      primaryInsight: primaryInsight,
      keyTrends: keyTrends,
      recommendations: recommendations,
      wasteReductionPotential: wasteReductionPotential,
      seasonalPatterns: seasonalPatterns,
    );
  }

  /// Get recommendations based on risk level
  List<String> _getRecommendations(SurplusRiskLevel riskLevel) {
    switch (riskLevel) {
      case SurplusRiskLevel.critical:
        return [
          'Schedule immediate pickup with multiple NGOs',
          'Consider emergency food distribution',
          'Activate surplus alert network',
          'Implement immediate waste reduction measures',
        ];
      case SurplusRiskLevel.high:
        return [
          'Schedule additional pickup within 24 hours',
          'Contact backup NGO partners',
          'Prepare surplus for quick distribution',
          'Monitor situation closely',
        ];
      case SurplusRiskLevel.medium:
        return [
          'Plan pickup within 2-3 days',
          'Notify regular NGO partners',
          'Prepare donation packages',
        ];
      case SurplusRiskLevel.low:
        return [
          'Continue regular donation schedule',
          'Monitor for changes',
        ];
    }
  }

  /// Get highest surplus category from forecast
  String _getHighestCategory(List<ForecastPoint> forecast) {
    final categoryTotals = <String, double>{};
    
    for (final point in forecast) {
      for (final entry in point.categoryBreakdown.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get seasonal pattern description
  String _getSeasonalPattern(SeasonType season) {
    switch (season) {
      case SeasonType.winter:
        return 'Higher surplus due to holiday celebrations and reduced consumption';
      case SeasonType.spring:
        return 'Moderate surplus with fresh produce availability';
      case SeasonType.summer:
        return 'Lower surplus due to increased outdoor activities';
      case SeasonType.autumn:
        return 'Increasing surplus as harvest season approaches';
    }
  }

  /// Get weather pattern description
  String _getWeatherPattern(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.sunny:
        return 'Normal surplus patterns, good for outdoor donations';
      case WeatherCondition.cloudy:
        return 'Slight increase in indoor food preparation';
      case WeatherCondition.rainy:
        return 'Reduced surplus due to limited shopping and events';
      case WeatherCondition.stormy:
        return 'Significantly reduced surplus, focus on emergency supplies';
    }
  }

  /// Update forecast with new covariates
  Future<AIForecast> updateForecastCovariates(
    AIForecast currentForecast,
    ForecastCovariates newCovariates,
    String donorId,
  ) async {
    // Regenerate forecast with new covariates
    return generateForecast(donorId, newCovariates);
  }

  /// Get current covariates based on date and location
  ForecastCovariates getCurrentCovariates() {
    final now = DateTime.now();
    final random = Random();

    // Determine season
    SeasonType season;
    final month = now.month;
    if (month >= 3 && month <= 5) {
      season = SeasonType.spring;
    } else if (month >= 6 && month <= 8) {
      season = SeasonType.summer;
    } else if (month >= 9 && month <= 11) {
      season = SeasonType.autumn;
    } else {
      season = SeasonType.winter;
    }

    // Check if weekend
    final isWeekend = now.weekday >= 6;

    // Simulate holiday check (simplified)
    final isHoliday = _isHoliday(now);

    // Random weather (in real app, would use weather API)
    final weather = WeatherCondition.values[random.nextInt(WeatherCondition.values.length)];

    // Mock local events
    final localEvents = <String>[];
    if (random.nextBool()) {
      localEvents.add('Local Festival');
    }

    return ForecastCovariates(
      isHoliday: isHoliday,
      isWeekend: isWeekend,
      weather: weather,
      localEvents: localEvents,
      season: season,
      economicIndex: 0.8 + random.nextDouble() * 0.4, // 0.8 - 1.2
    );
  }

  /// Simple holiday detection (can be enhanced)
  bool _isHoliday(DateTime date) {
    // Major holidays (simplified)
    final holidays = [
      DateTime(date.year, 1, 1), // New Year
      DateTime(date.year, 12, 25), // Christmas
      DateTime(date.year, 8, 14), // Pakistan Independence Day
      DateTime(date.year, 3, 23), // Pakistan Day
    ];

    return holidays.any((holiday) => 
      date.day == holiday.day && date.month == holiday.month);
  }
}
