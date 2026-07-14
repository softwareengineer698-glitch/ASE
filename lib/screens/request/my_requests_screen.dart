import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_request_service.dart';
import '../../models/food_request_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_request_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FoodRequestService _requestService = FoodRequestService();
  List<FoodRequest> _requests = [];
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId != null) {
        _requests = await _requestService.getRequestsByUser(userId);
        _stats = await _requestService.getUserRequestStats(userId);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('my_requests'.tr()),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'create_request'.tr(),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
            ).then((_) => _loadRequests()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats row
                _buildStatsRow(),

                // Requests list with tabs
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: 'active'.tr()),
                            Tab(text: 'fulfilled'.tr()),
                            Tab(text: 'all'.tr()),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildRequestList(_requests.where((r) => r.isActive).toList()),
                              _buildRequestList(_requests.where((r) => r.status == RequestStatus.fulfilled).toList()),
                              _buildRequestList(_requests),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('total'.tr(), _stats['total'] ?? 0, Icons.list_alt, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('pending'.tr(), _stats['pending'] ?? 0, Icons.hourglass_empty, Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard('fulfilled'.tr(), _stats['fulfilled'] ?? 0, Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('expired'.tr(), _stats['expired'] ?? 0, Icons.cancel, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: DashboardCard(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<FoodRequest> requests) {
    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.request_page,
        title: 'no_requests_found'.tr(),
        message: 'create_first_request'.tr(),
        actionText: 'create_request'.tr(),
        onActionPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
        ).then((_) => _loadRequests()),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(FoodRequest request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case RequestStatus.pending:
        statusColor = request.hoursRemaining < 0 ? Colors.grey : Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case RequestStatus.fulfilled:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.expired:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
    }

    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  request.foodType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      request.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quantity and deadline
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${request.quantity} ${request.unit}'),
              const Spacer(),
              Icon(Icons.access_time, size: 16, color: request.urgencyColor),
              const SizedBox(width: 4),
              if (request.status == RequestStatus.pending)
                Text(
                  request.hoursRemaining > 0
                      ? '${'in'.tr()} ${request.hoursRemaining}h'
                      : 'overdue'.tr(),
                  style: TextStyle(color: request.urgencyColor),
                )
              else if (request.status == RequestStatus.fulfilled && request.fulfilledAt != null)
                Text(
                  '${'fulfilled_on'.tr()} ${request.fulfilledAt!.day}/${request.fulfilledAt!.month}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),

          // Fulfilled by (if applicable)
          if (request.fulfilledByDonorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volunteer_activism, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${'fulfilled_by'.tr()} ${request.fulfilledByDonorName}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],

          // Actions
          if (request.status == RequestStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelRequest(request),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text('cancel'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteRequest(request),
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text('delete'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _cancelRequest(FoodRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cancel_request'.tr()),
        content: Text('confirm_cancel_request'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no_keep'.tr()),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _requestService.cancelRequest(request.id);
                _showSuccessSnackBar('request_cancelled'.tr());
                _loadRequests();
              } catch (e) {
                _showErrorSnackBar('Failed to cancel request: $e');
              }
            },
            icon: const Icon(Icons.check),
            label: Text('yes_cancel'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _deleteRequest(FoodRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_request'.tr()),
        content: Text('confirm_delete_request'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _requestService.deleteRequest(request.id);
                _showSuccessSnackBar('request_deleted'.tr());
                _loadRequests();
              } catch (e) {
                _showErrorSnackBar('Failed to delete request: $e');
              }
            },
            icon: const Icon(Icons.delete),
            label: Text('delete'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
