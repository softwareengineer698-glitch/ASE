import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donation_model.dart';
import '../donor/claim_donation_screen.dart';

class NearbyFoodMapScreen extends StatefulWidget {
  const NearbyFoodMapScreen({super.key});

  @override
  State<NearbyFoodMapScreen> createState() => _NearbyFoodMapScreenState();
}

class _NearbyFoodMapScreenState extends State<NearbyFoodMapScreen> {
  final MapController _mapController = MapController();

  Position? _userPosition;
  List<DonationModel> _allDonations = [];
  DonationModel? _selectedDonation;
  bool _loading = true;
  String? _locationError;

  LatLng _center = const LatLng(31.5497, 74.3436); // Lahore default

  // Only donations with GPS coords go on the map
  List<DonationModel> get _mappable =>
      _allDonations.where((d) => d.latitude != null && d.longitude != null).toList();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _locationError = null; });
    await _getLocation();
    await _loadDonations();
    setState(() => _loading = false);
  }

  Future<void> _getLocation() async {
    try {
      final svcOn = await Geolocator.isLocationServiceEnabled();
      if (!svcOn) {
        _locationError = 'Location services off. Enable to see distances.';
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied. Distances unavailable.';
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _userPosition = pos;
      _center = LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      _locationError = 'Could not get location.';
    }
  }

  Future<void> _loadDonations() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Load ALL available donations — no GPS filter
      final snap = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get();

      final donations = snap.docs
          .map((d) => DonationModel.fromMap(d.data(), d.id))
          .where((d) => d.donorId != uid)
          .where((d) => !d.isExpired)
          .toList();

      // Sort by distance (no-GPS ones go to end)
      if (_userPosition != null) {
        donations.sort((a, b) {
          final da = _distanceKm(a);
          final db = _distanceKm(b);
          if (da == double.infinity && db == double.infinity) return 0;
          if (da == double.infinity) return 1;
          if (db == double.infinity) return -1;
          return da.compareTo(db);
        });
      }

      setState(() => _allDonations = donations);

      // Center map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_userPosition != null) {
          _mapController.move(_center, 12.0);
        } else if (_mappable.isNotEmpty) {
          _mapController.move(
              LatLng(_mappable.first.latitude!, _mappable.first.longitude!), 11.0);
        }
      });
    } catch (e) {
      debugPrint('Map load error: $e');
    }
  }

  double _distanceKm(DonationModel d) {
    if (_userPosition == null || d.latitude == null || d.longitude == null) {
      return double.infinity;
    }
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          d.latitude!,
          d.longitude!,
        ) / 1000;
  }

  String _fmtDist(DonationModel d) {
    final km = _distanceKm(d);
    if (km == double.infinity) return '';
    if (km < 1) return '${(km * 1000).toInt()}m away';
    return '${km.toStringAsFixed(1)}km away';
  }

  // Open Google Maps directions from donation location → user location
  Future<void> _openRoute(DonationModel d) async {
    String url;
    if (d.latitude != null && d.longitude != null && _userPosition != null) {
      // GPS → GPS route
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${d.latitude},${d.longitude}'
          '&destination=${_userPosition!.latitude},${_userPosition!.longitude}'
          '&travelmode=driving';
    } else if (d.latitude != null && d.longitude != null) {
      // GPS coords available, no user location — just open location
      url = 'https://www.google.com/maps/search/?api=1'
          '&query=${d.latitude},${d.longitude}';
    } else {
      // Text address only — search for it
      final encoded = Uri.encodeComponent(d.location);
      url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'vegetables': return Colors.green;
      case 'fruits': return Colors.orange;
      case 'grains': return Colors.amber.shade700;
      case 'dairy': return Colors.blue;
      case 'meat': return Colors.red;
      case 'bakery': return Colors.brown;
      default: return Colors.teal;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Food',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _init,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Finding food near you...'),
                ],
              ),
            )
          : Column(
              children: [
                // ── Info banner ─────────────────────────────────────────────
                if (_locationError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: Colors.orange.shade50,
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_locationError!,
                              style: const TextStyle(fontSize: 12))),
                    ]),
                  ),

                // ── Stats bar ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: cs.primaryContainer.withValues(alpha: 0.25),
                  child: Row(children: [
                    Icon(Icons.fastfood, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${_allDonations.length} donation${_allDonations.length == 1 ? '' : 's'} available'
                      ' · ${_mappable.length} on map',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (_userPosition != null)
                      const Row(children: [
                        Icon(Icons.gps_fixed, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Location active',
                            style: TextStyle(fontSize: 11, color: Colors.green)),
                      ]),
                  ]),
                ),

                // ── Map (takes ~40% height) ──────────────────────────────────
                SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 12,
                          onTap: (_, __) => setState(() => _selectedDonation = null),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.foodbridge.app',
                          ),
                          // Markers
                          MarkerLayer(markers: [
                            // User pin
                            if (_userPosition != null)
                              Marker(
                                point: LatLng(_userPosition!.latitude,
                                    _userPosition!.longitude),
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
                                          blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            // Donation pins (all with GPS)
                            ..._mappable.map((d) {
                              final color = _catColor(d.category);
                              final sel = _selectedDonation?.id == d.id;
                              return Marker(
                                point: LatLng(d.latitude!, d.longitude!),
                                width: sel ? 60 : 50,
                                height: sel ? 60 : 50,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDonation = d),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: sel ? 3 : 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: sel ? 14 : 6,
                                          spreadRadius: sel ? 3 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(_catIcon(d.category),
                                        color: Colors.white,
                                        size: sel ? 28 : 22),
                                  ),
                                ),
                              );
                            }),
                          ]),
                        ],
                      ),

                      // Recenter
                      if (_userPosition != null)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'recenter',
                            backgroundColor: Colors.white,
                            elevation: 4,
                            onPressed: () => _mapController.move(
                                LatLng(_userPosition!.latitude,
                                    _userPosition!.longitude),
                                13.0),
                            child: Icon(Icons.my_location, color: cs.primary),
                          ),
                        ),

                      // No pins notice
                      if (_mappable.isEmpty && !_loading)
                        Positioned(
                          top: 0, left: 0, right: 0, bottom: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'No GPS-pinned donations.\nSee all donations in the list below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Selected donation popup (above list) ──────────────────
                if (_selectedDonation != null)
                  _buildSelectedCard(_selectedDonation!, cs),

                // ── ALL donations list ────────────────────────────────────
                Expanded(
                  child: _allDonations.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No available donations found.',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: _allDonations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _buildListTile(_allDonations[i], cs),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectedCard(DonationModel d, ColorScheme cs) {
    final color = _catColor(d.category);
    final dist = _fmtDist(d);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_catIcon(d.category), color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(d.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            if (dist.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dist,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 4),
            // Route button
            IconButton(
              icon: const Icon(Icons.directions, color: Colors.blue, size: 22),
              tooltip: 'Get directions',
              onPressed: () => _openRoute(d),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selectedDonation = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            '${d.remainingQuantity} ${d.unit} · ${d.category} · ${d.location}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedDonation = null);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClaimDonationScreen(donation: d)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Claim'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _openRoute(d),
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildListTile(DonationModel d, ColorScheme cs) {
    final color = _catColor(d.category);
    final dist = _fmtDist(d);
    final hasPin = d.latitude != null && d.longitude != null;

    return InkWell(
      onTap: () {
        if (hasPin) {
          setState(() => _selectedDonation = d);
          _mapController.move(LatLng(d.latitude!, d.longitude!), 15.0);
        } else {
          // No GPS — directly open claim
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ClaimDonationScreen(donation: d)));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_catIcon(d.category), color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Title + details
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(d.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(
                '${d.remainingQuantity} ${d.unit} · ${d.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Row(children: [
                Icon(Icons.location_on, size: 11, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    d.location,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ]),
          ),

          // Right side: distance + route button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (dist.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(dist,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 6),
              // Route / directions button
              GestureDetector(
                onTap: () => _openRoute(d),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions,
                      size: 18, color: Colors.green),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
