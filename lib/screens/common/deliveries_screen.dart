import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/delivery_model.dart';
import '../../widgets/dashboard_card.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        final provider = Provider.of<VolunteerProvider>(context, listen: false);
        if (user.role == UserRole.volunteer) {
          provider.initialize(user.uid);
        } else if (user.role == UserRole.ngo) {
          provider.initializeForNGO(user.uid);
        } else if (user.role == UserRole.donor) {
          provider.initializeForDonor(user.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteerProvider>(
      builder: (context, provider, child) {
        final user = Provider.of<AuthProvider>(context).user;
        final title = _getTitle(user?.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(provider, user?.role),
        );
      },
    );
  }

  String _getTitle(UserRole? role) {
    switch (role) {
      case UserRole.volunteer:
        return 'Logistics Tasks';
      case UserRole.ngo:
        return 'Transport Tracking';
      case UserRole.donor:
        return 'Outgoing Pickups';
      default:
        return 'Deliveries';
    }
  }

  Widget _buildContent(VolunteerProvider provider, UserRole? role) {
    final deliveries = provider.assignedDeliveries;

    if (deliveries.isEmpty &&
        (role != UserRole.volunteer || provider.availableTasks.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No active deliveries found',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (role == UserRole.volunteer &&
            provider.availableTasks.isNotEmpty) ...[
          _buildSectionHeader('Available for Pickup'),
          ...provider.availableTasks
              .map((d) => _buildDeliveryCard(d, provider, true)),
          const SizedBox(height: 24),
        ],
        if (deliveries.isNotEmpty) ...[
          _buildSectionHeader(role == UserRole.volunteer
              ? 'My Active Jobs'
              : 'Tracked Deliveries'),
          ...deliveries.map((d) => _buildDeliveryCard(d, provider, false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeliveryCard(
      DeliveryModel delivery, VolunteerProvider provider, bool isAvailable) {
    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(delivery.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delivery.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(delivery.status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '#${delivery.id.substring(0, 5)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            delivery.notes ?? 'Standard Transport Job',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          if (isAvailable)
            ElevatedButton(
              onPressed: () => provider.claimDelivery(delivery.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Claim Task',
                  style: TextStyle(color: Colors.white)),
            )
          else ...[
            _buildStatusTimeline(delivery),
            if (Provider.of<AuthProvider>(context, listen: false).user?.role ==
                UserRole.volunteer)
              _buildControlButtons(delivery, provider),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(DeliveryModel delivery) {
    return Column(
      children: [
        _buildTimelineItem(Icons.location_on, 'Donor Location',
            delivery.status == 'pending' || delivery.status == 'picked_up'),
        _buildTimelineItem(
            Icons.local_shipping, 'In Transit', delivery.status == 'picked_up'),
        _buildTimelineItem(Icons.check_circle, 'Safe Handover',
            delivery.status == 'delivered'),
      ],
    );
  }

  Widget _buildTimelineItem(IconData icon, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.blue : Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildControlButtons(
      DeliveryModel delivery, VolunteerProvider provider) {
    if (delivery.status == 'delivered') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final nextStatus =
                    delivery.status == 'pending' ? 'picked_up' : 'delivered';
                provider.updateDeliveryStatus(delivery.id, nextStatus);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                  delivery.status == 'pending'
                      ? 'Mark Picked Up'
                      : 'Mark Delivered',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
