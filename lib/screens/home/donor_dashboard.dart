import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/surplus_service.dart';
import '../../models/surplus_report_model.dart';
import '../auth/sign_in_screen.dart';
import '../forecast/forecast_dashboard.dart';
import '../donor/create_surplus_screen.dart';
import '../profile/simple_profile_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final SurplusService _surplusService = SurplusService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const SignInScreen();
    }

    return WillPopScope(
      onWillPop: () => _showExitDialog(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Donor Dashboard'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 30,
                        child: const Icon(
                          Icons.volunteer_activism,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome, Donor!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Help reduce food waste and feed communities',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions Section
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Main Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildMainActionCard(
                      context,
                      'Add Surplus',
                      'Donate your excess food',
                      Icons.add_circle,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateSurplusScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMainActionCard(
                      context,
                      'View Forecast',
                      'See demand predictions',
                      Icons.analytics,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForecastDashboard(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Section
              const Text(
                'Your Impact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Items Donated',
                            '12',
                            Icons.inventory,
                            Colors.green,
                          ),
                          _buildStatItem(
                            'People Fed',
                            '48',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'PKR Saved',
                            '15,000',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'ve helped reduce food waste by 85kg this month!',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // My Surplus Reports Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Surplus Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateSurplusScreen(),
                      ),
                    ),
                    child: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Surplus Reports List
              StreamBuilder<List<SurplusReportModel>>(
                stream: _surplusService.getDonorSurplusReports(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error: ${snapshot.error}'),
                      ),
                    );
                  }
                  
                  final reports = snapshot.data ?? [];
                  
                  if (reports.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No surplus reports yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first surplus report to help reduce food waste',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: reports.take(3).map((report) => 
                      _buildSurplusReportCard(report)
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you really want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showFeatureComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSurplusReportCard(SurplusReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(report.status),
          child: Icon(
            _getStatusIcon(report.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          report.foodType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${report.quantity} kg'),
            Text(
              'Expires: ${report.expiry.day}/${report.expiry.month}/${report.expiry.year}',
              style: TextStyle(
                color: _isExpiringSoon(report.expiry) ? Colors.red : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            report.status.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
          labelStyle: TextStyle(color: _getStatusColor(report.status)),
        ),
        onTap: () {
          // TODO: Navigate to surplus detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Surplus details for ${report.foodType}')),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'requested':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'requested':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  bool _isExpiringSoon(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    return difference <= 2; // Expires within 2 days
  }
}
