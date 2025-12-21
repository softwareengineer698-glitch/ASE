import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../screens/home/donor_dashboard_new.dart';
import '../screens/home/ngo_dashboard_new.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/donor_profile_screen.dart';
import '../screens/profile/ngo_profile_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/forecast/forecast_dashboard.dart';
import '../screens/auth/sign_in_screen.dart';

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

        final isDonor = user.role == UserRole.donor;
        final screens = isDonor ? _getDonorScreens() : _getNGOScreens();

        // Use LayoutBuilder to determine screen size
        return LayoutBuilder(
          builder: (context, constraints) {
            // Desktop/Tablet view (width > 800)
            if (constraints.maxWidth > 800) {
              return _buildDesktopView(screens, isDonor, user);
            }
            // Mobile view
            else {
              return _buildMobileView(screens);
            }
          },
        );
      },
    );
  }

  Widget _buildDesktopView(List<Widget> screens, bool isDonor, UserModel user) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            extended: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations:
                isDonor ? _donorRailDestinations : _ngoRailDestinations,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 20,
                    child: Icon(
                      isDonor ? Icons.person : Icons.business,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.userName ?? (isDonor ? 'Donor' : 'NGO'),
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
          // Main Content Area
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
    );
  }

  List<Widget> _getDonorScreens() {
    return [
      const DonorDashboard(), // Home
      const HistoryScreen(), // Surplus/History
      const LeaderboardScreen(), // Leaderboard
      const ForecastDashboard(), // Forecast
      const DonorProfileScreen(), // Profile
    ];
  }

  List<Widget> _getNGOScreens() {
    return [
      const NGODashboard(), // Home (Available Surplus)
      const HistoryScreen(), // Active Pickups
      const LeaderboardScreen(), // Leaderboard
      const ForecastDashboard(), // Forecast
      const NGOProfileScreen(), // Profile
    ];
  }

  List<NavigationRailDestination> get _donorRailDestinations => [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text('home'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.inventory_outlined),
          selectedIcon: const Icon(Icons.inventory),
          label: Text('surplus'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard),
          label: Text('leaders'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: Text('forecast'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: Text('profile'.tr()),
        ),
      ];

  List<NavigationRailDestination> get _ngoRailDestinations => [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text('home'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.local_shipping_outlined),
          selectedIcon: const Icon(Icons.local_shipping),
          label: Text('pickups'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard),
          label: Text('leaders'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: Text('forecast'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.business_outlined),
          selectedIcon: const Icon(Icons.business),
          label: Text('profile'.tr()),
        ),
      ];
}
