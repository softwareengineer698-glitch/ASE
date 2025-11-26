import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Custom error widget for consistent error display across the app
class ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? 'something_went_wrong'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom loading widget for consistent loading states
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 48,
            height: size ?? 48,
            child: const CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget for consistent empty state display
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Stream builder wrapper that handles loading, error, and empty states
class StreamBuilderWrapper<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool showEmptyOnNull;

  const StreamBuilderWrapper({
    super.key,
    required this.stream,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.showEmptyOnNull = false,
  });

  @override
  State<StreamBuilderWrapper<T>> createState() =>
      _StreamBuilderWrapperState<T>();
}

class _StreamBuilderWrapperState<T> extends State<StreamBuilderWrapper<T>> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: widget.stream,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? const LoadingWidget();
        }

        // Error state
        if (snapshot.hasError) {
          return widget.errorBuilder
                  ?.call(context, snapshot.error ?? 'Unknown error') ??
              ErrorWidget(
                error: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
        }

        // No data state
        if (!snapshot.hasData ||
            (widget.showEmptyOnNull && snapshot.data == null)) {
          return widget.emptyBuilder?.call(context) ??
              const EmptyStateWidget(
                title: 'No data available',
              );
        }

        // Data available
        return widget.builder(context, snapshot.data!);
      },
    );
  }
}

/// Future builder wrapper that handles loading, error, and empty states
class FutureBuilderWrapper<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool showEmptyOnNull;

  const FutureBuilderWrapper({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.showEmptyOnNull = false,
  });

  @override
  State<FutureBuilderWrapper<T>> createState() =>
      _FutureBuilderWrapperState<T>();
}

class _FutureBuilderWrapperState<T> extends State<FutureBuilderWrapper<T>> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: widget.future,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? const LoadingWidget();
        }

        // Error state
        if (snapshot.hasError) {
          return widget.errorBuilder
                  ?.call(context, snapshot.error ?? 'Unknown error') ??
              ErrorWidget(
                error: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
        }

        // No data state
        if (!snapshot.hasData ||
            (widget.showEmptyOnNull && snapshot.data == null)) {
          return widget.emptyBuilder?.call(context) ??
              const EmptyStateWidget(
                title: 'No data available',
              );
        }

        // Data available
        return widget.builder(context, snapshot.data!);
      },
    );
  }
}

/// Utility class for showing consistent dialogs and snackbars
class UIHelper {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showLoadingDialog(BuildContext context,
      {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
