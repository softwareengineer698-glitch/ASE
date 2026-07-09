import 'package:flutter/material.dart';
import 'main_navigation_wrapper.dart';
import '../../widgets/tracking_info_sheet.dart';

/// Main wrapper that provides bottom navigation for authenticated users
/// Routes to appropriate dashboard based on user role
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TrackingInfoSheet.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainNavigationWrapper();
  }
}
