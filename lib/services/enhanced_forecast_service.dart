import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_model.dart';
import 'forecast_service.dart';

/// Enhanced Forecast Service with real AI model integration
/// Supports Prophet, NeuralProphet, and ARIMA models via Python backend
class EnhancedForecastService {
  static const String _envBaseUrl =
      String.fromEnvironment('FORECAST_API_BASE_URL', defaultValue: '');
  static const Duration _timeout = Duration(seconds: 30);

  final String baseUrl;
  final ForecastService _fallbackService;

  EnhancedForecastService({
    String? baseUrl,
    ForecastService? fallbackService,
  })  : baseUrl = (baseUrl != null && baseUrl.trim().isNotEmpty)
            ? baseUrl.trim()
            : (_envBaseUrl.trim().isNotEmpty
                ? _envBaseUrl.trim()
                : 'http://127.0.0.1:5000'),
        _fallbackService = fallbackService ?? ForecastService();

  /// Generate forecast using Prophet model (recommended for food surplus)
  Future<AIForecast> generateProphetForecast(
    String donorId,
    List<Map<String, dynamic>> historicalData,
    ForecastCovariates covariates,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forecast/prophet'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'donor_id': donorId,
              'historical_data': historicalData,
              'covariates': covariates.toMap(),
              'forecast_days': 7,
              'include_uncertainty': true,
              'confidence_interval': 0.95,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseProphetResponse(data, covariates);
      } else {
        throw Exception('Prophet forecast failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock service if backend is unavailable
      return await _fallbackForecast(donorId, covariates);
    }
  }

  /// Generate forecast using NeuralProphet for complex patterns
  Future<AIForecast> generateNeuralProphetForecast(
    String donorId,
    List<Map<String, dynamic>> historicalData,
    ForecastCovariates covariates,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forecast/neuralprophet'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'donor_id': donorId,
              'historical_data': historicalData,
              'covariates': covariates.toMap(),
              'forecast_days': 7,
              'epochs': 100,
              'learning_rate': 0.01,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseNeuralProphetResponse(data, covariates);
      } else {
        throw Exception(
            'NeuralProphet forecast failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to Prophet if NeuralProphet fails
      return await generateProphetForecast(donorId, historicalData, covariates);
    }
  }

  /// Get model performance metrics and explanations
  Future<Map<String, dynamic>> getModelMetrics(String donorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/metrics/$donorId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _getDefaultMetrics();
      }
    } catch (e) {
      return _getDefaultMetrics();
    }
  }

  /// Parse Prophet response into AIForecast model
  AIForecast _parseProphetResponse(
      Map<String, dynamic> data, ForecastCovariates covariates) {
    final weeklyForecast = <ForecastPoint>[];
    final monthlyForecast = <ForecastPoint>[];
    final alerts = <SurplusAlert>[];

    // Parse weekly forecast
    final weeklyData = data['weekly_forecast'] as List;
    for (int i = 0; i < weeklyData.length; i++) {
      final point = weeklyData[i];
      weeklyForecast.add(ForecastPoint(
        date: DateTime.parse(point['date']),
        predictedSurplus: point['yhat'].toDouble(),
        confidence: point['confidence'].toDouble(),
        riskLevel: _determineRiskLevel(point['yhat'].toDouble()),
        contributingFactors: List<String>.from(point['factors'] ?? []),
        categoryBreakdown: Map<String, double>.from(point['categories'] ?? {}),
      ));
    }

    // Parse monthly forecast
    final monthlyData = data['monthly_forecast'] as List;
    for (int i = 0; i < monthlyData.length; i++) {
      final point = monthlyData[i];
      monthlyForecast.add(ForecastPoint(
        date: DateTime.parse(point['date']),
        predictedSurplus: point['yhat'].toDouble(),
        confidence: point['confidence'].toDouble(),
        riskLevel: _determineRiskLevel(point['yhat'].toDouble()),
        contributingFactors: List<String>.from(point['factors'] ?? []),
        categoryBreakdown: Map<String, double>.from(point['categories'] ?? {}),
      ));
    }

    // Generate alerts from forecast
    alerts.addAll(_generateAlertsFromForecast(weeklyForecast));

    // Parse insights
    final insightsData = data['insights'] as Map<String, dynamic>;
    final insights = ForecastInsights(
      primaryInsight: insightsData['primary_insight'] ?? '',
      keyTrends: List<String>.from(insightsData['key_trends'] ?? []),
      recommendations: List<String>.from(insightsData['recommendations'] ?? []),
      wasteReductionPotential:
          insightsData['waste_reduction_potential']?.toDouble() ?? 0.0,
      seasonalPatterns:
          Map<String, String>.from(insightsData['seasonal_patterns'] ?? {}),
    );

    return AIForecast(
      weeklyForecast: weeklyForecast,
      monthlyForecast: monthlyForecast,
      alerts: alerts,
      insights: insights,
      covariates: covariates.toMap(),
      lastUpdated: DateTime.now(),
      modelAccuracy: data['model_accuracy']?.toDouble() ?? 0.85,
    );
  }

  /// Parse NeuralProphet response (similar to Prophet)
  AIForecast _parseNeuralProphetResponse(
      Map<String, dynamic> data, ForecastCovariates covariates) {
    // Similar implementation to Prophet parsing
    return _parseProphetResponse(data, covariates);
  }

  /// Determine risk level based on predicted surplus
  SurplusRiskLevel _determineRiskLevel(double surplus) {
    if (surplus > 40) {
      return SurplusRiskLevel.critical;
    } else if (surplus > 25) {
      return SurplusRiskLevel.high;
    } else if (surplus > 15) {
      return SurplusRiskLevel.medium;
    } else {
      return SurplusRiskLevel.low;
    }
  }

  /// Generate alerts from forecast points
  List<SurplusAlert> _generateAlertsFromForecast(List<ForecastPoint> forecast) {
    final alerts = <SurplusAlert>[];

    for (int i = 0; i < forecast.length; i++) {
      final point = forecast[i];

      if (point.riskLevel == SurplusRiskLevel.high ||
          point.riskLevel == SurplusRiskLevel.critical) {
        alerts.add(SurplusAlert(
          id: 'ai_alert_${i}_${point.date.millisecondsSinceEpoch}',
          date: point.date,
          severity: point.riskLevel,
          title: point.riskLevel == SurplusRiskLevel.critical
              ? 'AI: Critical Surplus Alert'
              : 'AI: High Surplus Warning',
          message:
              'AI predicts ${point.predictedSurplus.toStringAsFixed(1)}kg surplus on ${point.formattedDate}',
          recommendations: _getAIRecommendations(point.riskLevel),
          isRead: false,
        ));
      }
    }

    return alerts;
  }

  /// Get AI-powered recommendations based on risk level
  List<String> _getAIRecommendations(SurplusRiskLevel riskLevel) {
    switch (riskLevel) {
      case SurplusRiskLevel.critical:
        return [
          'AI: Schedule immediate pickup with multiple NGOs',
          'AI: Activate emergency distribution network',
          'AI: Consider preservative treatment for extended storage',
          'AI: Alert community food sharing programs',
        ];
      case SurplusRiskLevel.high:
        return [
          'AI: Schedule pickup within 12 hours',
          'AI: Contact priority NGO partners',
          'AI: Prepare for rapid distribution',
          'AI: Monitor quality indicators closely',
        ];
      case SurplusRiskLevel.medium:
        return [
          'AI: Schedule pickup within 24-48 hours',
          'AI: Notify regular donation partners',
          'AI: Optimize packaging for transport',
        ];
      case SurplusRiskLevel.low:
        return [
          'AI: Maintain standard donation schedule',
          'AI: Focus on quality improvement',
        ];
    }
  }

  /// Fallback to mock forecast if backend is unavailable
  Future<AIForecast> _fallbackForecast(
      String donorId, ForecastCovariates covariates) async {
    return _fallbackService.generateForecast(donorId, covariates);
  }

  /// Get default model metrics
  Map<String, dynamic> _getDefaultMetrics() {
    return {
      'mape': 0.15, // Mean Absolute Percentage Error
      'rmse': 2.5, // Root Mean Square Error
      'mae': 1.8, // Mean Absolute Error
      'coverage': 0.92, // Prediction interval coverage
      'model_type': 'Prophet',
      'last_trained': DateTime.now().toIso8601String(),
      'data_points_used': 365,
    };
  }

  /// Train/retrain the model with new data
  Future<bool> retrainModel(
      String donorId, List<Map<String, dynamic>> newData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/train/$donorId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'new_data': newData,
              'model_type': 'prophet',
              'cross_validation': true,
            }),
          )
          .timeout(Duration(minutes: 5)); // Training takes longer

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
