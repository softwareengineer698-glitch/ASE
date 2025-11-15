import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

/// Comprehensive analytics dashboard showing user impact and performance
/// Displays different metrics based on user role (Donor/NGO)
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      analyticsProvider.refreshAnalytics(
        authProvider.user!.uid,
        authProvider.user!.role,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AnalyticsProvider, AuthProvider, ThemeProvider>(
      builder: (context, analyticsProvider, authProvider, themeProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analytics Dashboard'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadAnalytics(),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(analyticsProvider, user, themeProvider),
              _buildLeaderboardTab(analyticsProvider, user, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    if (analyticsProvider.isLoadingAnalytics) {
      return const LoadingWidget(message: 'Loading analytics...');
    }

    if (analyticsProvider.error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Error Loading Analytics',
        message: analyticsProvider.error!,
        actionText: 'Retry',
        onActionPressed: () => _loadAnalytics(),
      );
    }

    if (!analyticsProvider.hasAnalyticsData(user.role)) {
      return EmptyStateWidget(
        icon: Icons.analytics_outlined,
        title: 'No Analytics Data',
        message: user.role == UserRole.donor 
          ? 'Start donating to see your impact analytics here.'
          : 'Start accepting donations to see your analytics here.',
        actionText: 'Go to Dashboard',
        onActionPressed: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => analyticsProvider.refreshAnalytics(user.uid, user.role),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe Selector
            _buildTimeframeSelector(analyticsProvider, user, themeProvider),
            
            const SizedBox(height: 20),
            
            // Summary Cards
            _buildSummaryCards(analyticsProvider, user, themeProvider),
            
            const SizedBox(height: 24),
            
            // Charts Section
            _buildChartsSection(analyticsProvider, user, themeProvider),
            
            const SizedBox(height: 24),
            
            // Additional Insights
            _buildInsightsSection(analyticsProvider, user, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    if (analyticsProvider.isLoadingLeaderboard) {
      return const LoadingWidget(message: 'Loading leaderboard...');
    }

    return RefreshIndicator(
      onRefresh: () => analyticsProvider.loadLeaderboards(user.uid, user.role),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(analyticsProvider, user, themeProvider),
            
            const SizedBox(height: 20),
            
            // User's Rank Card
            _buildUserRankCard(analyticsProvider, user, themeProvider),
            
            const SizedBox(height: 24),
            
            // Leaderboard List
            _buildLeaderboardList(analyticsProvider, user, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: analyticsProvider.timeframeOptions.map((timeframe) {
                final isSelected = analyticsProvider.selectedTimeframe == timeframe;
                return FilterChip(
                  label: Text(timeframe.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      analyticsProvider.setTimeframe(timeframe, user.uid, user.role);
                    }
                  },
                  selectedColor: themeProvider.primaryColor.withOpacity(0.2),
                  checkmarkColor: themeProvider.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    final stats = analyticsProvider.getSummaryStats(user.role);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: stats['primaryLabel'],
            value: stats['primary'],
            icon: user.role == UserRole.donor ? Icons.volunteer_activism : Icons.business,
            color: themeProvider.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: stats['secondaryLabel'],
            value: stats['secondary'],
            icon: Icons.restaurant,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: stats['tertiaryLabel'],
            value: stats['tertiary'],
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    final chartData = analyticsProvider.getMonthlyChartData(user.role);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.role == UserRole.donor ? 'Monthly Donations' : 'Monthly Collections',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'No chart data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['value']);
                          }).toList(),
                          isCurved: true,
                          color: themeProvider.primaryColor,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    final stats = analyticsProvider.getSummaryStats(user.role);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impact Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: double.parse(stats['impact']) / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${stats['impact']}/100',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getImpactMessage(double.parse(stats['impact'])),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaderboard Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: analyticsProvider.leaderboardPeriodOptions.map((option) {
                final isSelected = analyticsProvider.selectedLeaderboardPeriod == option['value'];
                return FilterChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      analyticsProvider.setLeaderboardPeriod(option['value']!, user.uid, user.role);
                    }
                  },
                  selectedColor: themeProvider.primaryColor.withOpacity(0.2),
                  checkmarkColor: themeProvider.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    final rank = analyticsProvider.getUserRank(user.uid, user.role);
    final badge = analyticsProvider.getUserBadge(user.uid, user.role);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
              child: Text(
                user.email.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rank != null ? '#$rank' : 'Not ranked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(AnalyticsProvider analyticsProvider, UserModel user, ThemeProvider themeProvider) {
    final leaderboard = user.role == UserRole.donor 
      ? analyticsProvider.donorLeaderboard 
      : analyticsProvider.ngoLeaderboard;
    
    if (leaderboard.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.leaderboard,
        title: 'No Leaderboard Data',
        message: 'Leaderboard data will appear here once available.',
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...leaderboard.take(10).map((entry) => ListTile(
            leading: CircleAvatar(
              backgroundColor: entry.isCurrentUser 
                ? themeProvider.primaryColor 
                : _getRankColor(entry.rank),
              child: Text(
                entry.rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              entry.name,
              style: TextStyle(
                fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(entry.badge),
            trailing: Text(
              '${entry.value.toStringAsFixed(1)} ${user.role == UserRole.donor ? 'kg' : 'pickups'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser ? themeProvider.primaryColor : null,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _getImpactMessage(double score) {
    if (score >= 80) return 'Outstanding impact! You\'re making a real difference.';
    if (score >= 60) return 'Great work! Keep up the excellent contributions.';
    if (score >= 40) return 'Good progress! There\'s room for even more impact.';
    if (score >= 20) return 'Getting started! Every contribution counts.';
    return 'Just beginning your journey. Start making an impact today!';
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank <= 3) return Colors.grey;
    if (rank <= 5) return Colors.brown;
    return Colors.blue;
  }
}
