import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/sign_in_screen.dart';
import '../history/history_screen.dart';
import '../donor/create_donation_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final DonationService _donationService = DonationService();

  // Random food icon list
  final List<IconData> _foodIcons = [
    Icons.fastfood,
    Icons.local_pizza,
    Icons.restaurant,
    Icons.emoji_food_beverage,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.cake,
    Icons.icecream,
  ];

  IconData _selectedFoodIcon = Icons.fastfood; // Default fallback

  @override
  void initState() {
    super.initState();
    _selectedFoodIcon =
        _foodIcons[(DateTime.now().millisecondsSinceEpoch) % _foodIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ThemeProvider, LanguageProvider>(
      builder: (context, authProvider, themeProvider, languageProvider, child) {
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
                      maxWidth:
                          constraints.maxWidth > 800 ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section
                        _buildHeaderSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 2. Real-time Stats Dashboard Cards
                        _buildRealTimeStatsSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 3. Forecast Section
                        _buildForecastSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 4. Main Actions
                        _buildMainActionsSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 5. Active Donations List
                        _buildActiveDonationsSection(user, colorScheme),
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
                Row(
                  children: [
                    Text(
                      'hello_user'
                          .tr(namedArgs: {'name': user.email.split('@')[0]}),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _selectedFoodIcon,
                      size: 24,
                      color: colorScheme.primary,
                    )
                        .animate()
                        .scale(duration: 700.ms)
                        .then()
                        .scale(
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1, 1))
                        .then(delay: 1000.ms)
                        .scale(duration: 700.ms)
                        .then()
                        .scale(
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1, 1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ready_to_help_today'.tr(),
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

  // 2. Real-time Stats Dashboard Cards
  Widget _buildRealTimeStatsSection(UserModel user, ColorScheme colorScheme) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _donationService.getDonorStatistics(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return DashboardCard(
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading statistics',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalDonations = stats['totalDonations'] ?? 0;
        final pendingDonations = stats['pendingDonations'] ?? 0;
        final completedDonations = stats['completedDonations'] ?? 0;
        final totalQuantitySaved = stats['totalQuantitySaved'] ?? 0.0;
        final recentDonation = stats['recentDonation'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_impact'.tr(),
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
                    title: 'total_donations'.tr(),
                    value: '$totalDonations',
                    icon: Icons.volunteer_activism,
                    color: Colors.blue,
                    subtitle: 'all_time'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'pending'.tr(),
                    value: '$pendingDonations',
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    subtitle: 'awaiting_pickup'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'completed'.tr(),
                    value: '$completedDonations',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    subtitle: 'successfully_donated'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'food_saved'.tr(),
                    value: '${totalQuantitySaved.toStringAsFixed(1)} kg',
                    icon: Icons.eco,
                    color: Colors.purple,
                    subtitle: 'total_quantity'.tr(),
                  ),
                ),
              ],
            ),
            if (recentDonation != null) ...[
              const SizedBox(height: 16),
              DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'recent_activity'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recentDonation['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recentDonation['quantity']} ${recentDonation['unit']} - ${recentDonation['category']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
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
              Icon(Icons.insights, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'forecast_insights'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 5),
                      FlSpot(2, 4),
                      FlSpot(3, 7),
                      FlSpot(4, 6),
                    ],
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'donation_trend_increasing'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Main Actions
  Widget _buildMainActionsSection(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr(),
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
              child: CustomButton(
                text: 'create_donation'.tr(),
                icon: Icons.add_circle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateDonationScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'view_history'.tr(),
                icon: Icons.history,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.grey[300],
                textColor: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Active Donations List
  Widget _buildActiveDonationsSection(UserModel user, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getDonorDonations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return DashboardCard(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading donations',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final donations = snapshot.data ?? [];
          final activeDonations = donations
              .where((d) =>
                  d.status == DonationStatus.available ||
                  d.status == DonationStatus.claimed)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'active_donations'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${activeDonations.length} ${'items'.tr()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: activeDonations.isEmpty
                    ? DashboardCard(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'no_active_donations'.tr(),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'create_first_donation'.tr(),
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeDonations.length,
                        itemBuilder: (context, index) {
                          final donation = activeDonations[index];
                          return _buildDonationCard(donation, colorScheme);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(donation.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(donation.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  donation.formattedTimestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              donation.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              donation.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    donation.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${donation.quantity} ${donation.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (donation.status == DonationStatus.claimed) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _completeDonation(donation),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('mark_complete'.tr()),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showDonationDetails(donation),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ] else if (donation.status == DonationStatus.available) ...[
              OutlinedButton.icon(
                onPressed: () => _showDonationDetails(donation),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return Colors.green;
      case DonationStatus.claimed:
        return Colors.blue;
      case DonationStatus.completed:
        return Colors.purple;
      case DonationStatus.expired:
        return Colors.red;
    }
  }

  void _showDonationDetails(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donation.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${donation.category}'),
              const SizedBox(height: 8),
              Text('Quantity: ${donation.quantity} ${donation.unit}'),
              const SizedBox(height: 8),
              Text('Location: ${donation.location}'),
              const SizedBox(height: 8),
              Text('Status: ${donation.statusDisplayName}'),
              const SizedBox(height: 8),
              const Text('Description:'),
              Text(donation.description),
              const SizedBox(height: 8),
              Text('Posted: ${donation.formattedTimestamp}'),
              const SizedBox(height: 8),
              Text('Expires: ${donation.expiryTime}'),
              if (donation.status == DonationStatus.claimed &&
                  donation.claimedBy != null) ...[
                const SizedBox(height: 8),
                Text('Claimed by: NGO'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _completeDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('complete_donation'.tr()),
        content: Text('confirm_complete_donation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _donationService.completeDonation(donation.id);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('donation_completed'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error_completing_donation'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
