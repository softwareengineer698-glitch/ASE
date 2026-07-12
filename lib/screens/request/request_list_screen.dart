import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_request_service.dart';
import '../../models/food_request_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../chat/chat_screen.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final FoodRequestService _requestService = FoodRequestService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<FoodRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      _requests = await _requestService.getActiveRequests();
    } catch (e) {
      _showErrorSnackBar('Failed to load requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<FoodRequest> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    final query = _searchQuery.toLowerCase();
    return _requests.where((req) {
      return req.foodType.toLowerCase().contains(query) ||
          req.organizationName.toLowerCase().contains(query) ||
          req.description.toLowerCase().contains(query);
    }).toList();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('food_requests'.tr()),
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
          IconButton(
            icon: const Icon(Icons.my_library_books),
            tooltip: 'my_requests'.tr(),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_requests'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Stats row
          _buildStatsRow(),

          // Request list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.request_page,
                        title: 'no_requests_available'.tr(),
                        message: 'be_first_to_request'.tr(),
                        actionText: 'create_request'.tr(),
                        onActionPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateRequestScreen()),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return _buildRequestCard(request, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeCount = _requests.where((r) => r.isActive).length;
    final urgentCount = _requests.where((r) => r.isActive && r.isUrgent).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DashboardCard(
              child: Row(
                children: [
                  const Icon(Icons.request_quote, color: Colors.blue),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$activeCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('active_requests'.tr(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DashboardCard(
              child: Row(
                children: [
                  Icon(Icons.warning, color: urgentCount > 0 ? Colors.red : Colors.grey),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$urgentCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('urgent'.tr(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(FoodRequest request, ColorScheme colorScheme) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    final isOwnRequest = request.userId == currentUserId;

    return DashboardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with urgency badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.foodType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isOwnRequest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Your Request',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                  ),
                if (request.isUrgent && !isOwnRequest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.priority_high, size: 12, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Urgent',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(request.organizationName,
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${request.quantity} ${request.unit}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (request.description.isNotEmpty)
              Text(request.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: request.urgencyColor),
                const SizedBox(width: 4),
                Text(
                  request.hoursRemaining > 0
                      ? '${'expires_in'.tr()} ${request.hoursRemaining}h'
                      : 'expired'.tr(),
                  style: TextStyle(
                      fontSize: 12,
                      color: request.urgencyColor,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (!isOwnRequest) ...[
                  // Chat button
                  OutlinedButton.icon(
                    onPressed: () => _openChatWithRequester(request),
                    icon: const Icon(Icons.chat_outlined, size: 14),
                    label: const Text('Chat', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _fulfillRequest(request),
                    icon: const Icon(Icons.handshake, size: 16),
                    label: Text('fulfill'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.block, size: 14, color: Colors.grey),
                    label: const Text('Your own',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(FoodRequest request) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    final isOwnRequest = request.userId == currentUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.foodType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('organization'.tr(), request.organizationName),
              _buildDetailRow('quantity'.tr(),
                  '${request.quantity} ${request.unit}'),
              _buildDetailRow('needed_by'.tr(),
                  '${request.neededBy.day}/${request.neededBy.month}/${request.neededBy.year}'),
              if (request.description.isNotEmpty)
                _buildDetailRow('description'.tr(), request.description),
              if (request.location != null)
                _buildDetailRow('location'.tr(), request.location!),
              // Requester contact info (visible to other users)
              if (!isOwnRequest) ...[
                const Divider(height: 24),
                const Text('Contact Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(request.userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final phone = data?['phone'] as String? ?? '';
                    final email = data?['email'] as String? ?? '';
                    final address = data?['address'] as String? ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email.isNotEmpty) _buildDetailRow('Email', email),
                        if (phone.isNotEmpty) _buildDetailRow('Phone', phone),
                        if (address.isNotEmpty)
                          _buildDetailRow('Address', address),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: request.urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: request.urgencyColor),
                    const SizedBox(width: 8),
                    Text(
                      request.hoursRemaining > 0
                          ? '${request.hoursRemaining} ${'hours_remaining'.tr()}'
                          : 'request_expired'.tr(),
                      style: TextStyle(
                          color: request.urgencyColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
          if (!isOwnRequest) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openChatWithRequester(request);
              },
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: const Text('Chat'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _fulfillRequest(request);
              },
              icon: const Icon(Icons.handshake),
              label: Text('fulfill_request'.tr()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _fulfillRequest(FoodRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    // ── Block self-fulfillment ──────────────────────────────────────────────
    if (request.userId == currentUser.uid) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Text('Cannot Fulfill'),
          ]),
          content: const Text(
              'You cannot fulfill your own food request.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final userName = currentUser.userName ??
        currentUser.email.split('@')[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('fulfill_request'.tr()),
        content: Text(
            'confirm_fulfill_request'.tr(args: [request.foodType])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _requestService.fulfillRequest(
                  requestId: request.id,
                  donorId: currentUser.uid,
                  donorName: userName,
                );
                _showSuccessSnackBar('request_fulfilled_success'.tr());
                _loadRequests();
              } catch (e) {
                _showErrorSnackBar('Failed to fulfill request: $e');
              }
            },
            icon: const Icon(Icons.check),
            label: Text('confirm'.tr()),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithRequester(FoodRequest request) async {
    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return;
    if (request.userId == currentUser.uid) return;

    try {
      final db = FirebaseFirestore.instance;
      String? roomId;

      final existing = await db
          .collection('chat_rooms')
          .where('requestId', isEqualTo: request.id)
          .where('participantIds', arrayContains: currentUser.uid)
          .get();

      for (final doc in existing.docs) {
        final p = List<String>.from(doc.data()['participantIds'] ?? []);
        if (p.contains(request.userId)) {
          roomId = doc.id;
          break;
        }
      }

      if (roomId == null) {
        final ref = db.collection('chat_rooms').doc();
        await ref.set({
          'participantIds': [currentUser.uid, request.userId],
          'requestId': request.id,
          'lastMessage': null,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'type': 'request_fulfillment',
          'unreadCounts': {currentUser.uid: 0, request.userId: 0},
        });
        roomId = ref.id;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: roomId!,
            otherUserName: request.organizationName,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Could not open chat: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}