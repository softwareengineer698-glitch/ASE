import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        final isDonor = user.role == UserRole.donor;
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
            destinations: isDonor ? _donorDestinations : _ngoDestinations,
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        );
      },
    );
  }

  List<NavigationDestination> get _donorDestinations => [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: 'home'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_outlined),
          selectedIcon: const Icon(Icons.inventory),
          label: 'surplus'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard),
          label: 'Leaders',
        ),
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: 'forecast'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: 'profile'.tr(),
        ),
      ];

  List<NavigationDestination> get _ngoDestinations => [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: 'home'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.local_shipping_outlined),
          selectedIcon: const Icon(Icons.local_shipping),
          label: 'pickups'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard),
          label: 'Leaders',
        ),
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: 'forecast'.tr(),
        ),
        NavigationDestination(
          icon: const Icon(Icons.business_outlined),
          selectedIcon: const Icon(Icons.business),
          label: 'profile'.tr(),
        ),
      ];
}
