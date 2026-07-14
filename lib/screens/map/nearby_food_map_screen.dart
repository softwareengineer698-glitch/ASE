import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/donation_model.dart';
import '../donor/claim_donation_screen.dart';

// ── Pakistan food/donation centers ────────────────────────────────────────────
class _FoodCenter {
  final String name;
  final String city;
  final String type;
  final String phone;
  final double lat;
  final double lng;
  const _FoodCenter({
    required this.name,
    required this.city,
    required this.type,
    required this.phone,
    required this.lat,
    required this.lng,
  });
}

const List<_FoodCenter> _pakCenters = [
  // Edhi Foundation
  _FoodCenter(name: 'Edhi Foundation', city: 'Karachi', type: 'Food & Relief', phone: '021-32476378', lat: 24.8671, lng: 67.0102),
  _FoodCenter(name: 'Edhi Foundation', city: 'Lahore', type: 'Food & Relief', phone: '042-35761999', lat: 31.5204, lng: 74.3587),
  _FoodCenter(name: 'Edhi Foundation', city: 'Islamabad', type: 'Food & Relief', phone: '051-2611188', lat: 33.6844, lng: 73.0479),
  _FoodCenter(name: 'Edhi Foundation', city: 'Rawalpindi', type: 'Food & Relief', phone: '051-4411777', lat: 33.5651, lng: 73.0169),

  // Saylani Welfare
  _FoodCenter(name: 'Saylani Welfare', city: 'Karachi', type: 'Free Food', phone: '021-32779966', lat: 24.9056, lng: 67.0822),
  _FoodCenter(name: 'Saylani Welfare', city: 'Lahore', type: 'Free Food', phone: '042-35123456', lat: 31.5497, lng: 74.3436),
  _FoodCenter(name: 'Saylani Welfare', city: 'Islamabad', type: 'Free Food', phone: '051-2345678', lat: 33.7215, lng: 73.0433),

  // Chippa Welfare
  _FoodCenter(name: 'Chippa Welfare', city: 'Karachi', type: 'Food & Emergency', phone: '1030', lat: 24.8925, lng: 67.0281),
  _FoodCenter(name: 'Chippa Welfare', city: 'Lahore', type: 'Food & Emergency', phone: '1030', lat: 31.5085, lng: 74.3321),

  // Akhuwat
  _FoodCenter(name: 'Akhuwat Food Bank', city: 'Lahore', type: 'Food Bank', phone: '042-35761801', lat: 31.5754, lng: 74.3154),
  _FoodCenter(name: 'Akhuwat Food Bank', city: 'Islamabad', type: 'Food Bank', phone: '051-2890111', lat: 33.6938, lng: 73.0651),

  // Rizq
  _FoodCenter(name: 'Rizq Food Bank', city: 'Karachi', type: 'Food Bank', phone: '0311-1174979', lat: 24.8615, lng: 67.0099),
  _FoodCenter(name: 'Rizq Food Bank', city: 'Lahore', type: 'Food Bank', phone: '0311-1174979', lat: 31.4504, lng: 74.2787),

  // Khidmat Foundation
  _FoodCenter(name: 'Khidmat Foundation', city: 'Lahore', type: 'Free Food', phone: '042-36280001', lat: 31.5200, lng: 74.4000),
  _FoodCenter(name: 'Khidmat Foundation', city: 'Rawalpindi', type: 'Free Food', phone: '051-4601234', lat: 33.5971, lng: 73.0479),

  // JDC Foundation
  _FoodCenter(name: 'JDC Foundation', city: 'Karachi', type: 'Food Relief', phone: '021-34871000', lat: 24.9800, lng: 67.0350),

  // Al-Khidmat Foundation
  _FoodCenter(name: 'Al-Khidmat Foundation', city: 'Lahore', type: 'Food & Relief', phone: '042-35761000', lat: 31.4600, lng: 74.2600),
  _FoodCenter(name: 'Al-Khidmat Foundation', city: 'Karachi', type: 'Food & Relief', phone: '021-35761000', lat: 24.8200, lng: 67.0100),
  _FoodCenter(name: 'Al-Khidmat Foundation', city: 'Peshawar', type: 'Food & Relief', phone: '091-2611000', lat: 34.0150, lng: 71.5805),

  // Pakistan Sweet Home
  _FoodCenter(name: 'Pakistan Sweet Home', city: 'Islamabad', type: 'Food & Shelter', phone: '051-2890001', lat: 33.7100, lng: 73.0500),

  // Imran Khan Foundation / Shaukat Khanum
  _FoodCenter(name: 'Shaukat Khanum Memorial', city: 'Lahore', type: 'Healthcare & Food', phone: '042-35945100', lat: 31.4827, lng: 74.3148),
  _FoodCenter(name: 'Shaukat Khanum Memorial', city: 'Peshawar', type: 'Healthcare & Food', phone: '091-5840000', lat: 34.0100, lng: 71.5350),

  // Chhipa
  _FoodCenter(name: 'Chhipa Relief', city: 'Hyderabad', type: 'Food Relief', phone: '022-2611000', lat: 25.3792, lng: 68.3683),
  _FoodCenter(name: 'Chhipa Relief', city: 'Multan', type: 'Food Relief', phone: '061-4511000', lat: 30.1575, lng: 71.5249),
];

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
  _FoodCenter? _selectedCenter;
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
    if (!mounted) return;
    setState(() { _loading = true; _locationError = null; });
    await _getLocation();
    await _loadDonations();
    if (!mounted) return;
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

      if (!mounted) return;
      setState(() => _allDonations = donations);

      // Center map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
                          onTap: (_, __) => setState(() {
                            _selectedDonation = null;
                            _selectedCenter = null;
                          }),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.CareCircle.app',
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

                            // Pakistan food center pins (always shown)
                            ..._pakCenters.map((c) {
                              final sel = _selectedCenter?.name == c.name &&
                                  _selectedCenter?.lat == c.lat;
                              return Marker(
                                point: LatLng(c.lat, c.lng),
                                width: sel ? 58 : 46,
                                height: sel ? 58 : 46,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCenter = c;
                                      _selectedDonation = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: sel ? 3 : 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepOrange
                                              .withValues(alpha: 0.5),
                                          blurRadius: sel ? 14 : 6,
                                          spreadRadius: sel ? 3 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.volunteer_activism,
                                      color: Colors.white,
                                      size: sel ? 28 : 22,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Donation pins (all with GPS)
                            ..._mappable.map((d) {
                              final color = _catColor(d.category);
                              final sel = _selectedDonation?.id == d.id;
                              return Marker(
                                point: LatLng(d.latitude!, d.longitude!),
                                width: sel ? 60 : 50,
                                height: sel ? 60 : 50,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedDonation = d;
                                    _selectedCenter = null;
                                  }),
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

                // ── Selected food center popup ─────────────────────────────
                if (_selectedCenter != null)
                  _buildCenterCard(_selectedCenter!, cs),

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

  Widget _buildCenterCard(_FoodCenter c, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Colors.deepOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('${c.city} · ${c.type}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selectedCenter = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.phone, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(c.phone,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ]),
          const SizedBox(height: 10),
          Column(children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openCenterRoute(c),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  foregroundColor: Colors.deepOrange,
                  side: const BorderSide(color: Colors.deepOrange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _callCenter(c.phone),
                icon: const Icon(Icons.call, size: 16),
                label: const Text('Call Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _openCenterRoute(_FoodCenter c) async {
    String url;
    if (_userPosition != null) {
      // Route from user location to center
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${_userPosition!.latitude},${_userPosition!.longitude}'
          '&destination=${c.lat},${c.lng}'
          '&travelmode=driving';
    } else {
      // Just open the center location
      url = 'https://www.google.com/maps/search/?api=1'
          '&query=${c.lat},${c.lng}';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCenter(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
