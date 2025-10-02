import 'package:flutter/material.dart';
import '../../models/surplus_item.dart';
import '../../services/local_surplus_service.dart';
import '../../services/notification_service.dart';

class SurplusListScreen extends StatefulWidget {
  final String ngoName;

  const SurplusListScreen({
    super.key,
    required this.ngoName,
  });

  @override
  State<SurplusListScreen> createState() => _SurplusListScreenState();
}

class _SurplusListScreenState extends State<SurplusListScreen> {
  final _surplusService = LocalSurplusService();
  final _notificationService = NotificationService();
  List<SurplusItem> _surplusItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _surplusService.addListener(_onSurplusItemsChanged);
  }

  @override
  void dispose() {
    _surplusService.removeListener(_onSurplusItemsChanged);
    super.dispose();
  }

  void _initializeData() {
    // Initialize mock data if needed
    _surplusService.initializeMockData();
    _loadSurplusItems();
  }

  void _onSurplusItemsChanged(List<SurplusItem> items) {
    if (mounted) {
      setState(() {
        _surplusItems = items;
        _isLoading = false;
      });
    }
  }

  void _loadSurplusItems() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _surplusItems = _surplusService.getAllSurplusItems();
          _isLoading = false;
        });
      }
    });
  }

  List<SurplusItem> get _filteredItems {
    switch (_selectedFilter) {
      case 'Available':
        return _surplusItems
            .where((item) => item.status == SurplusStatus.available && !item.isExpired)
            .toList();
      case 'Accepted':
        return _surplusItems
            .where((item) => item.status == SurplusStatus.accepted)
            .toList();
      case 'Expired':
        return _surplusItems
            .where((item) => item.isExpired || item.status == SurplusStatus.expired)
            .toList();
      default:
        return _surplusItems;
    }
  }

  Future<void> _acceptSurplusItem(SurplusItem item) async {
    // Show confirmation dialog
    final confirmed = await _showAcceptConfirmationDialog(item);
    if (!confirmed) return;

    try {
      final success = await _surplusService.acceptSurplusItem(
        item.id,
        widget.ngoName,
      );

      if (success) {
        // Send notification to donor about acceptance
        await _notificationService.notifySurplusAccepted(
          ngoName: widget.ngoName,
          foodType: item.foodType,
          donorName: item.donorName,
        );
        
        _showSuccessSnackBar('Successfully accepted "${item.foodType}"');
      } else {
        _showErrorSnackBar('Failed to accept item. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: ${e.toString()}');
    }
  }

  Future<bool> _showAcceptConfirmationDialog(SurplusItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Surplus Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to accept this surplus item?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Quantity: ${item.quantity}'),
                    Text('Donor: ${item.donorName}'),
                    Text('Expires: ${item.formattedExpiryDate}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Surplus'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadSurplusItems,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Available',
                  'Accepted',
                  'Expired',
                ].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading surplus items...'),
                      ],
                    ),
                  )
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async => _loadSurplusItems(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildSurplusItemCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'Available':
        message = 'No available surplus items at the moment.\nCheck back later!';
        icon = Icons.inventory_2_outlined;
        break;
      case 'Accepted':
        message = 'No accepted items yet.\nStart accepting surplus items!';
        icon = Icons.check_circle_outline;
        break;
      case 'Expired':
        message = 'No expired items found.\nThat\'s great news!';
        icon = Icons.schedule_outlined;
        break;
      default:
        message = 'No surplus items found.\nItems will appear here when donors report surplus food.';
        icon = Icons.restaurant_menu_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSurplusItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurplusItemCard(SurplusItem item) {
    final isExpired = item.isExpired;
    final isExpiringSoon = item.isExpiringSoon;
    final canAccept = item.status == SurplusStatus.available && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.foodType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'by ${item.donorName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(item.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.scale, 'Quantity', '${item.quantity}'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildDetailItem(
                    Icons.schedule,
                    'Expires',
                    item.formattedExpiryDate,
                    textColor: isExpired 
                        ? Colors.red 
                        : isExpiringSoon 
                            ? Colors.orange 
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              Icons.access_time,
              'Reported',
              _formatReportedDate(item.reportedDate),
            ),

            // Action Button
            if (canAccept) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptSurplusItem(item),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept This Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (item.status == SurplusStatus.accepted) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Item accepted - Ready for collection',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SurplusStatus status) {
    switch (status) {
      case SurplusStatus.available:
        return Colors.green;
      case SurplusStatus.accepted:
        return Colors.blue;
      case SurplusStatus.collected:
        return Colors.purple;
      case SurplusStatus.expired:
        return Colors.red;
    }
  }

  String _formatReportedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
