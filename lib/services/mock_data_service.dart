import '../models/surplus_model.dart';
import '../models/forecast_model.dart';

class MockDataService {
  // Mock surplus data for NGO dashboard
  static List<SurplusItem> getMockSurplusItems() {
    return [
      SurplusItem(
        id: '1',
        donorName: 'Green Valley Restaurant',
        itemName: 'Fresh Vegetables',
        category: 'Vegetables',
        quantity: 50,
        unit: 'kg',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        location: 'Lahore, Punjab',
        description: 'Mixed fresh vegetables including tomatoes, onions, and carrots',
        status: SurplusStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SurplusItem(
        id: '2',
        donorName: 'City Bakery',
        itemName: 'Bread Loaves',
        category: 'Bakery',
        quantity: 30,
        unit: 'pieces',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        location: 'Karachi, Sindh',
        description: 'Fresh whole wheat bread loaves',
        status: SurplusStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SurplusItem(
        id: '3',
        donorName: 'Dairy Farm Co.',
        itemName: 'Fresh Milk',
        category: 'Dairy',
        quantity: 100,
        unit: 'liters',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        location: 'Islamabad, ICT',
        description: 'Fresh cow milk, pasteurized',
        status: SurplusStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      SurplusItem(
        id: '4',
        donorName: 'Fruit Market',
        itemName: 'Seasonal Fruits',
        category: 'Fruits',
        quantity: 75,
        unit: 'kg',
        expiryDate: DateTime.now().add(const Duration(days: 4)),
        location: 'Faisalabad, Punjab',
        description: 'Mix of seasonal fruits - mangoes, oranges, apples',
        status: SurplusStatus.reserved,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SurplusItem(
        id: '5',
        donorName: 'Rice Mill',
        itemName: 'Basmati Rice',
        category: 'Grains',
        quantity: 200,
        unit: 'kg',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        location: 'Multan, Punjab',
        description: 'Premium quality basmati rice',
        status: SurplusStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      SurplusItem(
        id: '6',
        donorName: 'Hotel Grand',
        itemName: 'Cooked Meals',
        category: 'Prepared Food',
        quantity: 40,
        unit: 'portions',
        expiryDate: DateTime.now().add(const Duration(hours: 6)),
        location: 'Lahore, Punjab',
        description: 'Freshly prepared meals - biryani and curry',
        status: SurplusStatus.available,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  // Mock forecast data for donor dashboard
  static List<ForecastData> getMockForecastData() {
    final List<ForecastData> forecasts = [];
    final categories = ['Vegetables', 'Fruits', 'Dairy', 'Grains', 'Prepared Food'];
    
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().add(Duration(days: i));
      
      for (String category in categories) {
        // Generate mock demand with some randomness and trends
        double baseDemand = _getBaseDemandForCategory(category);
        double seasonalFactor = _getSeasonalFactor(date, category);
        double randomFactor = 0.8 + (i % 5) * 0.1; // Simple variation
        
        double demand = baseDemand * seasonalFactor * randomFactor;
        double confidence = 0.7 + (i % 3) * 0.1; // Confidence decreases over time
        
        forecasts.add(ForecastData(
          date: date,
          demand: demand,
          category: category,
          confidence: confidence,
        ));
      }
    }
    
    return forecasts;
  }

  static double _getBaseDemandForCategory(String category) {
    switch (category) {
      case 'Vegetables':
        return 80.0;
      case 'Fruits':
        return 60.0;
      case 'Dairy':
        return 70.0;
      case 'Grains':
        return 90.0;
      case 'Prepared Food':
        return 50.0;
      default:
        return 50.0;
    }
  }

  static double _getSeasonalFactor(DateTime date, String category) {
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    double seasonalCycle = (dayOfYear % 30) / 30.0; // Simple 30-day cycle
    
    switch (category) {
      case 'Vegetables':
        return 1.0 + 0.3 * (0.5 + 0.5 * seasonalCycle);
      case 'Fruits':
        return 1.0 + 0.4 * seasonalCycle;
      case 'Dairy':
        return 1.0 + 0.2 * (1 - seasonalCycle);
      case 'Grains':
        return 1.0 + 0.1 * seasonalCycle;
      case 'Prepared Food':
        return 1.0 + 0.5 * (0.5 + 0.5 * seasonalCycle);
      default:
        return 1.0;
    }
  }

  // Get forecast summary for a specific category
  static ForecastSummary getForecastSummary(String category) {
    final forecasts = getMockForecastData()
        .where((f) => f.category == category)
        .take(7) // Next 7 days
        .toList();
    
    if (forecasts.isEmpty) {
      return ForecastSummary(
        category: category,
        totalDemand: 0,
        averageDemand: 0,
        peakDemand: 0,
        peakDate: DateTime.now(),
        dailyForecasts: [],
      );
    }
    
    double totalDemand = forecasts.fold(0, (sum, f) => sum + f.demand);
    double averageDemand = totalDemand / forecasts.length;
    
    ForecastData peakForecast = forecasts.reduce((a, b) => a.demand > b.demand ? a : b);
    
    return ForecastSummary(
      category: category,
      totalDemand: totalDemand,
      averageDemand: averageDemand,
      peakDemand: peakForecast.demand,
      peakDate: peakForecast.date,
      dailyForecasts: forecasts,
    );
  }

  // Get categories for filtering
  static List<String> getCategories() {
    return ['Vegetables', 'Fruits', 'Dairy', 'Grains', 'Prepared Food', 'Bakery'];
  }

  // Mock function to simulate adding surplus
  static Future<bool> addSurplus(SurplusItem item) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate success (in real app, this would save to database)
    return true;
  }

  // Mock function to simulate reserving surplus
  static Future<bool> reserveSurplus(String surplusId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate success
    return true;
  }
}
