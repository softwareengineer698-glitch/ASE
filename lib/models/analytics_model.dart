/// Analytics models for tracking donation and NGO performance metrics
/// Provides data structures for various analytics calculations

class DonorAnalytics {
  final int totalDonations;
  final double totalQuantityDonated; // in kg
  final int activeDonations;
  final int completedDonations;
  final int estimatedMealsFed;
  final double estimatedMoneySaved; // in PKR
  final double thisMonthQuantity;
  final Map<String, double> monthlyData; // Month -> Quantity
  final Map<String, int> categoryBreakdown; // Category -> Count
  final List<DonationTrend> trends;
  final double averageDonationSize;
  final int daysActive;
  final double impactScore;

  const DonorAnalytics({
    required this.totalDonations,
    required this.totalQuantityDonated,
    required this.activeDonations,
    required this.completedDonations,
    required this.estimatedMealsFed,
    required this.estimatedMoneySaved,
    required this.thisMonthQuantity,
    required this.monthlyData,
    required this.categoryBreakdown,
    required this.trends,
    required this.averageDonationSize,
    required this.daysActive,
    required this.impactScore,
  });

  factory DonorAnalytics.empty() {
    return const DonorAnalytics(
      totalDonations: 0,
      totalQuantityDonated: 0.0,
      activeDonations: 0,
      completedDonations: 0,
      estimatedMealsFed: 0,
      estimatedMoneySaved: 0.0,
      thisMonthQuantity: 0.0,
      monthlyData: {},
      categoryBreakdown: {},
      trends: [],
      averageDonationSize: 0.0,
      daysActive: 0,
      impactScore: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalDonations': totalDonations,
      'totalQuantityDonated': totalQuantityDonated,
      'activeDonations': activeDonations,
      'completedDonations': completedDonations,
      'estimatedMealsFed': estimatedMealsFed,
      'estimatedMoneySaved': estimatedMoneySaved,
      'thisMonthQuantity': thisMonthQuantity,
      'monthlyData': monthlyData,
      'categoryBreakdown': categoryBreakdown,
      'averageDonationSize': averageDonationSize,
      'daysActive': daysActive,
      'impactScore': impactScore,
    };
  }
}

class NGOAnalytics {
  final int totalRequests;
  final int acceptedRequests;
  final int completedPickups;
  final double totalQuantityCollected; // in kg
  final int estimatedMealsDistributed;
  final Map<String, int> dailyPickups; // Date -> Count
  final Map<String, double> monthlyCollections; // Month -> Quantity
  final List<String> activeDonors;
  final int uniqueDonors;
  final double averageResponseTime; // in hours
  final double collectionEfficiency; // percentage
  final List<NGOTrend> trends;
  final double impactScore;
  final int thisMonthPickups;

  const NGOAnalytics({
    required this.totalRequests,
    required this.acceptedRequests,
    required this.completedPickups,
    required this.totalQuantityCollected,
    required this.estimatedMealsDistributed,
    required this.dailyPickups,
    required this.monthlyCollections,
    required this.activeDonors,
    required this.uniqueDonors,
    required this.averageResponseTime,
    required this.collectionEfficiency,
    required this.trends,
    required this.impactScore,
    required this.thisMonthPickups,
  });

  factory NGOAnalytics.empty() {
    return const NGOAnalytics(
      totalRequests: 0,
      acceptedRequests: 0,
      completedPickups: 0,
      totalQuantityCollected: 0.0,
      estimatedMealsDistributed: 0,
      dailyPickups: {},
      monthlyCollections: {},
      activeDonors: [],
      uniqueDonors: 0,
      averageResponseTime: 0.0,
      collectionEfficiency: 0.0,
      trends: [],
      impactScore: 0.0,
      thisMonthPickups: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'acceptedRequests': acceptedRequests,
      'completedPickups': completedPickups,
      'totalQuantityCollected': totalQuantityCollected,
      'estimatedMealsDistributed': estimatedMealsDistributed,
      'dailyPickups': dailyPickups,
      'monthlyCollections': monthlyCollections,
      'activeDonors': activeDonors,
      'uniqueDonors': uniqueDonors,
      'averageResponseTime': averageResponseTime,
      'collectionEfficiency': collectionEfficiency,
      'impactScore': impactScore,
      'thisMonthPickups': thisMonthPickups,
    };
  }
}

class DonationTrend {
  final String period; // e.g., "Week 1", "March 2024"
  final double value;
  final TrendDirection direction;
  final String label;

  const DonationTrend({
    required this.period,
    required this.value,
    required this.direction,
    required this.label,
  });
}

class NGOTrend {
  final String period;
  final int pickups;
  final double quantity;
  final TrendDirection direction;
  final String label;

  const NGOTrend({
    required this.period,
    required this.pickups,
    required this.quantity,
    required this.direction,
    required this.label,
  });
}

enum TrendDirection {
  up,
  down,
  stable,
}

class LeaderboardEntry {
  final String id;
  final String name;
  final String email;
  final double value; // quantity for donors, pickups for NGOs
  final int rank;
  final String badge;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.value,
    required this.rank,
    required this.badge,
    required this.isCurrentUser,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'value': value,
      'rank': rank,
      'badge': badge,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      rank: map['rank'] ?? 0,
      badge: map['badge'] ?? '',
      isCurrentUser: map['isCurrentUser'] ?? false,
    );
  }
}

class AnalyticsTimeframe {
  final String label;
  final String value;
  final int days;

  const AnalyticsTimeframe({
    required this.label,
    required this.value,
    required this.days,
  });

  static const List<AnalyticsTimeframe> options = [
    AnalyticsTimeframe(label: 'Last 7 Days', value: '7d', days: 7),
    AnalyticsTimeframe(label: 'Last 30 Days', value: '30d', days: 30),
    AnalyticsTimeframe(label: 'Last 3 Months', value: '3m', days: 90),
    AnalyticsTimeframe(label: 'Last 6 Months', value: '6m', days: 180),
    AnalyticsTimeframe(label: 'Last Year', value: '1y', days: 365),
  ];
}
