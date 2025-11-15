import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_confirmation_model.dart';
import '../../services/delivery_confirmation_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/empty_state_widget.dart';

/// Delivery confirmation screen with photo uploads and digital signatures
class DeliveryConfirmationScreen extends StatefulWidget {
  const DeliveryConfirmationScreen({super.key});

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DeliveryConfirmationService _deliveryService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _deliveryService = DeliveryConfirmationService();
    _deliveryService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Delivery Confirmations'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending', icon: Icon(Icons.pending)),
                Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
                Tab(text: 'All', icon: Icon(Icons.list)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingTab(themeProvider),
              _buildCompletedTab(themeProvider),
              _buildAllTab(themeProvider),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateDeliveryDialog(themeProvider),
            backgroundColor: themeProvider.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildPendingTab(ThemeProvider themeProvider) {
    return ChangeNotifierBuilder<DeliveryConfirmationService>(
      notifier: _deliveryService,
      builder: (context, service) {
        final pendingDeliveries = service.pendingDeliveries;
        
        if (pendingDeliveries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle_outline,
            title: 'No Pending Deliveries',
            message: 'All deliveries are up to date!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: pendingDeliveries.length,
          itemBuilder: (context, index) {
            return _buildDeliveryCard(pendingDeliveries[index], themeProvider);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab(ThemeProvider themeProvider) {
    return ChangeNotifierBuilder<DeliveryConfirmationService>(
      notifier: _deliveryService,
      builder: (context, service) {
        final completedDeliveries = service.completedDeliveries;
        
        if (completedDeliveries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history,
            title: 'No Completed Deliveries',
            message: 'Completed deliveries will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: completedDeliveries.length,
          itemBuilder: (context, index) {
            return _buildDeliveryCard(completedDeliveries[index], themeProvider);
          },
        );
      },
    );
  }

  Widget _buildAllTab(ThemeProvider themeProvider) {
    return ChangeNotifierBuilder<DeliveryConfirmationService>(
      notifier: _deliveryService,
      builder: (context, service) {
        final allDeliveries = service.allDeliveries;
        
        return Column(
          children: [
            _buildStatsCard(service, themeProvider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: allDeliveries.length,
                itemBuilder: (context, index) {
                  return _buildDeliveryCard(allDeliveries[index], themeProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(DeliveryConfirmationService service, ThemeProvider themeProvider) {
    final stats = service.getDeliveryStats();
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Total', '${stats['total']}', Icons.all_inbox)),
                Expanded(child: _buildStatItem('Confirmed', '${stats['confirmed']}', Icons.verified)),
                Expanded(child: _buildStatItem('Pending', '${stats['pending']}', Icons.pending)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDeliveryCard(DeliveryConfirmation delivery, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(delivery.status.colorValue),
          child: Icon(
            _getStatusIcon(delivery.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${delivery.donorName} → ${delivery.ngoName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${delivery.quantityDelivered}kg ${delivery.foodCategory}'),
            Text('Status: ${delivery.statusDisplayName}'),
            Text('Date: ${delivery.formattedDeliveryDate}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (delivery.photos.isNotEmpty)
              Icon(Icons.photo_camera, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            if (delivery.donorSignature != null)
              Icon(Icons.edit, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            if (delivery.ngoSignature != null)
              Icon(Icons.verified_user, size: 16, color: Colors.purple),
          ],
        ),
        onTap: () => _showDeliveryDetails(delivery, themeProvider),
      ),
    );
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Icons.schedule;
      case DeliveryStatus.inProgress:
        return Icons.local_shipping;
      case DeliveryStatus.completed:
        return Icons.check;
      case DeliveryStatus.confirmed:
        return Icons.verified;
      case DeliveryStatus.rejected:
        return Icons.cancel;
    }
  }

  void _showDeliveryDetails(DeliveryConfirmation delivery, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delivery Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donor: ${delivery.donorName}'),
              Text('NGO: ${delivery.ngoName}'),
              Text('Quantity: ${delivery.quantityDelivered}kg'),
              Text('Category: ${delivery.foodCategory}'),
              Text('Status: ${delivery.statusDisplayName}'),
              if (delivery.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Notes: ${delivery.notes}'),
              ],
              const SizedBox(height: 16),
              Text('Photos: ${delivery.photos.length}'),
              Text('Signatures: ${delivery.donorSignature != null ? "✓" : "✗"} Donor, ${delivery.ngoSignature != null ? "✓" : "✗"} NGO'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (delivery.requiresAction)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showActionDialog(delivery, themeProvider);
              },
              child: const Text('Take Action'),
            ),
        ],
      ),
    );
  }

  void _showActionDialog(DeliveryConfirmation delivery, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Add Photo'),
              onTap: () => _addPhoto(delivery.id),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Add Signature'),
              onTap: () => _addSignature(delivery.id),
            ),
            if (delivery.isComplete)
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Confirm Delivery'),
                onTap: () => _confirmDelivery(delivery.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateDeliveryDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Delivery Confirmation'),
        content: const Text('This would open a form to create a new delivery confirmation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createMockDelivery();
            },
            child: const Text('Create Mock'),
          ),
        ],
      ),
    );
  }

  void _addPhoto(String deliveryId) {
    Navigator.of(context).pop();
    _deliveryService.addPhoto(
      deliveryId: deliveryId,
      filePath: '/mock/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      type: PhotoType.delivery,
      caption: 'Mock photo added',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo added successfully!')),
    );
  }

  void _addSignature(String deliveryId) {
    Navigator.of(context).pop();
    _deliveryService.addSignature(
      deliveryId: deliveryId,
      signatureData: 'mock_signature_data',
      signerName: 'Current User',
      signerRole: 'donor',
      signerEmail: 'user@example.com',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signature added successfully!')),
    );
  }

  void _confirmDelivery(String deliveryId) {
    Navigator.of(context).pop();
    _deliveryService.confirmDelivery(deliveryId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery confirmed successfully!')),
    );
  }

  void _createMockDelivery() {
    _deliveryService.createDeliveryConfirmation(
      donationId: 'donation_${DateTime.now().millisecondsSinceEpoch}',
      donorId: 'current_user',
      ngoId: 'ngo_${DateTime.now().millisecondsSinceEpoch}',
      donorName: 'Test Donor',
      ngoName: 'Test NGO',
      deliveryDate: DateTime.now(),
      quantityDelivered: 10.0,
      foodCategory: 'Test Category',
      notes: 'Mock delivery for testing',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mock delivery created!')),
    );
  }
}

/// Helper widget for ChangeNotifier
class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  final T notifier;
  final Widget Function(BuildContext context, T notifier) builder;

  const ChangeNotifierBuilder({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  State<ChangeNotifierBuilder<T>> createState() => _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier> extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }
}
