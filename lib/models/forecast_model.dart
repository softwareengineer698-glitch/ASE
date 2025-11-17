class ForecastData {
  final DateTime date;
  final double demand;
  final String category;
  final double confidence;

  ForecastData({
    required this.date,
    required this.demand,
    required this.category,
    required this.confidence,
  });

  factory ForecastData.fromMap(Map<String, dynamic> map) {
    return ForecastData(
      date: DateTime.parse(map['date']),
      demand: map['demand']?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'demand': demand,
      'category': category,
      'confidence': confidence,
    };
  }
}

class ForecastSummary {
  final String category;
  final double totalDemand;
  final double averageDemand;
  final double peakDemand;
  final DateTime peakDate;
  final List<ForecastData> dailyForecasts;

  ForecastSummary({
    required this.category,
    required this.totalDemand,
    required this.averageDemand,
    required this.peakDemand,
    required this.peakDate,
    required this.dailyForecasts,
  });
}

/// Enhanced AI forecast model with comprehensive prediction data
class AIForecast {
  final List<ForecastPoint> weeklyForecast;
  final List<ForecastPoint> monthlyForecast;
  final List<SurplusAlert> alerts;
  final ForecastInsights insights;
  final Map<String, dynamic> covariates;
  final DateTime lastUpdated;
  final double modelAccuracy;

  const AIForecast({
    required this.weeklyForecast,
    required this.monthlyForecast,
    required this.alerts,
    required this.insights,
    required this.covariates,
    required this.lastUpdated,
    required this.modelAccuracy,
  });

  factory AIForecast.empty() {
    return AIForecast(
      weeklyForecast: [],
      monthlyForecast: [],
      alerts: [],
      insights: ForecastInsights.empty(),
      covariates: {},
      lastUpdated: DateTime.now(),
      modelAccuracy: 0.0,
    );
  }
}

/// Individual forecast data point with prediction details
class ForecastPoint {
  final DateTime date;
  final double predictedSurplus;
  final double confidence;
  final SurplusRiskLevel riskLevel;
  final List<String> contributingFactors;
  final Map<String, double> categoryBreakdown;

  const ForecastPoint({
    required this.date,
    required this.predictedSurplus,
    required this.confidence,
    required this.riskLevel,
    required this.contributingFactors,
    required this.categoryBreakdown,
  });

  String get formattedDate => '${date.day}/${date.month}';
  String get riskLevelText => riskLevel.displayName;
  String get confidenceText => '${(confidence * 100).toStringAsFixed(0)}%';
}

/// Surplus risk levels with color coding
enum SurplusRiskLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case SurplusRiskLevel.low:
        return 'Low Risk';
      case SurplusRiskLevel.medium:
        return 'Medium Risk';
      case SurplusRiskLevel.high:
        return 'High Risk';
      case SurplusRiskLevel.critical:
        return 'Critical Risk';
    }
  }

  int get colorValue {
    switch (this) {
      case SurplusRiskLevel.low:
        return 0xFF4CAF50; // Green
      case SurplusRiskLevel.medium:
        return 0xFFFF9800; // Orange
      case SurplusRiskLevel.high:
        return 0xFFF44336; // Red
      case SurplusRiskLevel.critical:
        return 0xFF9C27B0; // Purple
    }
  }
}

/// Alerts for upcoming surplus predictions
class SurplusAlert {
  final String id;
  final DateTime date;
  final SurplusRiskLevel severity;
  final String title;
  final String message;
  final List<String> recommendations;
  final bool isRead;

  const SurplusAlert({
    required this.id,
    required this.date,
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendations,
    required this.isRead,
  });

  String get timeUntil {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else {
      return 'soon';
    }
  }
}

/// AI-generated insights and recommendations
class ForecastInsights {
  final String primaryInsight;
  final List<String> keyTrends;
  final List<String> recommendations;
  final double wasteReductionPotential;
  final Map<String, String> seasonalPatterns;

  const ForecastInsights({
    required this.primaryInsight,
    required this.keyTrends,
    required this.recommendations,
    required this.wasteReductionPotential,
    required this.seasonalPatterns,
  });

  factory ForecastInsights.empty() {
    return const ForecastInsights(
      primaryInsight: 'No insights available yet.',
      keyTrends: [],
      recommendations: [],
      wasteReductionPotential: 0.0,
      seasonalPatterns: {},
    );
  }
}

/// Covariates that affect surplus predictions
class ForecastCovariates {
  final bool isHoliday;
  final bool isWeekend;
  final WeatherCondition weather;
  final List<String> localEvents;
  final SeasonType season;
  final double economicIndex;

  const ForecastCovariates({
    required this.isHoliday,
    required this.isWeekend,
    required this.weather,
    required this.localEvents,
    required this.season,
    required this.economicIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'isHoliday': isHoliday,
      'isWeekend': isWeekend,
      'weather': weather.name,
      'localEvents': localEvents,
      'season': season.name,
      'economicIndex': economicIndex,
    };
  }
}

enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  stormy;

  String get displayName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.stormy:
        return 'Stormy';
    }
  }
}

enum SeasonType {
  spring,
  summer,
  autumn,
  winter;

  String get displayName {
    switch (this) {
      case SeasonType.spring:
        return 'Spring';
      case SeasonType.summer:
        return 'Summer';
      case SeasonType.autumn:
        return 'Autumn';
      case SeasonType.winter:
        return 'Winter';
    }
  }
}
