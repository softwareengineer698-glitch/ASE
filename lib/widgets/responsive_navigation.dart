import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../widgets/tracking_info_sheet.dart';
import '../screens/home/unified_dashboard.dart';
import '../screens/profile/unified_profile_screen.dart';
import '../screens/impact/donor_impact_screen.dart';
import '../screens/donor/create_donation_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/volunteer/volunteer_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/common/deliveries_screen.dart';
import '../screens/profile/profile_screen.dart';

class ResponsiveNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const ResponsiveNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ResponsiveNavigationWrapper> createState() =>
      _ResponsiveNavigationWrapperState();
}

class _ResponsiveNavigationWrapperState
    extends State<ResponsiveNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // Show tracking info explainer once per install — first-use only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TrackingInfoSheet.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const SignInScreen();
        }

        final screens = _getScreensForRole(user.role);

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildDesktopView(screens, user);
            } else {
              return _buildMobileView(screens);
            }
          },
        );
      },
    );
  }

  List<Widget> _getScreensForRole(UserRole role) {
    switch (role) {
      case UserRole.donor:
      case UserRole.ngo:
        return _getUnifiedScreens();
      case UserRole.volunteer:
        return _getVolunteerScreens();
      case UserRole.admin:
        return _getAdminScreens();
    }
  }

  Widget _buildDesktopView(List<Widget> screens, UserModel user) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            extended: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: _getRailDestinations(user.role),
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: _getUserProfileImageUrl(user.uid),
                    builder: (context, snapshot) {
                      final imageUrl = snapshot.data;
                      return CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 20,
                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl) as ImageProvider
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? Icon(
                                _getRoleIcon(user.role),
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.userName ?? user.role.displayName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView(List<Widget> screens) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      // Persistent help button — opens the tracking info explainer
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.small(
              heroTag: 'tracking_help_fab',
              onPressed: () => TrackingInfoSheet.show(context),
              tooltip: 'show_tracking_info'.tr(),
              child: const Icon(Icons.info_outline_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return Icons.person;
      case UserRole.ngo:
        return Icons.business;
      case UserRole.volunteer:
        return Icons.directions_run;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  List<NavigationRailDestination> _getRailDestinations(UserRole role) {
    switch (role) {
      case UserRole.donor:
      case UserRole.ngo:
        return _unifiedRailDestinations;
      case UserRole.volunteer:
        return _volunteerRailDestinations;
      case UserRole.admin:
        return _adminRailDestinations;
    }
  }

  List<Widget> _getUnifiedScreens() {
    return [
      const UnifiedDashboard(),
      const CreateDonationScreen(),
      const DonorImpactScreen(),
      const DeliveriesScreen(),
      const UnifiedProfileScreen(),
    ];
  }

  List<Widget> _getVolunteerScreens() {
    return [
      const VolunteerDashboard(),
      const DeliveriesScreen(),
      const UnifiedProfileScreen(),
    ];
  }

  List<Widget> _getAdminScreens() {
    return [
      const AdminDashboard(),
      const ProfileScreen(),
    ];
  }

  List<NavigationRailDestination> get _unifiedRailDestinations => [
        _buildRailDest(Icons.home, Icons.home_outlined, 'home'),
        _buildRailDest(Icons.volunteer_activism, Icons.volunteer_activism_outlined, 'donate'),
        _buildRailDest(Icons.analytics, Icons.analytics_outlined, 'impact'),
        _buildRailDest(Icons.local_shipping, Icons.local_shipping_outlined, 'transport'),
        _buildRailDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  List<NavigationRailDestination> get _volunteerRailDestinations => [
        _buildRailDest(Icons.home, Icons.home_outlined, 'home'),
        _buildRailDest(Icons.local_shipping, Icons.local_shipping_outlined, 'logistics'),
        _buildRailDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  List<NavigationRailDestination> get _adminRailDestinations => [
        _buildRailDest(Icons.dashboard, Icons.dashboard_outlined, 'admin'),
        _buildRailDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  NavigationRailDestination _buildRailDest(
      IconData selected, IconData unselected, String labelKey) {
    return NavigationRailDestination(
      icon: Icon(unselected),
      selectedIcon: Icon(selected),
      label: Text(labelKey.tr()),
    );
  }

  Future<String?> _getUserProfileImageUrl(String uid) async {
    // Guard: if the user has logged out, the uid may be stale — fail silently
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['profileImageUrl'] as String?;
      }
    } catch (_) {
      // Permission denied when logging out — suppress silently
    }
    return null;
  }
}
