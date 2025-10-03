import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/surplus_service.dart';
import '../../services/ngo_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../auth/sign_in_screen.dart';
import '../profile/simple_profile_screen.dart';
import '../../models/surplus_report_model.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});
  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> {
  final SurplusService _surplusService = SurplusService();
  final NGOService _ngoService = NGOService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const SignInScreen();
    }

    // Debug: Print user role for troubleshooting
    print('NGO Dashboard - Current user role: ${user.role}');
    print('NGO Dashboard - User UID: ${user.uid}');

    if (user.role != UserRole.ngo) {
      return Scaffold(
        appBar: AppBar(title: const Text('NGO Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'This dashboard is for NGO users only.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Current role: ${user.role.displayName}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                ),
                child: const Text('Sign In as NGO'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () => _showExitDialog(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NGO Dashboard'),
          backgroundColor: Colors.blue,
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
                        backgroundColor: Colors.blue,
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
                              'Welcome, NGO Partner!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Help collect surplus food and feed communities',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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

              // Available Surplus Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Surplus Food',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {}), // Refresh
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Surplus Reports List
              StreamBuilder<List<SurplusReportModel>>(
                stream: _surplusService.getAvailableSurplusReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Error: ${snapshot.error}'),
                          ],
                        ),
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
                              'No surplus available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new surplus reports from donors',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: reports.map((report) => 
                      _buildSurplusCard(report, user.uid)
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  Widget _buildMainActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
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
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
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

  Widget _buildSurplusCard(SurplusReportModel report, String ngoId) {
    final isExpiringSoon = report.expiry.difference(DateTime.now()).inDays <= 2;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.foodType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Quantity: ${report.quantity} kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    report.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (report.description != null) ...[
              Text(
                report.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isExpiringSoon ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${report.expiry.day}/${report.expiry.month}/${report.expiry.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isExpiringSoon ? Colors.red : Colors.grey[600],
                    fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isExpiringSoon) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptSurplus(report, ngoId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept Surplus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showSurplusDetails(report),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptSurplus(SurplusReportModel report, String ngoId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accept Surplus'),
          content: Text('Do you want to accept ${report.foodType} (${report.quantity} kg)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Accept the surplus
      await _ngoService.acceptSurplus(ngoId, report.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully accepted ${report.foodType}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger notification
        NotificationService().notifySurplusAccepted(
          foodType: report.foodType,
          ngoName: 'Your NGO', // TODO: Get actual NGO name from profile
          donorName: 'Donor', // TODO: Get donor name from report
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting surplus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSurplusDetails(SurplusReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.foodType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Quantity', '${report.quantity} kg'),
            _buildDetailRow('Expires', '${report.expiry.day}/${report.expiry.month}/${report.expiry.year}'),
            _buildDetailRow('Posted', '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}'),
            if (report.description != null)
              _buildDetailRow('Description', report.description!),
            _buildDetailRow('Status', report.status.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptSurplus(report, Provider.of<AuthProvider>(context, listen: false).user!.uid);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
