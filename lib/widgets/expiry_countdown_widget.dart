import 'dart:async';
import 'package:flutter/material.dart';

/// A self-ticking countdown widget that shows time remaining until [expiryTime].
/// Rebuilds every second so the counter is always accurate.
/// Shows nothing once the donation has been expired for more than 24 h.
class ExpiryCountdownWidget extends StatefulWidget {
  final DateTime expiryTime;

  /// Optional text style. Defaults to a small, coloured style based on urgency.
  final TextStyle? style;

  const ExpiryCountdownWidget({
    required this.expiryTime, super.key,
    this.style,
  });

  @override
  State<ExpiryCountdownWidget> createState() => _ExpiryCountdownWidgetState();
}

class _ExpiryCountdownWidgetState extends State<ExpiryCountdownWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calc());
    });
  }

  Duration _calc() => widget.expiryTime.difference(DateTime.now());

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.isNegative;
    final label = _buildLabel(isExpired);
    final color = _buildColor(isExpired);
    final icon = isExpired ? Icons.timer_off_outlined : Icons.timer_outlined;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: widget.style != null
              ? widget.style!.copyWith(color: widget.style!.color ?? color)
              : TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
        ),
      ],
    );
  }

  String _buildLabel(bool isExpired) {
    if (isExpired) {
      final ago = _remaining.abs();
      if (ago.inDays >= 1) return 'Expired ${ago.inDays}d ago';
      if (ago.inHours >= 1) {
        return 'Expired ${ago.inHours}h ${ago.inMinutes % 60}m ago';
      }
      if (ago.inMinutes >= 1) return 'Expired ${ago.inMinutes}m ago';
      return 'Just expired';
    }

    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    if (d >= 7) {
      return 'Expires ${widget.expiryTime.day}/${widget.expiryTime.month}/${widget.expiryTime.year}';
    }
    if (d >= 1) return 'Expires in ${d}d ${h}h';
    if (h >= 1) return '${h}h ${m}m left';
    if (m >= 1) return '${m}m ${s.toString().padLeft(2, '0')}s left';
    return '${s}s left';
  }

  Color _buildColor(bool isExpired) {
    if (isExpired) return Colors.red;
    final hours = _remaining.inHours;
    if (hours < 1) return Colors.red; // < 1 hour  → red/urgent
    if (hours < 6) return Colors.orange; // < 6 hours → orange/warn
    if (hours < 24) return Colors.amber.shade700; // < 1 day → amber
    return Colors.green; // plenty of time
  }
}
