import 'package:flutter/material.dart';
import '../../widgets/responsive_navigation.dart';

class MainNavigationWrapper extends StatelessWidget {
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavigationWrapper(
      initialIndex: initialIndex,
    );
  }
}

// Helper widget for smooth page transitions
class PageTransitionWrapper extends StatelessWidget {
  final Widget child;
  final String title;

  const PageTransitionWrapper({
    required this.child, required this.title, super.key,
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
