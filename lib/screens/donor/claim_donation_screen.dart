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

    return Scaffold(
      appBar: AppBar(title: Text('claim_donation'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Donation summary ────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(d.description,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      const Divider(height: 24),
                      _row(Icons.category_outlined,
                          '${d.category} · ${d.itemType.displayName}'),
                      const SizedBox(height: 6),
                      _row(Icons.scale_outlined,
                          'Total: ${d.quantity} ${d.unit} · Remaining: ${d.remainingQuantity} ${d.unit}'),
                      const SizedBox(height: 6),
                      _row(Icons.location_on_outlined, d.location),
                      const SizedBox(height: 6),
                      ExpiryCountdownWidget(
                        expiryTime: d.expiryTime,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Quantity picker ─────────────────────────────────────────
              Text('how_much_do_you_need'.tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'quantity'.tr(),
                        suffixText: d.unit,
                        border: const OutlineInputBorder(),
                        helperText: 'Max: ${d.remainingQuantity} ${d.unit}',
                      ),
                      validator: (v) {
                        final q = double.tryParse(v ?? '');
                        if (q == null || q <= 0)
                          return 'Enter a valid quantity';
                        if (q > d.remainingQuantity) {
                          return 'Exceeds available (${d.remainingQuantity} ${d.unit})';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick-select fraction buttons
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
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.handshake_outlined),
                  label: Text('submit_claim'.tr(),
                      style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color}) => Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 13, color: color ?? Colors.grey[700])),
          ),
        ],
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final qty = double.parse(_qtyController.text.trim());

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
