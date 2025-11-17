import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/sign_in_screen.dart';
import '../history/history_screen.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> {
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
                      maxWidth:
                          constraints.maxWidth > 800 ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section
                        _buildHeaderSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 2. Quick Stats Dashboard
                        _buildQuickStatsSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 3. Available Surplus List (Main Feature)
                        _buildAvailableSurplusSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 4. Active Requests
                        _buildActiveRequestsSection(colorScheme),
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
              Icons.business,
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
                      'welcome_user'
                          .tr(namedArgs: {'name': user.email.split('@')[0]}),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'verified'.tr(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ready_to_collect'.tr(),
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

  // 2. Quick Stats Dashboard
  Widget _buildQuickStatsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'todays_overview'.tr(),
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
                title: 'available'.tr(),
                value: '8',
                icon: Icons.restaurant,
                iconColor: Colors.green,
                subtitle: 'surplus_nearby'.tr(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'pending'.tr(),
                value: '2',
                icon: Icons.schedule,
                iconColor: Colors.orange,
                subtitle: 'pickups_waiting'.tr(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'this_month'.tr(),
                value: '45',
                icon: Icons.check_circle,
                iconColor: Colors.blue,
                subtitle: 'completed'.tr(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'people_helped'.tr(),
                value: '1,230',
                icon: Icons.people,
                iconColor: Colors.purple,
                subtitle: 'lives_impacted'.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Available Surplus List (Main Feature)
  Widget _buildAvailableSurplusSection(ColorScheme colorScheme) {
    final availableSurplus = _generateAvailableSurplus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'available_surplus'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...availableSurplus
            .map((surplus) => _buildAvailableSurplusCard(surplus, colorScheme)),
      ],
    );
  }

  Widget _buildAvailableSurplusCard(
      Map<String, dynamic> surplus, ColorScheme colorScheme) {
    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surplus['foodType'],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getExpiryColor(surplus['expiryHours'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${surplus['expiryHours']}h left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getExpiryColor(surplus['expiryHours']),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${surplus['distance']} km',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Donor: ${surplus['donorName']}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Posted: ${surplus['timePosted']}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  surplus['location'],
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'view_details'.tr(),
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  onPressed: () => _showSurplusDetails(context, surplus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'accept_pickup'.tr(),
                  variant: ButtonVariant.filled,
                  size: ButtonSize.small,
                  onPressed: () => _acceptPickup(context, surplus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Active Requests
  Widget _buildActiveRequestsSection(ColorScheme colorScheme) {
    final activeRequests = _generateActiveRequests();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'active_requests'.tr(),
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
        ...activeRequests
            .map((request) => _buildActiveRequestCard(request, colorScheme)),
      ],
    );
  }

  Widget _buildActiveRequestCard(
      Map<String, dynamic> request, ColorScheme colorScheme) {
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['foodType'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Status: ${request['status']}',
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request['eta'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Contact Donor',
                  icon: Icons.phone,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Mark Collected',
                  icon: Icons.check,
                  variant: ButtonVariant.tonal,
                  size: ButtonSize.small,
                  onPressed: () => _markAsCollected(context, request),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getExpiryColor(int hours) {
    if (hours <= 2) return Colors.red;
    if (hours <= 6) return Colors.orange;
    return Colors.green;
  }

  List<Map<String, dynamic>> _generateAvailableSurplus() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return [];

    // All surplus data with status tracking
    final allSurplus = [
      {
        'id': '1',
        'foodType': 'Fresh Vegetables',
        'quantity': '5 kg',
        'expiryHours': 4,
        'distance': 2.3,
        'donorName': 'Ali Restaurant',
        'donorId': 'donor_1',
        'timePosted': '30 min ago',
        'location': 'Gulshan-e-Iqbal, Karachi',
        'status': 'Available', // Available, Requested, Accepted, Collected
        'acceptedBy': null, // NGO ID that accepted this
      },
      {
        'id': '2',
        'foodType': 'Cooked Rice & Curry',
        'quantity': '15 portions',
        'expiryHours': 2,
        'distance': 1.8,
        'donorName': 'Wedding Hall',
        'donorId': 'donor_2',
        'timePosted': '1 hour ago',
        'location': 'Defence Phase 2, Karachi',
        'status': 'Available',
        'acceptedBy': null,
      },
      {
        'id': '3',
        'foodType': 'Bread & Bakery Items',
        'quantity': '30 pieces',
        'expiryHours': 8,
        'distance': 3.5,
        'donorName': 'City Bakery',
        'donorId': 'donor_3',
        'timePosted': '2 hours ago',
        'location': 'Clifton Block 5, Karachi',
        'status': 'Accepted',
        'acceptedBy': 'other_ngo_id', // Already accepted by another NGO
      },
      {
        'id': '4',
        'foodType': 'Mixed Fruits',
        'quantity': '8 kg',
        'expiryHours': 6,
        'distance': 1.2,
        'donorName': 'Fruit Market',
        'donorId': 'donor_4',
        'timePosted': '45 min ago',
        'location': 'Saddar, Karachi',
        'status': 'Accepted',
        'acceptedBy': user.uid, // Accepted by current NGO
      },
    ];

    // Filter to show only available surplus (not accepted by any NGO)
    // This prevents duplication - once accepted, it's not visible to other NGOs
    return allSurplus
        .where((surplus) =>
            surplus['status'] == 'Available' ||
            (surplus['status'] == 'Accepted' &&
                surplus['acceptedBy'] == user.uid))
        .toList();
  }

  List<Map<String, dynamic>> _generateActiveRequests() {
    return [
      {
        'foodType': 'Mixed Vegetables',
        'status': 'On the way',
        'eta': '15 min',
      },
      {
        'foodType': 'Fruit Basket',
        'status': 'Accepted',
        'eta': '45 min',
      },
    ];
  }

  void _showSurplusDetails(BuildContext context, Map<String, dynamic> surplus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(surplus['foodType']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'quantity'.tr()}: ${surplus['quantity']}'),
            Text(
                '${'expiry'.tr()}: ${surplus['expiryHours']} ${'hours_left'.tr()}'),
            Text('${'distance'.tr()}: ${surplus['distance']} km'),
            Text('${'donor'.tr()}: ${surplus['donorName']}'),
            Text('${'location'.tr()}: ${surplus['location']}'),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 40, color: Colors.grey),
                    Text('map_preview'.tr()),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptPickup(context, surplus);
            },
            child: Text('accept_pickup'.tr()),
          ),
        ],
      ),
    );
  }

  void _acceptPickup(BuildContext context, Map<String, dynamic> surplus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('accept_pickup'.tr()),
        content: Text('${'accept_pickup_for'.tr()} ${surplus['foodType']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${'pickup_accepted_for'.tr()} ${surplus['foodType']}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('accept'.tr()),
          ),
        ],
      ),
    );
  }

  void _markAsCollected(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('mark_as_collected'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${'mark_as_collected_question'.tr().replaceAll('{foodType}', request['foodType'])}'),
            const SizedBox(height: 16),
            Text('upload_photo_signature'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${request['foodType']} ${'marked_as_collected'.tr()}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('mark_collected'.tr()),
          ),
        ],
      ),
    );
  }
}
