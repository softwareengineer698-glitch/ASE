import 'package:flutter/material.dart';

class PageBackground extends StatelessWidget {
  final Widget child;
  final bool hasGradient;
  final List<Color>? gradientColors;
  final Color? backgroundColor;

  const PageBackground({
    required this.child, super.key,
    this.hasGradient = false,
    this.gradientColors,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors ?? [
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: child,
      );
    }

    return Container(
      color: backgroundColor ?? colorScheme.surface,
      child: child,
    );
  }
}

class ResponsivePageLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasGradient;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final double maxWidth;

  const ResponsivePageLayout({
    required this.child, super.key,
    this.padding,
    this.hasGradient = false,
    this.gradientColors,
    this.backgroundColor,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return PageBackground(
      hasGradient: hasGradient,
      gradientColors: gradientColors,
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > maxWidth ? maxWidth : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: padding ?? EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CardSection extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;

  const CardSection({
    required this.child, super.key,
    this.title,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: elevation ?? 2,
        color: backgroundColor,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
