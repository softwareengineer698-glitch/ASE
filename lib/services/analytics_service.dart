import 'dart:math';
import '../models/analytics_model.dart';
import '../models/surplus_report_model.dart';
import '../models/ngo_request_model.dart';

/// Service for calculating and providing analytics data
/// Handles data aggregation, trend analysis, and leaderboard generation
class AnalyticsService {
  static const double _mealsPerKg = 4.0; // Estimated meals per kg of food
  static const double _pkrPerKg = 150.0; // Estimated PKR value per kg

  /// Calculate donor analytics from surplus reports
  Future<DonorAnalytics> calculateDonorAnalytics(
    String donorId,
    List<SurplusReportModel> reports,
    AnalyticsTimeframe timeframe,
  ) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (reports.isEmpty) {
      return DonorAnalytics.empty();
    }

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: timeframe.days));
    
    // Filter reports within timeframe
    final filteredReports = reports.where((r) => 
      r.timestamp.isAfter(cutoffDate)).toList();

    // Calculate basic metrics
    final totalDonations = filteredReports.length;
    final totalQuantity = filteredReports.fold<double>(
      0, (sum, report) => sum + report.quantity);
    
    final activeDonations = filteredReports.where(
      (r) => r.status == 'available' || r.status == 'requested').length;
    
    final completedDonations = filteredReports.where(
      (r) => r.status == 'completed').length;

    // Calculate impact metrics
    final estimatedMeals = (totalQuantity * _mealsPerKg).round();
    final estimatedMoney = totalQuantity * _pkrPerKg;

    // Calculate this month's data
    final thisMonth = DateTime(now.year, now.month, 1);
    final thisMonthReports = filteredReports.where(
      (r) => r.timestamp.isAfter(thisMonth)).toList();
    final thisMonthQuantity = thisMonthReports.fold<double>(
      0, (sum, report) => sum + report.quantity);

    // Generate monthly data for charts
    final monthlyData = _generateMonthlyData(filteredReports, timeframe.days);
    
    // Generate category breakdown (mock data for now)
    final categoryBreakdown = _generateCategoryBreakdown(filteredReports);

    // Generate trends
    final trends = _generateDonationTrends(filteredReports, timeframe.days);

    // Calculate additional metrics
    final averageDonationSize = totalDonations > 0 ? totalQuantity / totalDonations : 0.0;
    final daysActive = _calculateActiveDays(filteredReports);
    final impactScore = _calculateDonorImpactScore(
      totalQuantity, completedDonations, daysActive);

    return DonorAnalytics(
      totalDonations: totalDonations,
      totalQuantityDonated: totalQuantity,
      activeDonations: activeDonations,
      completedDonations: completedDonations,
      estimatedMealsFed: estimatedMeals,
      estimatedMoneySaved: estimatedMoney,
      thisMonthQuantity: thisMonthQuantity,
      monthlyData: monthlyData,
      categoryBreakdown: categoryBreakdown,
      trends: trends,
      averageDonationSize: averageDonationSize,
      daysActive: daysActive,
      impactScore: impactScore,
    );
  }

  /// Calculate NGO analytics from requests
  Future<NGOAnalytics> calculateNGOAnalytics(
    String ngoId,
    List<NGORequestModel> requests,
    AnalyticsTimeframe timeframe,
  ) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (requests.isEmpty) {
      return NGOAnalytics.empty();
    }

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: timeframe.days));
    
    // Filter requests within timeframe
    final filteredRequests = requests.where((r) => 
      r.timestamp.isAfter(cutoffDate)).toList();

    // Calculate basic metrics
    final totalRequests = filteredRequests.length;
    final acceptedRequests = filteredRequests.where(
      (r) => r.status == 'accepted').length;
    final completedPickups = filteredRequests.where(
      (r) => r.status == 'completed').length;

    // Mock quantity data (in real app, would get from surplus reports)
    final totalQuantity = completedPickups * 5.0; // Average 5kg per pickup
    final estimatedMeals = (totalQuantity * _mealsPerKg).round();

    // Generate daily pickups data
    final dailyPickups = _generateDailyPickups(filteredRequests, timeframe.days);
    
    // Generate monthly collections
    final monthlyCollections = _generateMonthlyCollections(filteredRequests, timeframe.days);

    // Calculate unique donors (mock data)
    final uniqueDonors = (completedPickups * 0.7).round(); // Assume 70% unique
    final activeDonors = List.generate(uniqueDonors, 
      (i) => 'donor_${i + 1}@example.com');

    // Calculate performance metrics
    final averageResponseTime = _calculateAverageResponseTime(filteredRequests);
    final collectionEfficiency = totalRequests > 0 
      ? (completedPickups / totalRequests) * 100 : 0.0;

    // Generate trends
    final trends = _generateNGOTrends(filteredRequests, timeframe.days);

    // Calculate impact score
    final impactScore = _calculateNGOImpactScore(
      completedPickups, collectionEfficiency, averageResponseTime);

    // This month pickups
    final thisMonth = DateTime(now.year, now.month, 1);
    final thisMonthPickups = filteredRequests.where(
      (r) => r.timestamp.isAfter(thisMonth) && r.status == 'completed').length;

    return NGOAnalytics(
      totalRequests: totalRequests,
      acceptedRequests: acceptedRequests,
      completedPickups: completedPickups,
      totalQuantityCollected: totalQuantity,
      estimatedMealsDistributed: estimatedMeals,
      dailyPickups: dailyPickups,
      monthlyCollections: monthlyCollections,
      activeDonors: activeDonors,
      uniqueDonors: uniqueDonors,
      averageResponseTime: averageResponseTime,
      collectionEfficiency: collectionEfficiency,
      trends: trends,
      impactScore: impactScore,
      thisMonthPickups: thisMonthPickups,
    );
  }

  /// Generate leaderboard for donors
  Future<List<LeaderboardEntry>> generateDonorLeaderboard(
    String currentUserId,
    String period, // 'weekly', 'monthly', 'all-time'
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock leaderboard data
    final random = Random();
    final entries = <LeaderboardEntry>[];

    // Generate mock entries
    for (int i = 0; i < 20; i++) {
      final isCurrentUser = i == 5; // Current user at rank 6
      entries.add(LeaderboardEntry(
        id: isCurrentUser ? currentUserId : 'user_$i',
        name: isCurrentUser ? 'You' : 'Donor ${i + 1}',
        email: isCurrentUser ? 'you@example.com' : 'donor${i + 1}@example.com',
        value: 100.0 - (i * 3.5) + random.nextDouble() * 5,
        rank: i + 1,
        badge: _getBadgeForRank(i + 1),
        isCurrentUser: isCurrentUser,
      ));
    }

    return entries;
  }

  /// Generate leaderboard for NGOs
  Future<List<LeaderboardEntry>> generateNGOLeaderboard(
    String currentUserId,
    String period,
  ) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock leaderboard data
    final random = Random();
    final entries = <LeaderboardEntry>[];

    for (int i = 0; i < 15; i++) {
      final isCurrentUser = i == 3; // Current user at rank 4
      entries.add(LeaderboardEntry(
        id: isCurrentUser ? currentUserId : 'ngo_$i',
        name: isCurrentUser ? 'Your NGO' : 'NGO ${i + 1}',
        email: isCurrentUser ? 'your-ngo@example.com' : 'ngo${i + 1}@example.com',
        value: (50 - (i * 2.2) + random.nextDouble() * 3).toDouble(),
        rank: i + 1,
        badge: _getBadgeForRank(i + 1),
        isCurrentUser: isCurrentUser,
      ));
    }

    return entries;
  }

  // Helper methods

  Map<String, double> _generateMonthlyData(List<SurplusReportModel> reports, int days) {
    final data = <String, double>{};
    final now = DateTime.now();
    
    // Generate data for the last few months based on timeframe
    final months = (days / 30).ceil();
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.month}/${month.year}';
      
      // Calculate quantity for this month
      final monthReports = reports.where((r) => 
        r.timestamp.year == month.year && r.timestamp.month == month.month);
      final quantity = monthReports.fold<double>(0, (sum, r) => sum + r.quantity);
      
      data[monthKey] = quantity;
    }
    
    return data;
  }

  Map<String, int> _generateCategoryBreakdown(List<SurplusReportModel> reports) {
    // Mock category data - in real app would use actual categories
    final categories = ['Fruits', 'Vegetables', 'Grains', 'Dairy', 'Prepared Food'];
    final breakdown = <String, int>{};
    
    for (final category in categories) {
      breakdown[category] = Random().nextInt(reports.length ~/ 2) + 1;
    }
    
    return breakdown;
  }

  List<DonationTrend> _generateDonationTrends(List<SurplusReportModel> reports, int days) {
    final trends = <DonationTrend>[];
    final now = DateTime.now();
    
    // Generate weekly trends
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));
      
      final weekReports = reports.where((r) => 
        r.timestamp.isAfter(weekStart) && r.timestamp.isBefore(weekEnd));
      final quantity = weekReports.fold<double>(0, (sum, r) => sum + r.quantity);
      
      trends.add(DonationTrend(
        period: 'Week ${4 - i}',
        value: quantity,
        direction: i == 0 ? TrendDirection.up : 
                  Random().nextBool() ? TrendDirection.up : TrendDirection.down,
        label: '${quantity.toStringAsFixed(1)} kg',
      ));
    }
    
    return trends;
  }

  Map<String, int> _generateDailyPickups(List<NGORequestModel> requests, int days) {
    final data = <String, int>{};
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      
      final dayRequests = requests.where((r) => 
        r.timestamp.year == date.year &&
        r.timestamp.month == date.month &&
        r.timestamp.day == date.day &&
        r.status == 'completed');
      
      data[dateKey] = dayRequests.length;
    }
    
    return data;
  }

  Map<String, double> _generateMonthlyCollections(List<NGORequestModel> requests, int days) {
    final data = <String, double>{};
    final now = DateTime.now();
    
    final months = (days / 30).ceil();
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.month}/${month.year}';
      
      final monthRequests = requests.where((r) => 
        r.timestamp.year == month.year && 
        r.timestamp.month == month.month &&
        r.status == 'completed');
      
      // Mock quantity calculation
      data[monthKey] = monthRequests.length * 5.0; // 5kg average per pickup
    }
    
    return data;
  }

  List<NGOTrend> _generateNGOTrends(List<NGORequestModel> requests, int days) {
    final trends = <NGOTrend>[];
    final now = DateTime.now();
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));
      
      final weekRequests = requests.where((r) => 
        r.timestamp.isAfter(weekStart) && 
        r.timestamp.isBefore(weekEnd) &&
        r.status == 'completed');
      
      final pickups = weekRequests.length;
      final quantity = pickups * 5.0; // Mock quantity
      
      trends.add(NGOTrend(
        period: 'Week ${4 - i}',
        pickups: pickups,
        quantity: quantity,
        direction: i == 0 ? TrendDirection.up : 
                  Random().nextBool() ? TrendDirection.up : TrendDirection.down,
        label: '$pickups pickups',
      ));
    }
    
    return trends;
  }

  double _calculateAverageResponseTime(List<NGORequestModel> requests) {
    if (requests.isEmpty) return 0.0;
    
    // Mock calculation - in real app would calculate time between request and acceptance
    return 2.5 + Random().nextDouble() * 3; // 2.5-5.5 hours average
  }

  int _calculateActiveDays(List<SurplusReportModel> reports) {
    if (reports.isEmpty) return 0;
    
    final uniqueDays = <String>{};
    for (final report in reports) {
      final dayKey = '${report.timestamp.year}-${report.timestamp.month}-${report.timestamp.day}';
      uniqueDays.add(dayKey);
    }
    
    return uniqueDays.length;
  }

  double _calculateDonorImpactScore(double totalQuantity, int completedDonations, int daysActive) {
    // Custom scoring algorithm
    final quantityScore = totalQuantity * 0.4;
    final completionScore = completedDonations * 2.0;
    final consistencyScore = daysActive * 0.5;
    
    return (quantityScore + completionScore + consistencyScore).clamp(0.0, 100.0);
  }

  double _calculateNGOImpactScore(int completedPickups, double efficiency, double responseTime) {
    final pickupScore = completedPickups * 3.0;
    final efficiencyScore = efficiency * 0.5;
    final responseScore = (10 - responseTime.clamp(0, 10)) * 2.0;
    
    return (pickupScore + efficiencyScore + responseScore).clamp(0.0, 100.0);
  }

  String _getBadgeForRank(int rank) {
    if (rank == 1) return '🥇 Champion';
    if (rank <= 3) return '🥈 Hero';
    if (rank <= 5) return '🥉 Star';
    if (rank <= 10) return '⭐ Rising';
    return '👍 Active';
  }
}
