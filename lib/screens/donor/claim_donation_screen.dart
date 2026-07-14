import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../widgets/expiry_countdown_widget.dart';

class ClaimDonationScreen extends StatefulWidget {
  final DonationModel donation;

  const ClaimDonationScreen({required this.donation, super.key});

  @override
  State<ClaimDonationScreen> createState() => _ClaimDonationScreenState();
}

class _ClaimDonationScreenState extends State<ClaimDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _svc = DonationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qtyController.text = widget.donation.remainingQuantity.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('claim_donation'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Donation summary ──────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(d.description,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Divider(height: 16),
                      _row(Icons.category_outlined,
                          '${d.category} · ${d.itemType.displayName}'),
                      const SizedBox(height: 4),
                      _row(Icons.scale_outlined,
                          'Total: ${d.quantity} ${d.unit}  ·  Remaining: ${d.remainingQuantity} ${d.unit}'),
                      const SizedBox(height: 4),
                      _row(Icons.location_on_outlined, d.location),
                      const SizedBox(height: 4),
                      ExpiryCountdownWidget(
                        expiryTime: d.expiryTime,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Quantity label ────────────────────────────────────────
              const Text('How much do you need?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // ── Quantity input ────────────────────────────────────────
              TextFormField(
                controller: _qtyController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  suffixText: d.unit,
                  border: const OutlineInputBorder(),
                  helperText: 'Max: ${d.remainingQuantity} ${d.unit}',
                  isDense: true,
                ),
                validator: (v) {
                  final q = double.tryParse(v ?? '');
                  if (q == null || q <= 0) return 'Enter a valid quantity';
                  if (q > d.remainingQuantity) {
                    return 'Exceeds available (${d.remainingQuantity} ${d.unit})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // ── Quick-select chips ────────────────────────────────────
              Wrap(
                spacing: 8,
                children: [0.25, 0.5, 0.75, 1.0].map((frac) {
                  final qty = d.remainingQuantity * frac;
                  return ActionChip(
                    label: Text('${(frac * 100).toInt()}%'),
                    onPressed: () => setState(
                        () => _qtyController.text = qty.toStringAsFixed(2)),
                  );
                }).toList(),
              ),

              const Spacer(),

              // ── Submit button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Claim',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color, double fontSize = 13}) =>
      Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: fontSize, color: color ?? Colors.grey[700])),
          ),
        ],
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    // ── Check if user is trying to claim their own donation ────────────────
    if (widget.donation.donorId == user.uid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Cannot Claim'),
            ],
          ),
          content: const Text(
            'You cannot claim your own donation.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      return;
    }

    final qtyText = _qtyController.text.trim();
    final qty = double.tryParse(qtyText);

    // ── Validate quantity ──────────────────────────────────────────────────
    if (qty == null || qty <= 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Quantity'),
          content: const Text('Please enter a valid quantity greater than 0.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    if (qty > widget.donation.remainingQuantity) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Exceeds Available'),
          ]),
          content: Text(
            'You requested ${_fmtQty(qty)} ${widget.donation.unit} but only '
            '${_fmtQty(widget.donation.remainingQuantity)} ${widget.donation.unit} is available.\n\n'
            'Please enter a quantity of ${_fmtQty(widget.donation.remainingQuantity)} or less.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _qtyController.text = _fmtQty(widget.donation.remainingQuantity);
              },
              child: const Text('Use Max'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final claimId = await _svc.submitClaim(
        donationId: widget.donation.id,
        claimantId: user.uid,
        requestedQuantity: qty,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('claim_submitted'.tr()),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, claimId);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Claim Failed'),
            content: Text('$e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtQty(double v) {
    if (v.abs() < 0.001) return '0';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return double.parse(v.toStringAsFixed(2)).toString();
  }
}
