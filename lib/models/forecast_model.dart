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
