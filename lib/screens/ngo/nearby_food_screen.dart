import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../widgets/donation_image.dart';
import '../donor/claim_donation_screen.dart';
import '../../widgets/expiry_countdown_widget.dart';

class NearbyFoodScreen extends StatefulWidget {
  const NearbyFoodScreen({super.key});

  @override
  State<NearbyFoodScreen> createState() => _NearbyFoodScreenState();
}

class _NearbyFoodScreenState extends State<NearbyFoodScreen> {
  final _donationService = DonationService();
  double? _lat;
  double? _lng;
  bool _locating = true;
  String? _locationError;
  double _radiusKm = 20;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        setState(() => _locationError = 'Location services disabled');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() => _locationError = 'Location permission denied');
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      setState(() => _locationError = 'Failed to get location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('nearby_food'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
            onPressed: _showRadiusDialog,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Refresh location',
            onPressed: _fetchLocation,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_locating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching your location…'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_locationError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getNearbyDonations(
          lat: _lat!, lng: _lng!, radiusKm: _radiusKm),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('no_nearby_food'.tr(),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    'within_radius'.tr(
                      namedArgs: {'radius': _radiusKm.toStringAsFixed(0)},
                    ),
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _showRadiusDialog,
                  child: const Text('Increase search radius'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildLocationBanner(items.length),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _DonationCard(
                    donation: items[i], userLat: _lat!, userLng: _lng!),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$count item${count != 1 ? 's' : ''} within ${_radiusKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusDialog() {
    double temp = _radiusKm;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Radius'),
        content: StatefulBuilder(
          builder: (ctx, setD) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${temp.toStringAsFixed(0)} km'),
              Slider(
                value: temp,
                min: 1,
                max: 100,
                divisions: 19,
                label: '${temp.toStringAsFixed(0)} km',
                onChanged: (v) => setD(() => temp = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _radiusKm = temp);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// ── Donation card for nearby list ────────────────────────────────────────────
class _DonationCard extends StatelessWidget {
  final DonationModel donation;
  final double userLat;
  final double userLng;

  const _DonationCard({
    required this.donation,
    required this.userLat,
    required this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = _dist();
    final distLabel = distKm < 1
        ? '${(distKm * 1000).toStringAsFixed(0)} m'
        : '${distKm.toStringAsFixed(1)} km';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClaimDonationScreen(donation: donation),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DonationImage(
                imageUrls: donation.imageUrls,
                width: double.infinity,
                height: 130,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _statusChip(),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(donation.category,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.scale_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      '${donation.remainingQuantity} / ${donation.quantity} ${donation.unit}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(distLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(donation.location,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ExpiryCountdownWidget(
                expiryTime: donation.expiryTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    final isPartial = donation.status == DonationStatus.partiallyClaimed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            (isPartial ? Colors.orange : Colors.green).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPartial ? 'Partial' : 'Available',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPartial ? Colors.orange : Colors.green,
        ),
      ),
    );
  }

  double _dist() {
    if (donation.latitude == null || donation.longitude == null) return 0;
    // Rough calculation reused from service (no dep on service here)
    const r = 6371.0;
    final double dLat = _rad(donation.latitude! - userLat);
    final double dLon = _rad(donation.longitude! - userLng);
    final double a = _sinH(dLat) * _sinH(dLat) +
        _cos(userLat) * _cos(donation.latitude!) * _sinH(dLon) * _sinH(dLon);
    return r * 2 * _atan2Sqrt(a);
  }

  double _rad(double d) => d * 3.14159265 / 180;
  double _sinH(double r) => (r / 2 - _pow3(r / 2) / 6); // approx
  double _cos(double deg) {
    final r = _rad(deg);
    return 1 - r * r / 2;
  }

  double _pow3(double x) => x * x * x;

  double _atan2Sqrt(double a) {
    final sqrtA = a < 0
        ? 0.0
        : a > 1
            ? 1.0
            : _sqrtApprox(a);
    final sqrtB = _sqrtApprox(1 - a);
    return sqrtA == 0 && sqrtB == 0 ? 0 : sqrtA / sqrtB;
  }

  double _sqrtApprox(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 5; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }
}
