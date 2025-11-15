import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../home/donor_dashboard_new.dart';
import '../home/ngo_dashboard_new.dart';
import '../history/history_screen.dart';
import '../profile/donor_profile_screen.dart';
import '../profile/ngo_profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../forecast/forecast_dashboard.dart';
import '../auth/sign_in_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;

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
      },
    );
  }

  List<Widget> _getDonorScreens() {
    return [
      const DonorDashboard(),           // Home
      const HistoryScreen(),            // Surplus/History
      const LeaderboardScreen(),        // Leaderboard
      const ForecastDashboard(),        // Forecast
      const DonorProfileScreen(),       // Profile
    ];
  }

  List<Widget> _getNGOScreens() {
    return [
      const NGODashboard(),             // Home (Available Surplus)
      const HistoryScreen(),            // Active Pickups (reusing history for now)
      const LeaderboardScreen(),        // Leaderboard
      const ForecastDashboard(),        // Forecast
      const NGOProfileScreen(),         // Profile
    ];
  }
}

// Helper widget for smooth page transitions
class PageTransitionWrapper extends StatelessWidget {
  final Widget child;
  final String title;

  const PageTransitionWrapper({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: title,
      child: Material(
        child: child,
      ),
    );
  }
}
