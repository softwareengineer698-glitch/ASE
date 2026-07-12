import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../donor/claim_donation_screen.dart';

class NearbyFoodMapScreen extends StatefulWidget {
  const NearbyFoodMapScreen({super.key});

  @override
  State<NearbyFoodMapScreen> createState() => _NearbyFoodMapScreenState();
}

class _NearbyFoodMapScreenState extends State<NearbyFoodMapScreen> {
  final MapController _mapController = MapController();
  final DonationService _donationService = DonationService();

  Position? _userPosition;
  List<DonationModel> _donations = [];
  DonationModel? _selectedDonation;
  bool _loadingLocation = true;
  String? _locationError;
  double _radiusKm = 10.0;

  // Default center (fallback if location denied)
  LatLng _center = const LatLng(30.3753, 69.3451); // Pakistan center

  @override
  void initState() {
    super.initState();
    _initLocationAndDonations();
  }

  Future<void> _initLocationAndDonations() async {
    setState(() { _loadingLocation = true; _locationError = null; });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Showing all donations.';
          _loadingLocation = false;
        });
        _loadDonations();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied. Showing all donations.';
          _loadingLocation = false;
        });
        _loadDonations();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _userPosition = position;
        _center = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
      });

      // Move map to user location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_center, 13.0);
      });

    } catch (e) {
      setState(() {
        _locationError = 'Could not get location. Showing all donations.';
        _loadingLocation = false;
      });
    }

    _loadDonations();
  }

  Future<void> _loadDonations() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final snap = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get();

      final donations = snap.docs
          .map((d) => DonationModel.fromMap(d.data(), d.id))
          .where((d) => d.donorId != uid) // exclude own
          .where((d) => d.latitude != null && d.longitude != null)
          .toList();

      setState(() => _donations = donations);
    } catch (e) {
      debugPrint('Error loading donations for map: $e');
    }
  }

  double _distanceKm(DonationModel d) {
    if (_userPosition == null || d.latitude == null || d.longitude == null) {
      return 0;
    }
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          d.latitude!,
          d.longitude!,
        ) /
        1000;
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return Colors.green;
      case 'fruits': return Colors.orange;
      case 'grains': return Colors.amber;
      case 'dairy': return Colors.blue;
      case 'meat': return Colors.red;
      case 'bakery': return Colors.brown;
      default: return Colors.teal;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return Icons.eco;
      case 'fruits': return Icons.apple;
      case 'grains': return Icons.grass;
      case 'dairy': return Icons.water_drop;
      case 'meat': return Icons.set_meal;
      case 'bakery': return Icons.bakery_dining;
      default: return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Food',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Radius selector
          PopupMenuButton<double>(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Filter radius',
            onSelected: (v) => setState(() => _radiusKm = v),
            itemBuilder: (_) => [5, 10, 20, 50]
                .map((r) => PopupMenuItem(
                      value: r.toDouble(),
                      child: Row(children: [
                        if (_radiusKm == r)
                          const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Within ${r}km'),
                      ]),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _initLocationAndDonations,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onTap: (_, __) => setState(() => _selectedDonation = null),
            ),
            children: [
              // Tile layer — OpenStreetMap (no API key)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodbridge.app',
              ),

              // User location circle
              if (_userPosition != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    radius: _radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderColor: Colors.blue.withValues(alpha: 0.4),
                    borderStrokeWidth: 2,
                  ),
                ]),

              // Donation markers
              MarkerLayer(
                markers: [
                  // User's own location marker
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),

                  // Donation markers (filtered by radius if we have location)
                  ..._donations
                      .where((d) {
                        if (_userPosition == null) return true;
                        return _distanceKm(d) <= _radiusKm;
                      })
                      .map((d) {
                        final color = _categoryColor(d.category);
                        final isSelected = _selectedDonation?.id == d.id;
                        return Marker(
                          point: LatLng(d.latitude!, d.longitude!),
                          width: isSelected ? 60 : 48,
                          height: isSelected ? 60 : 48,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDonation = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: isSelected ? 12 : 6,
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _categoryIcon(d.category),
                                color: Colors.white,
                                size: isSelected ? 28 : 22,
                              ),
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ],
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_loadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Getting your location...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Location error banner ─────────────────────────────────────────
          if (_locationError != null && !_loadingLocation)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_locationError!,
                            style: const TextStyle(fontSize: 12))),
                  ]),
                ),
              ),
            ),

          // ── Donation count badge ──────────────────────────────────────────
          Positioned(
            bottom: _selectedDonation != null ? 240 : 20,
            left: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fastfood, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_donations.where((d) => _userPosition == null || _distanceKm(d) <= _radiusKm).length} donations within ${_radiusKm.toInt()}km',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
            ),
          ),

          // ── Recenter button ───────────────────────────────────────────────
          if (_userPosition != null)
            Positioned(
              bottom: _selectedDonation != null ? 240 : 20,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                onPressed: () =>
                    _mapController.move(
                      LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      14.0,
                    ),
                child: Icon(Icons.my_location, color: colorScheme.primary),
              ),
            ),

          // ── Selected donation card ────────────────────────────────────────
          if (_selectedDonation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDonationCard(_selectedDonation!, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DonationModel d, ColorScheme colorScheme) {
    final dist = _distanceKm(d);
    final color = _categoryColor(d.category);

    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(d.category), color: color, size: 28),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(d.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(d.category,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    if (_userPosition != null)
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.blue),
                        Text(
                          dist < 1
                              ? '${(dist * 1000).toInt()}m away'
                              : '${dist.toStringAsFixed(1)}km away',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.blue),
                        ),
                      ]),
                  ]),
                ]),
              ),

              // Close button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedDonation = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),

            const SizedBox(height: 12),

            // Details row
            Row(children: [
              _infoChip(Icons.scale,
                  '${d.remainingQuantity} ${d.unit}', Colors.green),
              const SizedBox(width: 8),
              _infoChip(Icons.access_time,
                  d.formattedExpiryDate, d.isExpiringSoon ? Colors.orange : Colors.grey),
              const SizedBox(width: 8),
              _infoChip(Icons.location_on, d.location, Colors.grey),
            ]),

            if (d.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(d.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 16),

            // Claim button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedDonation = null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClaimDonationScreen(donation: d),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_basket),
                label: Text(
                    'Claim ${d.remainingQuantity} ${d.unit} of ${d.title}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Flexible(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              style: TextStyle(fontSize: 11, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
