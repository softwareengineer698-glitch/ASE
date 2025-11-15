import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/sign_in_screen.dart';
import '../forecast/forecast_dashboard.dart';
import '../donor/create_surplus_screen.dart';
import '../history/history_screen.dart';
import '../notifications/notifications_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final user = authProvider.user;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (user == null) {
          return const SignInScreen();
        }

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                      maxWidth: constraints.maxWidth > 800 ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section
                        _buildHeaderSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 2. Quick Stats Dashboard Cards
                        _buildQuickStatsSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 3. Forecast Section
                        _buildForecastSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 4. Main Actions
                        _buildMainActionsSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 5. Active Surplus List
                        _buildActiveSurplusSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.02),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 1. Header Section
  Widget _buildHeaderSection(UserModel user, ColorScheme colorScheme) {
    return DashboardCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 30,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.email.split('@')[0]} 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to help reduce food waste today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Quick Stats Dashboard Cards
  Widget _buildQuickStatsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Surplus Risk',
                value: 'High',
                icon: Icons.warning,
                iconColor: Colors.orange,
                subtitle: 'Check forecast',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'This Month',
                value: '12',
                icon: Icons.restaurant,
                iconColor: Colors.green,
                subtitle: 'Food donated',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Meals Helped',
                value: '156',
                icon: Icons.people,
                iconColor: Colors.blue,
                subtitle: 'People fed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Pending',
                value: '3',
                icon: Icons.schedule,
                iconColor: Colors.purple,
                subtitle: 'Pickups waiting',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Forecast Section
  Widget _buildForecastSection(BuildContext context, ColorScheme colorScheme) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '📊 Demand Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForecastDashboard()),
                ),
                child: Text('Report'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 50, // Even shorter height
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRect(
              child: _buildMiniChart(colorScheme),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Surplus Alert: High demand expected tomorrow',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Main Actions
  Widget _buildMainActionsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'report_surplus'.tr(),
                subtitle: 'add_new_surplus'.tr(),
                icon: Icons.add_circle,
                iconColor: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateSurplusScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'View History',
                subtitle: 'Past donations',
                icon: Icons.history,
                iconColor: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: '🔔 Notifications',
          icon: Icons.notifications,
          fullWidth: true,
          variant: ButtonVariant.outlined,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  // 5. Active Surplus List
  Widget _buildActiveSurplusSection(ColorScheme colorScheme) {
    final mockSurplus = _generateMockSurplus();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Surplus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...mockSurplus.map((surplus) => _buildSurplusCard(surplus, colorScheme)),
      ],
    );
  }

  Widget _buildSurplusCard(Map<String, dynamic> surplus, ColorScheme colorScheme) {
    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(surplus['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: _getStatusColor(surplus['status']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surplus['foodName'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Quantity: ${surplus['quantity']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(surplus['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  surplus['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(surplus['status']),
                  ),
                ),
              ),
            ],
          ),
          if (surplus['ngoName'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'NGO: ${surplus['ngoName']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (surplus['eta'] != null)
                  Text(
                    'ETA: ${surplus['eta']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
          if (surplus['status'] == 'Accepted') ...[
            const SizedBox(height: 12),
            CustomButton(
              text: 'track_pickup'.tr(),
              icon: Icons.location_on,
              size: ButtonSize.small,
              variant: ButtonVariant.tonal,
              onPressed: () => _showTrackingDialog(context, surplus),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniChart(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 1),
                FlSpot(2, 4),
                FlSpot(3, 2),
                FlSpot(4, 5),
                FlSpot(5, 3),
                FlSpot(6, 4),
              ],
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 1,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Requested':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Collected':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _generateMockSurplus() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return [];
    
    // All surplus data with donor IDs
    final allSurplus = [
      {
        'id': '1',
        'donorId': user.uid, // Current user's surplus
        'foodName': 'Fresh Vegetables',
        'quantity': '5 kg',
        'status': 'Accepted',
        'ngoName': 'Edhi Foundation',
        'eta': '2:30 PM',
      },
      {
        'id': '2',
        'donorId': user.uid, // Current user's surplus
        'foodName': 'Cooked Rice',
        'quantity': '10 portions',
        'status': 'Available',
        'ngoName': null,
        'eta': null,
      },
      {
        'id': '3',
        'donorId': user.uid, // Current user's surplus
        'foodName': 'Bread Loaves',
        'quantity': '20 pieces',
        'status': 'Requested',
        'ngoName': 'Saylani Welfare',
        'eta': '4:00 PM',
      },
      {
        'id': '4',
        'donorId': 'other_donor_id', // Other donor's surplus - should not be visible
        'foodName': 'Other Donor Food',
        'quantity': '3 kg',
        'status': 'Available',
        'ngoName': null,
        'eta': null,
      },
    ];
    
    // Filter to show only current user's surplus
    return allSurplus.where((surplus) => surplus['donorId'] == user.uid).toList();
  }

  void _showTrackingDialog(BuildContext context, Map<String, dynamic> surplus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tracking: ${surplus['foodName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text('Accepted by ${surplus['ngoName']}'),
              subtitle: const Text('10:30 AM'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blue),
              title: const Text('On the way'),
              subtitle: Text('ETA: ${surplus['eta']}'),
            ),
            const ListTile(
              leading: Icon(Icons.schedule, color: Colors.grey),
              title: Text('Pickup pending'),
              subtitle: Text('Waiting for collection'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Contact NGO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
