import 'package:flutter/material.dart';
import 'main_navigation_wrapper.dart';

/// Main wrapper that provides bottom navigation for authenticated users
/// Routes to appropriate dashboard based on user role
class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationWrapper();
  }
}
