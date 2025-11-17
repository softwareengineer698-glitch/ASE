import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for performance optimizations and monitoring
class PerformanceUtils {
  /// Optimized debug print that only works in debug mode
  static void debugLog(String message, [String? tag]) {
    if (kDebugMode) {
      final formattedMessage = tag != null ? '[$tag] $message' : message;
      debugPrint(formattedMessage);
    }
  }

  /// Measure execution time of a function
  static Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      return await operation();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      debugLog(
          '$operationName took ${stopwatch.elapsedMilliseconds}ms', 'PERF');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugLog(
          '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
          'PERF');
      rethrow;
    }
  }

  /// Create optimized const widgets for better performance
  static const Widget emptyWidget = SizedBox.shrink();

  static const Widget verticalSpacing4 = SizedBox(height: 4);
  static const Widget verticalSpacing8 = SizedBox(height: 8);
  static const Widget verticalSpacing12 = SizedBox(height: 12);
  static const Widget verticalSpacing16 = SizedBox(height: 16);
  static const Widget verticalSpacing24 = SizedBox(height: 24);
  static const Widget verticalSpacing32 = SizedBox(height: 32);

  static const Widget horizontalSpacing4 = SizedBox(width: 4);
  static const Widget horizontalSpacing8 = SizedBox(width: 8);
  static const Widget horizontalSpacing12 = SizedBox(width: 12);
  static const Widget horizontalSpacing16 = SizedBox(width: 16);
  static const Widget horizontalSpacing24 = SizedBox(width: 24);
  static const Widget horizontalSpacing32 = SizedBox(width: 32);

  /// Optimized border radius constants
  static const BorderRadius borderRadius4 =
      BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadius8 =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadius12 =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadius16 =
      BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadius20 =
      BorderRadius.all(Radius.circular(20));
  static const BorderRadius borderRadius24 =
      BorderRadius.all(Radius.circular(24));

  /// Optimized edge insets constants
  static const EdgeInsets paddingAll4 = EdgeInsets.all(4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(32);

  static const EdgeInsets paddingHorizontal8 =
      EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHorizontal12 =
      EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets paddingHorizontal16 =
      EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHorizontal20 =
      EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingHorizontal24 =
      EdgeInsets.symmetric(horizontal: 24);

  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVertical12 =
      EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingVertical16 =
      EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingVertical20 =
      EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets paddingVertical24 =
      EdgeInsets.symmetric(vertical: 24);

  /// Check if device is low-end for performance adjustments
  static bool get isLowEndDevice {
    // This is a simplified check - in production you might want more sophisticated detection
    return !kDebugMode; // Assume release builds might be on lower-end devices
  }

  /// Get optimized animation duration based on device performance
  static Duration getAnimationDuration({
    Duration normal = const Duration(milliseconds: 300),
    Duration reduced = const Duration(milliseconds: 150),
  }) {
    return isLowEndDevice ? reduced : normal;
  }

  /// Debounce function calls to improve performance
  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// Dispose all debounce timers
  static void disposeDebounceTimers() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}

/// Extension for optimized widget building
extension PerformanceWidgetExtensions on Widget {
  /// Wrap widget with RepaintBoundary for better performance
  Widget get repaintBoundary => RepaintBoundary(child: this);

  /// Add sliver padding with const optimization
  Widget sliverPadding(EdgeInsetsGeometry padding) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(child: this),
    );
  }
}
