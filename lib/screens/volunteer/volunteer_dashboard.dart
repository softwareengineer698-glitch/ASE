import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/volunteer_model.dart';
import '../../models/delivery_model.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<VolunteerProvider>(context, listen: false)
            .initialize(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteerProvider>(
      builder: (context, volunteerProvider, child) {
        final volunteer = volunteerProvider.currentVolunteer;

        return Scaffold(
          appBar: _buildAppBar(volunteerProvider),
          body: RefreshIndicator(
            onRefresh: () async {
              // Refresh logic
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(volunteerProvider),
                  const SizedBox(height: 24),
                  _buildStatsRow(volunteer),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Active Deliveries'),
                  const SizedBox(height: 12),
                  _buildDeliveriesList(volunteerProvider),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Available Tasks Nearby'),
                  const SizedBox(height: 12),
                  _buildAvailableTasksList(volunteerProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(VolunteerProvider provider) {
    return AppBar(
      title: const Text('Volunteer Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusCard(VolunteerProvider provider) {
    final bool isAvailable = provider.isAvailable;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.grey.shade400, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              isAvailable ? Icons.directions_run : Icons.bedtime,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isAvailable
                      ? 'Ready to accept new deliveries'
                      : 'Switch online to start helping',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (val) => provider.toggleAvailability(),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(VolunteerModel? volunteer) {
    return Row(
      children: [
        _buildStatItem('Deliveries', '${volunteer?.completedDeliveries ?? 0}',
            Icons.local_shipping, Colors.blue),
        const SizedBox(width: 16),
        _buildStatItem(
            'Rating',
            volunteer?.performanceScore.toStringAsFixed(1) ?? '5.0',
            Icons.star,
            Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList(VolunteerProvider provider) {
    if (provider.assignedDeliveries.isEmpty) {
      return _buildEmptyState(
          'No active deliveries', 'Deliveries you accept will appear here.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.assignedDeliveries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final delivery = provider.assignedDeliveries[index];
        return _buildDeliveryCard(delivery, provider);
      },
    );
  }

  Widget _buildDeliveryCard(
      DeliveryModel delivery, VolunteerProvider provider) {
    String statusLabel = delivery.status.toUpperCase();
    Color statusColor = Colors.blue;
    if (delivery.status == 'picked_up') {
      statusLabel = 'IN TRANSIT';
      statusColor = Colors.orange;
    } else if (delivery.status == 'delivered') {
      statusLabel = 'COMPLETED';
      statusColor = Colors.green;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_bag, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery #${delivery.id.substring(0, 5)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('Ready for next step',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          delivery.status == 'pending'
                              ? 'Pickup: Tap for address'
                              : 'Drop-off: Tap for address',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (delivery.status == 'pending')
                  ElevatedButton(
                    onPressed: () =>
                        provider.updateDeliveryStatus(delivery.id, 'picked_up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Picked Up'),
                  )
                else if (delivery.status == 'picked_up')
                  ElevatedButton(
                    onPressed: () =>
                        provider.updateDeliveryStatus(delivery.id, 'delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Delivered'),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTasksList(VolunteerProvider provider) {
    if (provider.availableTasks.isEmpty) {
      return _buildEmptyState('No tasks nearby',
          'Tasks in your area will show up when donors report surplus.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.availableTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = provider.availableTasks[index];
        return _buildAvailableTaskCard(task, provider);
      },
    );
  }

  Widget _buildAvailableTaskCard(
      DeliveryModel task, VolunteerProvider provider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Assigned by NGO',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Location: Search Area',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _confirmClaimTask(task, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept Task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClaimTask(DeliveryModel task, VolunteerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Delivery Task?'),
        content: const Text(
            'By accepting, you commit to picking up and delivering this food package safely.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.claimDelivery(task.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
