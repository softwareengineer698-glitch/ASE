import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Changed from 3 tabs to 2 tabs - Verifications tab removed
    // NGO verification layer removed per requirements
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          // Verifications tab removed - NGOs are now auto-verified
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(colorScheme, adminProvider),
          _buildUsersTab(colorScheme, adminProvider),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // TAB 1: Overview
  // ──────────────────────────────────────
  Widget _buildOverviewTab(ColorScheme colorScheme, AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(colorScheme, provider.stats),
          const SizedBox(height: 24),
          Text(
            'System Management',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAdminActions(context, colorScheme),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // TAB 2: Users (Donors & NGOs)
  // ──────────────────────────────────────
  Widget _buildUsersTab(ColorScheme colorScheme, AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donors Section
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Donors (${provider.allDonors.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.allDonors.isEmpty)
            const DashboardCard(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No donors registered yet',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            ...provider.allDonors.map((donor) =>
                _buildUserCard(context, donor, colorScheme, provider)),
          const SizedBox(height: 32),

          // NGOs Section - Note: All NGOs are now auto-verified
          Row(
            children: [
              const Icon(Icons.business, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'NGOs (${provider.allNGOs.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.allNGOs.isEmpty)
            const DashboardCard(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No NGOs registered yet',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            ...provider.allNGOs.map(
                (ngo) => _buildUserCard(context, ngo, colorScheme, provider)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // SHARED WIDGETS
  // ──────────────────────────────────────

  Widget _buildSummarySection(ColorScheme colorScheme, Map<String, int> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                '${stats['totalUsers']}',
                Icons.people,
                colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active NGOs',
                '${stats['activeNGOs']}',
                Icons.business,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Donors',
                '${stats['donors']}',
                Icons.volunteer_activism,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Volunteers',
                '${stats['volunteers']}',
                Icons.volunteer_activism_rounded,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, ColorScheme colorScheme) {
    final actions = [
      {
        'title': 'User Management',
        'icon': Icons.person_search,
        'color': Colors.blue,
        'action': () => _tabController.animateTo(1),
      },
      {
        'title': 'Global Reports',
        'icon': Icons.bar_chart,
        'color': Colors.orange,
        'action': () {},
      },
      {
        'title': 'Security Audit',
        'icon': Icons.security,
        'color': Colors.red,
        'action': () {},
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return DashboardCard(
          child: InkWell(
            onTap: action['action'] as VoidCallback,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData,
                    color: action['color'] as Color, size: 32),
                const SizedBox(height: 8),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user,
      ColorScheme colorScheme, AdminProvider provider) {
    final isNGO = user.role == UserRole.ngo;

    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isNGO
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              child: Icon(
                isNGO ? Icons.business : Icons.person,
                color: isNGO ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(
              user.organizationName ?? user.userName ?? user.email.split('@')[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isNGO
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isNGO ? 'NGO' : 'Donor',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isNGO ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    // Verification badge removed - all NGOs are auto-verified
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Account',
              onPressed: () => _confirmDeleteUser(context, user, provider),
            ),
          ),
          // Note: Verify button removed - all NGOs are auto-verified
        ],
      ),
    );
  }

  void _confirmDeleteUser(
      BuildContext context, UserModel user, AdminProvider provider) {
    final userName = user.organizationName ?? user.userName ?? user.email;
    final roleLabel = user.role == UserRole.ngo ? 'NGO' : 'Donor';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Delete $roleLabel Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Are you sure you want to permanently delete the following account?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $userName',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Email: ${user.email}'),
                  Text('Role: $roleLabel'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠ This action is irreversible. All associated data (donations, claims, requests) will be permanently deleted.',
              style: TextStyle(
                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteUser(user.uid);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '$userName has been deleted.'
                          : 'Failed to delete account. Please try again.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
