import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
            title: Text('history'.tr()),
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              tabs: isDonor ? _getDonorTabs() : _getNGOTabs(),
            ),
          ),
          body: _isLoading
              ? LoadingWidget(message: 'loading_history'.tr())
              : TabBarView(
                  controller: _tabController,
                  children: isDonor ? _getDonorTabViews() : _getNGOTabViews(),
                ),
        );
      },
    );
  }

  List<Tab> _getDonorTabs() {
    return [
      Tab(text: 'all'.tr(), icon: const Icon(Icons.list)),
      Tab(text: 'active'.tr(), icon: const Icon(Icons.pending_actions)),
      Tab(text: 'completed'.tr(), icon: const Icon(Icons.check_circle)),
    ];
  }

  List<Tab> _getNGOTabs() {
    return [
      Tab(text: 'all'.tr(), icon: const Icon(Icons.list)),
      Tab(text: 'accepted'.tr(), icon: const Icon(Icons.handshake)),
      Tab(text: 'collected'.tr(), icon: const Icon(Icons.check_circle)),
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
    return EmptyStateWidget(
      icon: Icons.volunteer_activism,
      title: 'no_donations_yet'.tr(),
      message: 'start_donating_message'.tr(),
      actionText: 'make_donation'.tr(),
    );
  }

  Widget _buildDonorActiveHistory() {
    return EmptyStateWidget(
      icon: Icons.pending_actions,
      title: 'no_active_donations'.tr(),
      message: 'no_pending_donations'.tr(),
    );
  }

  Widget _buildDonorCompletedHistory() {
    return EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: 'no_completed_donations'.tr(),
      message: 'completed_donations_message'.tr(),
    );
  }

  Widget _buildNGOAllHistory() {
    return EmptyStateWidget(
      icon: Icons.business,
      title: 'no_requests_yet'.tr(),
      message: 'start_accepting_message'.tr(),
      actionText: 'browse_donations'.tr(),
    );
  }

  Widget _buildNGOAcceptedHistory() {
    return EmptyStateWidget(
      icon: Icons.handshake,
      title: 'no_accepted_donations'.tr(),
      message: 'accepted_donations_message'.tr(),
    );
  }

  Widget _buildNGOCollectedHistory() {
    return EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: 'no_collected_donations'.tr(),
      message: 'collected_donations_message'.tr(),
    );
  }
}
