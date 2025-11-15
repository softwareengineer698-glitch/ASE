import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

/// Screen displaying user's donation/request history
/// Shows different content based on user role (Donor/NGO)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isDonor = user.role == UserRole.donor;

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              tabs: isDonor ? _getDonorTabs() : _getNGOTabs(),
            ),
          ),
          body: _isLoading
              ? const LoadingWidget(message: 'Loading history...')
              : TabBarView(
                  controller: _tabController,
                  children: isDonor ? _getDonorTabViews() : _getNGOTabViews(),
                ),
        );
      },
    );
  }

  List<Tab> _getDonorTabs() {
    return const [
      Tab(text: 'All', icon: Icon(Icons.list)),
      Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
      Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
    ];
  }

  List<Tab> _getNGOTabs() {
    return const [
      Tab(text: 'All', icon: Icon(Icons.list)),
      Tab(text: 'Accepted', icon: Icon(Icons.handshake)),
      Tab(text: 'Collected', icon: Icon(Icons.check_circle)),
    ];
  }

  List<Widget> _getDonorTabViews() {
    return [
      _buildDonorAllHistory(),
      _buildDonorActiveHistory(),
      _buildDonorCompletedHistory(),
    ];
  }

  List<Widget> _getNGOTabViews() {
    return [
      _buildNGOAllHistory(),
      _buildNGOAcceptedHistory(),
      _buildNGOCollectedHistory(),
    ];
  }

  Widget _buildDonorAllHistory() {
    return const EmptyStateWidget(
      icon: Icons.volunteer_activism,
      title: 'No Donations Yet',
      message: 'Start donating to help your community and see your impact here.',
      actionText: 'Make a Donation',
    );
  }

  Widget _buildDonorActiveHistory() {
    return const EmptyStateWidget(
      icon: Icons.pending_actions,
      title: 'No Active Donations',
      message: 'You don\'t have any pending donations at the moment.',
    );
  }

  Widget _buildDonorCompletedHistory() {
    return const EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: 'No Completed Donations',
      message: 'Your completed donations will appear here.',
    );
  }

  Widget _buildNGOAllHistory() {
    return const EmptyStateWidget(
      icon: Icons.business,
      title: 'No Requests Yet',
      message: 'Start accepting donations to help your community and track them here.',
      actionText: 'Browse Donations',
    );
  }

  Widget _buildNGOAcceptedHistory() {
    return const EmptyStateWidget(
      icon: Icons.handshake,
      title: 'No Accepted Donations',
      message: 'Donations you\'ve accepted will appear here.',
    );
  }

  Widget _buildNGOCollectedHistory() {
    return const EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: 'No Collected Donations',
      message: 'Donations you\'ve collected will appear here.',
    );
  }
}
