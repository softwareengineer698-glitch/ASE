import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/forecast_model.dart';
import '../../services/forecast_service.dart';
import '../../providers/auth_provider.dart';

/// Forecast Dashboard — uses real ForecastService + HistoricalDataService
/// Shows actual donation data alongside AI-powered surplus predictions.
class ForecastDashboard extends StatefulWidget {
  const ForecastDashboard({super.key});

  @override
  State<ForecastDashboard> createState() => _ForecastDashboardState();
}

class _ForecastDashboardState extends State<ForecastDashboard> {
  final ForecastService _forecastService = ForecastService();

  AIForecast? _forecast;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All', 'Vegetables', 'Fruits', 'Grains', 'Dairy', 'Prepared Food'
  ];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.uid ?? 'anonymous';
      final covariates = _forecastService.getCurrentCovariates();
      final forecast = await _forecastService.generateForecast(uid, covariates);
      if (mounted) {
        setState(() {
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Filter weekly forecast by selected category
  List<ForecastPoint> get _filteredPoints {
    final points = _forecast?.weeklyForecast ?? [];
    if (_selectedCategory == 'All') return points;
    return points.map((p) {
      final catValue = p.categoryBreakdown[_selectedCategory] ?? 0;
      return ForecastPoint(
        date: p.date,
        predictedSurplus: catValue,
        confidence: p.confidence,
        riskLevel: p.riskLevel,
        contributingFactors: p.contributingFactors,
        categoryBreakdown: p.categoryBreakdown,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forecast_title'.tr()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForecast,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('generating_forecast'.tr()),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _loadForecast,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadForecast,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildModelAccuracy(),
                        const SizedBox(height: 20),
                        _buildCategoryFilter(),
                        const SizedBox(height: 20),
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        _buildChartSection(),
                        const SizedBox(height: 20),
                        _buildInsights(),
                        const SizedBox(height: 20),
                        _buildAlerts(),
                        const SizedBox(height: 20),
                        _buildRecommendations(),
                        const SizedBox(height: 20),
                        _buildCategoryBreakdown(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('forecast_title'.tr(),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                          overflow: TextOverflow.ellipsis),
                      Text('ai_powered_predictions'.tr(),
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.lightbulb,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('plan_donations'.tr(),
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            if (_forecast != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${_formatDate(_forecast!.lastUpdated)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Model accuracy badge ─────────────────────────────────────────────────
  Widget _buildModelAccuracy() {
    if (_forecast == null) return const SizedBox.shrink();
    final accuracy = (_forecast!.modelAccuracy * 100).toStringAsFixed(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 14, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text('Model Accuracy: $accuracy%',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Category filter ──────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('select_category'.tr(),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.map((cat) {
              final sel = _selectedCategory == cat;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: sel ? Colors.blue : Colors.grey[700],
                    fontWeight:
                        sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Summary cards ────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final points = _filteredPoints;
    if (points.isEmpty) return const SizedBox.shrink();

    final total =
        points.fold<double>(0, (s, p) => s + p.predictedSurplus);
    final avg = total / points.length;
    final peak = points.reduce(
        (a, b) => a.predictedSurplus > b.predictedSurplus ? a : b);
    final avgConfidence =
        points.fold<double>(0, (s, p) => s + p.confidence) /
            points.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _summaryCard('Avg Daily',
                    '${avg.toStringAsFixed(1)} kg',
                    Icons.trending_up, Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard('Peak Demand',
                    '${peak.predictedSurplus.toStringAsFixed(1)} kg',
                    Icons.show_chart, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard('Total (7 days)',
                    '${total.toStringAsFixed(1)} kg',
                    Icons.inventory, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard('Peak Date',
                    _formatDate(peak.date),
                    Icons.calendar_today, Colors.purple)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _summaryCard('Avg Confidence',
                    '${(avgConfidence * 100).toStringAsFixed(0)}%',
                    Icons.verified, Colors.teal)),
            const SizedBox(width: 12),
            Expanded(
                child: _summaryCard('Waste Reduction',
                    '${(_forecast?.insights.wasteReductionPotential ?? 0).toStringAsFixed(1)} kg',
                    Icons.eco, Colors.lightGreen)),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(title,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ─── Chart ────────────────────────────────────────────────────────────────
  Widget _buildChartSection() {
    final points = _filteredPoints;
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('weekly_forecast'.tr(),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 240, child: _buildChart(points)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text('Predicted Demand (kg)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<ForecastPoint> points) {
    final spots = points.asMap().entries
        .map((e) =>
            FlSpot(e.key.toDouble(), e.value.predictedSurplus))
        .toList();

    final maxY = spots
        .map((s) => s.y)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey[300]!, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: Colors.grey[300]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(),
          topTitles:
              const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final d = points[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.day}/${d.month}',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 10,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!)),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.25,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 5,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Insights ──────────────────────────────────────────────────────────
  Widget _buildInsights() {
    final insights = _forecast?.insights;
    if (insights == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ai_insights'.tr(),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary insight
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology,
                          color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(insights.primaryInsight,
                            style: TextStyle(
                                color: Colors.purple.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Key trends
                if (insights.keyTrends.isNotEmpty) ...[
                  const Text('Key Trends',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  ...insights.keyTrends.map((t) => _insightRow(
                      Icons.trending_up, t, Colors.blue)),
                  const SizedBox(height: 10),
                ],
                // Seasonal patterns
                if (insights.seasonalPatterns.isNotEmpty) ...[
                  const Text('Seasonal Patterns',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  ...insights.seasonalPatterns.entries.map((e) =>
                      _insightRow(
                          Icons.wb_sunny, '${e.key}: ${e.value}',
                          Colors.orange)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _insightRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ─── Alerts ───────────────────────────────────────────────────────────────
  Widget _buildAlerts() {
    final alerts = _forecast?.alerts ?? [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
            SizedBox(width: 6),
            Text('Surplus Alerts',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...alerts.take(3).map((alert) {
          final isCritical =
              alert.severity == SurplusRiskLevel.critical;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isCritical
                ? Colors.red.shade50
                : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(
                isCritical
                    ? Icons.error_rounded
                    : Icons.warning_amber_rounded,
                color: isCritical ? Colors.red : Colors.orange,
              ),
              title: Text(alert.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(alert.message,
                  style: const TextStyle(fontSize: 12)),
              trailing: Text(_formatDate(alert.date),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600])),
            ),
          );
        }),
      ],
    );
  }

  // ─── Recommendations ──────────────────────────────────────────────────────
  Widget _buildRecommendations() {
    final recs = _forecast?.insights.recommendations ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('donation_recommendations'.tr(),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: recs
                  .map((r) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.check,
                                  size: 14,
                                  color: Colors.green.shade700),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(r,
                                    style: const TextStyle(
                                        fontSize: 13))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Category breakdown ───────────────────────────────────────────────────
  Widget _buildCategoryBreakdown() {
    final points = _forecast?.weeklyForecast ?? [];
    if (points.isEmpty) return const SizedBox.shrink();

    // Aggregate totals per category
    final totals = <String, double>{};
    for (final p in points) {
      for (final e in p.categoryBreakdown.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
    if (totals.isEmpty) return const SizedBox.shrink();

    final grandTotal =
        totals.values.fold<double>(0, (s, v) => s + v);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.red
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category Breakdown (7 days)',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sorted.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value.key;
                final val = entry.value.value;
                final pct =
                    grandTotal > 0 ? (val / grandTotal) : 0.0;
                final color = colors[idx % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text(
                              '${val.toStringAsFixed(1)} kg (${(pct * 100).toStringAsFixed(0)}%)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: color.withAlpha(40),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${wd[date.weekday - 1]}, ${date.day} ${mo[date.month - 1]}';
  }
}
