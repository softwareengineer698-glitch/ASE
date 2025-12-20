import 'package:flutter/material.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 800 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final defaultPadding = padding ??
            EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
              vertical: 16.0,
            );

        return Container(
          width: double.infinity,
          padding: defaultPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 800 ? 800 : double.infinity,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class TouchTargetSize extends StatelessWidget {
  final Widget child;
  final double? minSize;

  const TouchTargetSize({
    super.key,
    required this.child,
    this.minSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize!,
        minHeight: minSize!,
      ),
      child: child,
    );
  }
}
