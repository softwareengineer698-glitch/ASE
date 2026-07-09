import 'package:flutter/material.dart';

/// Renders a donation image from a network URL.
/// Falls back to a placeholder icon when the URL is missing or fails to load.
/// Backward-compatible: donations created before Storage integration have
/// imageUrls = [] and will show the placeholder.
class DonationImage extends StatelessWidget {
  final List<String> imageUrls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const DonationImage({
    required this.imageUrls,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget child;
    if (imageUrls.isEmpty || imageUrls.first.isEmpty) {
      child = _placeholder(colorScheme);
    } else {
      child = Image.network(
        _optimizedCloudinaryUrl(imageUrls.first),
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, widget, progress) {
          if (progress == null) return widget;
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(colorScheme),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      width: width,
      height: height,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.volunteer_activism_rounded,
          size: (height ?? 80) * 0.4,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _optimizedCloudinaryUrl(String url) {
    // Cloudinary supports delivery transformations in the URL; f_auto,q_auto
    // lets the CDN choose an efficient format and quality for thumbnails.
    if (!url.contains('res.cloudinary.com') ||
        !url.contains('/image/upload/')) {
      return url;
    }
    if (url.contains('/image/upload/f_auto,q_auto/')) return url;
    return url.replaceFirst('/image/upload/', '/image/upload/f_auto,q_auto/');
  }
}
