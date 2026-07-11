import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/forecast_model.dart';
import '../../providers/forecast_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

/// Advanced AI Forecast Dashboard for Donors
/// Provides surplus predictions, alerts, and recommendations with covariate controls
class AIForecastDashboard extends StatefulWidget {
  const AIForecastDashboard({super.key});

  @override
  State<AIForecastDashboard> createState() => _AIForecastDashboardState();
}

class _AIForecastDashboardState extends State<AIForecastDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForecast();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadForecast() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final forecastProvider =
        Provider.of<ForecastProvider>(context, listen: false);

    if (authProvider.user != null) {
      forecastProvider.loadForecast(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ForecastProvider, AuthProvider, ThemeProvider>(
      builder: (context, forecastProvider, authProvider, themeProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Forecast Dashboard'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                Tab(text: 'Charts', icon: Icon(Icons.analytics)),
                Tab(text: 'Alerts', icon: Icon(Icons.warning)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadForecast(),
              ),
            ],
          ),
          body: forecastProvider.isLoading
              ? const LoadingWidget(message: 'Generating AI forecast...')
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(forecastProvider, user, themeProvider),
                    _buildChartsTab(forecastProvider, user, themeProvider),
                    _buildAlertsTab(forecastProvider, user, themeProvider),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOverviewTab(ForecastProvider forecastProvider, dynamic user,
      ThemeProvider themeProvider) {
    if (forecastProvider.error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Forecast Error',
        message: forecastProvider.error!,
        actionText: 'Retry',
        onActionPressed: () => _loadForecast(),
      );
    }

    if (!forecastProvider.hasForecast) {
      return EmptyStateWidget(
        icon: Icons.psychology,
        title: 'No Forecast Available',
        message: 'AI forecast will appear here once generated.',
        actionText: 'Generate Forecast',
        onActionPressed: () => _loadForecast(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => forecastProvider.refreshForecast(user?.uid ?? ''),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Forecast Summary Cards
            _buildSummaryCards(forecastProvider, themeProvider),

            const SizedBox(height: 24),

            // Covariates Control Panel
            _buildCovariatesPanel(forecastProvider, user, themeProvider),

            const SizedBox(height: 24),

            // Today's Forecast
            _buildTodaysForecast(forecastProvider, themeProvider),

            const SizedBox(height: 24),

            // AI Insights
            _buildInsightsSection(forecastProvider, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab(ForecastProvider forecastProvider, dynamic user,
      ThemeProvider themeProvider) {
    if (!forecastProvider.hasForecast) {
      return const EmptyStateWidget(
        icon: Icons.analytics,
        title: 'No Chart Data',
        message: 'Generate forecast to see charts.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => forecastProvider.refreshForecast(user?.uid ?? ''),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Chart
            _buildWeeklyChart(forecastProvider, themeProvider),

            const SizedBox(height: 24),

            // Monthly Chart
            _buildMonthlyChart(forecastProvider, themeProvider),

            const SizedBox(height: 24),

            // Category Breakdown
            _buildCategoryBreakdown(forecastProvider, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab(ForecastProvider forecastProvider, dynamic user,
      ThemeProvider themeProvider) {
    final alerts = forecastProvider.currentForecast?.alerts ?? [];

    if (alerts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle,
        title: 'No Alerts',
        message: 'All clear! No surplus alerts at the moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => forecastProvider.refreshForecast(user?.uid ?? ''),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return _buildAlertCard(alert, forecastProvider, themeProvider);
        },
      ),
    );
  }

  Widget _buildSummaryCards(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final summary = forecastProvider.getForecastSummary();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Weekly Surplus',
            value: '${summary['totalWeeklySurplus'].toStringAsFixed(1)} kg',
            icon: Icons.inventory,
            color: themeProvider.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Daily Average',
            value: '${summary['averageDailySurplus'].toStringAsFixed(1)} kg',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'High Risk Days',
            value: '${summary['highRiskDays']}',
            icon: Icons.warning,
            color: Colors.red,
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
                fontSize: 20,
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

  Widget _buildCovariatesPanel(ForecastProvider forecastProvider, dynamic user,
      ThemeProvider themeProvider) {
    final covariates = forecastProvider.currentCovariates;
    if (covariates == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Forecast Factors & Models',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Forecasting Toggle
            SwitchListTile(
              title: const Text('AI Enhanced Mode'),
              subtitle: const Text('Use advanced time-series ML models'),
              value: forecastProvider.useEnhancedService,
              onChanged: (value) => forecastProvider.setUseEnhancedService(
                  user?.uid ?? '', value),
              activeThumbColor: themeProvider.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),

            if (forecastProvider.useEnhancedService)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Algorithm Model'),
                subtitle: Text('Current: ${forecastProvider.selectedModel}'),
                trailing: DropdownButton<String>(
                  value: forecastProvider.selectedModel,
                  onChanged: (model) {
                    if (model != null) {
                      forecastProvider.updateModelType(user?.uid ?? '', model);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: 'ARIMA', child: Text('ARIMA model')),
                    DropdownMenuItem(
                        value: 'Prophet', child: Text('Prophet model')),
                    DropdownMenuItem(
                        value: 'NeuralProphet', child: Text('NeuralProphet')),
                  ],
                ),
              ),

            const Divider(),

            // Holiday Toggle
            SwitchListTile(
              title: const Text('Holiday Period'),
              subtitle: const Text('Affects surplus by +40%'),
              value: covariates.isHoliday,
              onChanged: (value) =>
                  forecastProvider.toggleHoliday(user?.uid ?? ''),
              activeThumbColor: themeProvider.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),

            // Weather Selector
            ListTile(
              title: const Text('Weather Condition'),
              subtitle: Text(covariates.weather.displayName),
              trailing: DropdownButton<WeatherCondition>(
                value: covariates.weather,
                onChanged: (weather) {
                  if (weather != null) {
                    forecastProvider.updateWeather(user?.uid ?? '', weather);
                  }
                },
                items: WeatherCondition.values.map((weather) {
                  return DropdownMenuItem(
                    value: weather,
                    child: Text(weather.displayName),
                  );
                }).toList(),
              ),
            ),

            // Local Events
            if (covariates.localEvents.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Local Events:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: covariates.localEvents.map((event) {
                  return Chip(
                    label: Text(event),
                    onDeleted: () => forecastProvider.removeLocalEvent(
                        user?.uid ?? '', event),
                    backgroundColor:
                        themeProvider.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysForecast(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final todaysForecast = forecastProvider.todaysForecast;
    final tomorrowsForecast = forecastProvider.tomorrowsForecast;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Today & Tomorrow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Today
                Expanded(
                  child: _buildDayForecast(
                    'Today',
                    todaysForecast,
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 16),
                // Tomorrow
                Expanded(
                  child: _buildDayForecast(
                    'Tomorrow',
                    tomorrowsForecast,
                    themeProvider,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayForecast(
      String day, ForecastPoint? forecast, ThemeProvider themeProvider) {
    if (forecast == null) {
      return Column(
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No data', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(forecast.riskLevel.colorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(forecast.riskLevel.colorValue)),
          ),
          child: Column(
            children: [
              Text(
                '${forecast.predictedSurplus.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(forecast.riskLevel.colorValue),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                forecast.riskLevelText,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(forecast.riskLevel.colorValue),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                forecast.confidenceText,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final insights = forecastProvider.currentForecast?.insights;
    if (insights == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primary Insight
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                insights.primaryInsight,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: themeProvider.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            if (insights.recommendations.isNotEmpty) ...[
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...insights.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(rec,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final chartData = forecastProvider.weeklyChartData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Surplus Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Text(
                              chartData[value.toInt()]['date'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value['surplus']);
                      }).toList(),
                      isCurved: true,
                      color: themeProvider.primaryColor,
                      barWidth: 3,
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

  Widget _buildMonthlyChart(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final chartData = forecastProvider.monthlyChartData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Outlook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Text(
                              chartData[value.toInt()]['week'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: chartData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['surplus'],
                          color: Color(entry.value['color']),
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      ForecastProvider forecastProvider, ThemeProvider themeProvider) {
    final breakdown = forecastProvider.weeklyCategoryBreakdown;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: entry.value /
                              breakdown.values.reduce((a, b) => a > b ? a : b),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              themeProvider.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value.toStringAsFixed(1)} kg'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SurplusAlert alert, ForecastProvider forecastProvider,
      ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(alert.severity.colorValue),
          child: Icon(
            alert.severity == SurplusRiskLevel.critical
                ? Icons.error
                : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 4),
            Text(
              alert.timeUntil,
              style: TextStyle(
                fontSize: 12,
                color: Color(alert.severity.colorValue),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: alert.isRead
            ? const Icon(Icons.check, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => forecastProvider.markAlertAsRead(alert.id),
              ),
        onTap: () => _showAlertDetails(alert, forecastProvider),
      ),
    );
  }

  void _showAlertDetails(
      SurplusAlert alert, ForecastProvider forecastProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...alert.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!alert.isRead)
            ElevatedButton(
              onPressed: () {
                forecastProvider.markAlertAsRead(alert.id);
                Navigator.of(context).pop();
              },
              child: const Text('Mark as Read'),
            ),
        ],
      ),
    );
  }
}
