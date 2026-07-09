import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../models/user_model.dart';
import '../services/analytics_service.dart';
import '../services/surplus_service.dart';
import '../services/ngo_service.dart';

/// Provider for managing analytics state and data
/// Handles loading, caching, and updating analytics data
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final SurplusService _surplusService = SurplusService();
  final NGOService _ngoService = NGOService();

  // State variables
  DonorAnalytics? _donorAnalytics;
  NGOAnalytics? _ngoAnalytics;
  List<LeaderboardEntry> _donorLeaderboard = [];
  List<LeaderboardEntry> _ngoLeaderboard = [];
  
  bool _isLoadingAnalytics = false;
  bool _isLoadingLeaderboard = false;
  String? _error;
  
  AnalyticsTimeframe _selectedTimeframe = AnalyticsTimeframe.options[1]; // 30 days
  String _selectedLeaderboardPeriod = 'monthly';

  // Getters
  DonorAnalytics? get donorAnalytics => _donorAnalytics;
  NGOAnalytics? get ngoAnalytics => _ngoAnalytics;
  List<LeaderboardEntry> get donorLeaderboard => _donorLeaderboard;
  List<LeaderboardEntry> get ngoLeaderboard => _ngoLeaderboard;
  
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get error => _error;
  
  AnalyticsTimeframe get selectedTimeframe => _selectedTimeframe;
  String get selectedLeaderboardPeriod => _selectedLeaderboardPeriod;

  /// Load analytics data for a donor
  Future<void> loadDonorAnalytics(String donorId) async {
    _isLoadingAnalytics = true;
    _error = null;
    notifyListeners();

    try {
      // Get surplus reports for the donor
      final reportsStream = _surplusService.getDonorSurplusReports(donorId);
      final reports = await reportsStream.first;

      // Calculate analytics
      _donorAnalytics = await _analyticsService.calculateDonorAnalytics(
        donorId,
        reports,
        _selectedTimeframe,
      );
    } catch (e) {
      _error = 'Failed to load donor analytics: $e';
      print('Error loading donor analytics: $e');
    }

    _isLoadingAnalytics = false;
    notifyListeners();
  }

  /// Load analytics data for an NGO
  Future<void> loadNGOAnalytics(String ngoId) async {
    _isLoadingAnalytics = true;
    _error = null;
    notifyListeners();

    try {
      // Get NGO requests
      final requestsStream = _ngoService.getNGORequests(ngoId);
      final requests = await requestsStream.first;

      // Calculate analytics
      _ngoAnalytics = await _analyticsService.calculateNGOAnalytics(
        ngoId,
        requests,
        _selectedTimeframe,
      );
    } catch (e) {
      _error = 'Failed to load NGO analytics: $e';
      print('Error loading NGO analytics: $e');
    }

    _isLoadingAnalytics = false;
    notifyListeners();
  }

  /// Load leaderboard data
  Future<void> loadLeaderboards(String currentUserId, UserRole userRole) async {
    _isLoadingLeaderboard = true;
    _error = null;
    notifyListeners();

    try {
      // Load both leaderboards in parallel
      final futures = await Future.wait([
        _analyticsService.generateDonorLeaderboard(
          currentUserId,
          _selectedLeaderboardPeriod,
        ),
        _analyticsService.generateNGOLeaderboard(
          currentUserId,
          _selectedLeaderboardPeriod,
        ),
      ]);

      _donorLeaderboard = futures[0];
      _ngoLeaderboard = futures[1];
    } catch (e) {
      _error = 'Failed to load leaderboards: $e';
      print('Error loading leaderboards: $e');
    }

    _isLoadingLeaderboard = false;
    notifyListeners();
  }

  /// Change analytics timeframe and reload data
  Future<void> setTimeframe(AnalyticsTimeframe timeframe, String userId, UserRole userRole) async {
    if (_selectedTimeframe == timeframe) return;

    _selectedTimeframe = timeframe;
    notifyListeners();

    // Reload analytics with new timeframe
    if (userRole == UserRole.donor) {
      await loadDonorAnalytics(userId);
    } else {
      await loadNGOAnalytics(userId);
    }
  }

  /// Change leaderboard period and reload data
  Future<void> setLeaderboardPeriod(String period, String userId, UserRole userRole) async {
    if (_selectedLeaderboardPeriod == period) return;

    _selectedLeaderboardPeriod = period;
    notifyListeners();

    // Reload leaderboards with new period
    await loadLeaderboards(userId, userRole);
  }

  /// Refresh all analytics data
  Future<void> refreshAnalytics(String userId, UserRole userRole) async {
    await Future.wait([
      if (userRole == UserRole.donor) 
        loadDonorAnalytics(userId)
      else 
        loadNGOAnalytics(userId),
      loadLeaderboards(userId, userRole),
    ]);
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user's current rank from leaderboard
  int? getUserRank(String userId, UserRole userRole) {
    final leaderboard = userRole == UserRole.donor ? _donorLeaderboard : _ngoLeaderboard;
    
    try {
      final entry = leaderboard.firstWhere((entry) => entry.isCurrentUser);
      return entry.rank;
    } catch (e) {
      return null;
    }
  }

  /// Get user's current badge from leaderboard
  String? getUserBadge(String userId, UserRole userRole) {
    final leaderboard = userRole == UserRole.donor ? _donorLeaderboard : _ngoLeaderboard;
    
    try {
      final entry = leaderboard.firstWhere((entry) => entry.isCurrentUser);
      return entry.badge;
    } catch (e) {
      return null;
    }
  }

  /// Get summary statistics for quick display
  Map<String, dynamic> getSummaryStats(UserRole userRole) {
    if (userRole == UserRole.donor && _donorAnalytics != null) {
      return {
        'primary': _donorAnalytics!.totalQuantityDonated.toStringAsFixed(1),
        'primaryLabel': 'kg Donated',
        'secondary': _donorAnalytics!.estimatedMealsFed.toString(),
        'secondaryLabel': 'Meals Fed',
        'tertiary': _donorAnalytics!.completedDonations.toString(),
        'tertiaryLabel': 'Completed',
        'impact': _donorAnalytics!.impactScore.toStringAsFixed(0),
      };
    } else if (userRole == UserRole.ngo && _ngoAnalytics != null) {
      return {
        'primary': _ngoAnalytics!.completedPickups.toString(),
        'primaryLabel': 'Pickups',
        'secondary': _ngoAnalytics!.estimatedMealsDistributed.toString(),
        'secondaryLabel': 'Meals Distributed',
        'tertiary': _ngoAnalytics!.collectionEfficiency.toStringAsFixed(0),
        'tertiaryLabel': '% Efficiency',
        'impact': _ngoAnalytics!.impactScore.toStringAsFixed(0),
      };
    }
    
    return {
      'primary': '0',
      'primaryLabel': 'No Data',
      'secondary': '0',
      'secondaryLabel': 'No Data',
      'tertiary': '0',
      'tertiaryLabel': 'No Data',
      'impact': '0',
    };
  }

  /// Check if analytics data is available
  bool hasAnalyticsData(UserRole userRole) {
    return userRole == UserRole.donor 
      ? _donorAnalytics != null 
      : _ngoAnalytics != null;
  }

  /// Get chart data for monthly trends
  List<Map<String, dynamic>> getMonthlyChartData(UserRole userRole) {
    Map<String, double>? monthlyData;
    
    if (userRole == UserRole.donor && _donorAnalytics != null) {
      monthlyData = _donorAnalytics!.monthlyData;
    } else if (userRole == UserRole.ngo && _ngoAnalytics != null) {
      monthlyData = _ngoAnalytics!.monthlyCollections;
    }

    if (monthlyData == null || monthlyData.isEmpty) {
      return [];
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'value': entry.value,
    }).toList();
  }

  /// Get available timeframe options
  List<AnalyticsTimeframe> get timeframeOptions => AnalyticsTimeframe.options;

  /// Get available leaderboard period options
  List<Map<String, String>> get leaderboardPeriodOptions => [
    {'value': 'weekly', 'label': 'This Week'},
    {'value': 'monthly', 'label': 'This Month'},
    {'value': 'all-time', 'label': 'All Time'},
  ];
}
