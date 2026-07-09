import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dismissible, first-use-only bottom sheet that explains the tracking system.
///
/// • Shown automatically the first time a user reaches their dashboard.
/// • Tracked via SharedPreferences key [_seenKey] — never shown again once
///   the user taps "Got It".
/// • Can be reopened manually by calling [TrackingInfoSheet.show] from
///   any screen (e.g. a help icon).
///
/// No existing status pipelines, enums, or dashboard filtering is changed.
class TrackingInfoSheet extends StatelessWidget {
  const TrackingInfoSheet({super.key});

  static const String _seenKey = 'tracking_info_seen_v1';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Shows the sheet if the user has not seen it before.
  /// Pass [force] = true to always show (e.g. from a help icon).
  static Future<void> showIfNeeded(BuildContext context,
      {bool force = false}) async {
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seenKey) == true) return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TrackingInfoSheet(),
    );
  }

  /// Opens the sheet unconditionally — call from a "?" / info icon.
  static Future<void> show(BuildContext context) =>
      showIfNeeded(context, force: true);

  // ── Mark seen ──────────────────────────────────────────────────────────────

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'tracking_info_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'tracking_info_body'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // What is tracked
            _InfoTile(
              icon: Icons.inventory_2_outlined,
              color: colorScheme.primary,
              title: 'tracking_what'.tr(),
              body: 'tracking_what_body'.tr(),
            ),
            const SizedBox(height: 16),

            // Why it matters
            _InfoTile(
              icon: Icons.verified_outlined,
              color: Colors.green,
              title: 'tracking_why'.tr(),
              body: 'tracking_why_body'.tr(),
            ),
            const SizedBox(height: 16),

            // For donors
            _InfoTile(
              icon: Icons.favorite_border_rounded,
              color: const Color(0xFFE53935),
              title: 'tracking_how_donors'.tr(),
              body: 'tracking_how_donors_body'.tr(),
            ),
            const SizedBox(height: 16),

            // For recipients
            _InfoTile(
              icon: Icons.business_outlined,
              color: const Color(0xFF43A047),
              title: 'tracking_how_recipients'.tr(),
              body: 'tracking_how_recipients_body'.tr(),
            ),
            const SizedBox(height: 28),

            // Tracking pipeline visual
            _StatusPipeline(colorScheme: colorScheme),
            const SizedBox(height: 28),

            // Got It button — same style as role picker's Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _markSeen();
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'got_it'.tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows the five-step donation status pipeline as colored chips.
class _StatusPipeline extends StatelessWidget {
  final ColorScheme colorScheme;

  const _StatusPipeline({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Available', Colors.green),
      ('Claimed', Colors.blue),
      ('Pickup Ready', Colors.orange),
      ('Completed', Colors.purple),
      ('Expired', Colors.grey),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donation Status Pipeline',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: steps.map((s) {
            final (label, color) = s;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
