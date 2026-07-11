import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'responsive_widget.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    required this.currentIndex, required this.onTap, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.primaryContainer,
            destinations: _getDestinationsForRole(user.role),
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        );
      },
    );
  }

  List<NavigationDestination> _getDestinationsForRole(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return _donorDestinations;
      case UserRole.ngo:
        return _ngoDestinations;
      case UserRole.volunteer:
        return _volunteerDestinations;
      case UserRole.admin:
        return _adminDestinations;
    }
  }

  List<NavigationDestination> get _donorDestinations => [
        _buildDest(Icons.home, Icons.home_outlined, 'home'),
        _buildDest(Icons.shopping_cart, Icons.shopping_cart_outlined, 'accept'),
        _buildDest(Icons.analytics, Icons.analytics_outlined, 'impact'),
        _buildDest(Icons.inventory, Icons.inventory_outlined, 'surplus'),
        _buildDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  List<NavigationDestination> get _ngoDestinations => [
        _buildDest(Icons.home, Icons.home_outlined, 'home'),
        _buildDest(Icons.volunteer_activism, Icons.volunteer_activism_outlined,
            'donate'),
        _buildDest(Icons.analytics, Icons.analytics_outlined, 'impact'),
        _buildDest(
            Icons.local_shipping, Icons.local_shipping_outlined, 'pickups'),
        _buildDest(Icons.business, Icons.business_outlined, 'profile'),
      ];

  List<NavigationDestination> get _volunteerDestinations => [
        _buildDest(Icons.home, Icons.home_outlined, 'home'),
        _buildDest(
            Icons.local_shipping, Icons.local_shipping_outlined, 'logistics'),
        _buildDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  List<NavigationDestination> get _adminDestinations => [
        _buildDest(Icons.dashboard, Icons.dashboard_outlined, 'admin'),
        _buildDest(Icons.person, Icons.person_outline, 'profile'),
      ];

  NavigationDestination _buildDest(
      IconData selected, IconData unselected, String labelKey) {
    return NavigationDestination(
      icon: TouchTargetSize(
        child: Icon(unselected),
      ),
      selectedIcon: TouchTargetSize(
        child: Icon(selected),
      ),
      label: labelKey.tr(),
    );
  }
}
