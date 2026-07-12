import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/donation_image.dart';
import '../../widgets/expiry_countdown_widget.dart';
import '../auth/sign_in_screen.dart';
import '../donor/claim_donation_screen.dart';
import '../donor/create_donation_screen.dart';
import '../request/create_request_screen.dart';
import '../request/request_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_rooms_screen.dart';
import '../chat/chat_screen.dart';
import '../history/history_screen.dart';
import '../map/nearby_food_map_screen.dart';

class UnifiedDashboard extends StatefulWidget {
  const UnifiedDashboard({super.key});
  @override
  State<UnifiedDashboard> createState() => _UnifiedDashboardState();
}

class _UnifiedDashboardState extends State<UnifiedDashboard> {
  final DonationService _donationService = DonationService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Nearest';
  String? _profileImageUrl;
  Position? _currentPosition;

  final List<String> _categories = [
    'All','Vegetables','Fruits','Grains','Dairy','Meat','Bakery','Other'
  ];
  final List<String> _sortOptions = [
    'Nearest','Newest','Oldest','Expiry Soon','Quantity High','Quantity Low'
  ];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _browseKey = GlobalKey();
  final GlobalKey _claimsKey = GlobalKey();
  final GlobalKey _myDonationsKey = GlobalKey();
  final GlobalKey _nearbyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      // Location services unavailable — continue without location
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      // Only update state if still mounted and user still matches
      final currentUid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (doc.exists && mounted && currentUid == uid) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
        });
      }
    } catch (_) {
      // Permission denied on logout — suppress silently
    }
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) return const SignInScreen();
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user, colorScheme),
                    const SizedBox(height: 20),
                    _buildAvailableCount(colorScheme),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildNearbyFood(user, colorScheme),
                    const SizedBox(height: 24),
                    _buildAvailableDonations(user, colorScheme),
                    const SizedBox(height: 24),
                    _buildMyDonations(user, colorScheme),
                    const SizedBox(height: 24),
                    _buildMyClaims(user, colorScheme),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(UserModel user, ColorScheme colorScheme) {
    return DashboardCard(
      child: Row(children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ? NetworkImage(_profileImageUrl!) as ImageProvider
              : null,
          child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
              ? Text(
                  _getInitials(user),
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  'hello_user'.tr(namedArgs: {
                    'name': user.userName ?? user.email.split('@')[0]
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.restaurant, size: 22, color: colorScheme.primary)
                  .animate().scale(duration: 700.ms).then()
                  .scale(begin: const Offset(1.1,1.1), end: const Offset(1,1)),
            ]),
            const SizedBox(height: 4),
            Text(
              'Donate & receive food donations',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
      ]),
    );
  }

  String _getInitials(UserModel user) {
    final name = user.userName ?? user.email.split('@')[0];
    final words = name.trim().split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  // ── Available Count ────────────────────────────────────────────────────────
  Widget _buildAvailableCount(ColorScheme colorScheme) {
    return StreamBuilder<int>(
      stream: _donationService.getAvailableDonationsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return DashboardCard(
          child: Row(children: [
            Icon(Icons.fastfood, color: colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('available_donations'.tr(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('$count items ready for pickup',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: colorScheme.primary)),
            ]),
          ]),
        );
      },
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    final buttons = [
      _ActionBtn('create donation'.tr(), Icons.add_circle,
          colorScheme.primary, Colors.white,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDonationScreen()))),
      _ActionBtn('browse donations'.tr(), Icons.search,
          colorScheme.primaryContainer, colorScheme.onPrimaryContainer,
          () => _scrollToSection(_browseKey)),
      _ActionBtn('food_requests'.tr(), Icons.request_page_outlined,
          Colors.blue.withValues(alpha: 0.12), Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestListScreen()))),
      _ActionBtn('my_chats'.tr(), Icons.chat_outlined,
          Colors.teal.withValues(alpha: 0.12), Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatRoomsScreen()))),
      _ActionBtn('request_food'.tr(), Icons.add_shopping_cart,
          Colors.orange.withValues(alpha: 0.12), Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen()))),
      _ActionBtn('notifications'.tr(), Icons.notifications_outlined,
          Colors.purple.withValues(alpha: 0.12), Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      _ActionBtn('Nearby Food', Icons.location_on,
          Colors.red.withValues(alpha: 0.12), Colors.red,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyFoodMapScreen()))),
      _ActionBtn('view history'.tr(), Icons.history,
          Colors.grey.withValues(alpha: 0.12), Colors.grey.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
      _ActionBtn('my claims'.tr(), Icons.list_alt,
          Colors.green.withValues(alpha: 0.12), Colors.green,
          () => _scrollToSection(_claimsKey)),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth >= 600 ? 4 : 2;
        final spacing = 10.0;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing, runSpacing: spacing,
          children: buttons.map((b) => SizedBox(width: w, child: _buildActionCard(b))).toList(),
        );
      }),
    ]);
  }

  Widget _buildActionCard(_ActionBtn b) {
    return InkWell(
      onTap: b.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: b.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: b.fg.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(b.icon, color: b.fg, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(b.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: b.fg),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  // ── Nearby Food ───────────────────────────────────────────────────────────
  Widget _buildNearbyFood(UserModel user, ColorScheme colorScheme) {
    return Container(
      key: _nearbyKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getAvailableDonations(),
        builder: (context, snapshot) {
          final allDonations = snapshot.data ?? [];

          // Filter to only donations that have coordinates
          final nearby = allDonations.where((d) =>
            d.donorId != user.uid &&
            d.latitude != null &&
            d.longitude != null
          ).toList();

          // Sort by distance if we have location
          if (_currentPosition != null) {
            nearby.sort((a, b) =>
              _calculateDistance(a).compareTo(_calculateDistance(b)));
          }

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              const Text('Nearby Food',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_currentPosition == null)
                TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Enable Location', style: TextStyle(fontSize: 12)),
                ),
              if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Location On',
                          style: TextStyle(fontSize: 11, color: Colors.green)),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 12),

            // Location not enabled
            if (_currentPosition == null)
              DashboardCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Icon(Icons.location_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Enable location to see food donations near you',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use My Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ]),
                ),
              )

            // No nearby donations with coordinates
            else if (nearby.isEmpty)
              DashboardCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Icon(Icons.location_searching, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No food donations found near your location',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ),
              )

            // Show nearby donations as horizontal scroll
            else ...[
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearby.take(10).length,
                  itemBuilder: (context, i) {
                    final d = nearby[i];
                    final dist = _formatDistance(d);
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(
                        right: 12,
                        left: i == 0 ? 0 : 0,
                      ),
                      child: DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DonationImage(
                                imageUrls: d.imageUrls,
                                width: double.infinity,
                                height: 90,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Distance badge
                            if (dist.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 10, color: Colors.blue),
                                    const SizedBox(width: 3),
                                    Text(dist,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.blue)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 4),
                            // Title
                            Text(d.title,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            // Quantity
                            Text(
                              '${d.remainingQuantity} ${d.unit} available',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                              maxLines: 1,
                            ),
                            const Spacer(),
                            // Claim button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _claimDonation(d, user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text('Claim'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text('${nearby.length} donation${nearby.length == 1 ? '' : 's'} near you',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ]);
        },
      ),
    );
  }

  // ── Available Donations (Browse) ──────────────────────────────────────────
  Widget _buildAvailableDonations(UserModel user, ColorScheme colorScheme) {
    return Container(
      key: _browseKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getAvailableDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final donations = _filterAndSort(snapshot.data ?? []);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('available_donations'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${donations.length} items',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 12),
            _buildSearchFilter(colorScheme),
            const SizedBox(height: 12),
            if (donations.isEmpty)
              DashboardCard(
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('no_donations_found'.tr(),
                      style: TextStyle(color: Colors.grey[600])),
                )),
              )
            else
              ...donations.map((d) => _buildAvailableCard(d, user, colorScheme)),
          ]);
        },
      ),
    );
  }

  Widget _buildSearchFilter(ColorScheme colorScheme) {
    return DashboardCard(
      child: Column(children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'search_donations'.tr(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear),
                    onPressed: () { _searchController.clear(); setState(() {}); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'category'.tr(),
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _selectedSortBy,
            decoration: InputDecoration(
              labelText: 'sort_by'.tr(),
              prefixIcon: const Icon(Icons.sort),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _sortOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _selectedSortBy = v!),
          )),
        ]),
      ]),
    );
  }

  List<DonationModel> _filterAndSort(List<DonationModel> list) {
    var filtered = List<DonationModel>.from(list);
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      filtered = filtered.where((d) =>
        d.title.toLowerCase().contains(q) ||
        d.description.toLowerCase().contains(q) ||
        d.category.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered.where((d) => d.category == _selectedCategory).toList();
    }
    switch (_selectedSortBy) {
      case 'Nearest':
        if (_currentPosition != null) {
          filtered.sort((a, b) {
            final distA = _calculateDistance(a);
            final distB = _calculateDistance(b);
            return distA.compareTo(distB);
          });
        } else {
          // Fallback to newest if location unavailable
          filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        break;
      case 'Oldest': filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp)); break;
      case 'Expiry Soon': filtered.sort((a, b) => a.expiryTime.compareTo(b.expiryTime)); break;
      case 'Quantity High': filtered.sort((a, b) => b.quantity.compareTo(a.quantity)); break;
      case 'Quantity Low': filtered.sort((a, b) => a.quantity.compareTo(b.quantity)); break;
      default: filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return filtered;
  }

  double _calculateDistance(DonationModel donation) {
    if (_currentPosition == null) return double.infinity;
    if (donation.latitude == null || donation.longitude == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      donation.latitude!,
      donation.longitude!,
    ) / 1000; // Convert to kilometers
  }

  String _formatDistance(DonationModel donation) {
    final distance = _calculateDistance(donation);
    if (distance == double.infinity) return '';
    if (distance < 1) return '${(distance * 1000).toStringAsFixed(0)}m away';
    return '${distance.toStringAsFixed(1)}km away';
  }

  Widget _buildAvailableCard(DonationModel d, UserModel user, ColorScheme colorScheme) {
    final isOwn = d.donorId == user.uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(isOwn ? 'Your Donation' : 'available'.tr(),
                  style: TextStyle(color: isOwn ? Colors.blue : Colors.green,
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 6),
            if (_formatDistance(d).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(d),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (d.isExpiringSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('Expiring Soon',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            const SizedBox(width: 8),
            ExpiryCountdownWidget(expiryTime: d.expiryTime),
          ]),
          const SizedBox(height: 10),
          DonationImage(imageUrls: d.imageUrls, width: double.infinity, height: 140,
              borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Text(d.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(d.description, style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Wrap(spacing: 16, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.category, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(d.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.scale, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${d.quantity} ${d.unit}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(d.location, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ]),
          const SizedBox(height: 12),
          if (isOwn)
            SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.block, size: 16, color: Colors.grey),
                label: const Text('Your own donation', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _claimDonation(d, user),
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
                child: Text('Claim & Choose Quantity'),
              ),
            ),
        ]),
      ),
    );
  }

  void _claimDonation(DonationModel donation, UserModel user) {
    // ── Self-claim guard ──────────────────────────────────────────────────────
    if (donation.donorId == user.uid) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Text('Cannot Claim'),
          ]),
          content: const Text(
              'You cannot claim your own donation. This donation was posted by you.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // Navigate to ClaimDonationScreen which supports partial quantity selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClaimDonationScreen(donation: donation),
      ),
    );
  }

  // ── My Donations ───────────────────────────────────────────────────────────
  Widget _buildMyDonations(UserModel user, ColorScheme colorScheme) {
    return Container(
      key: _myDonationsKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getDonorDonations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final active = all.where((d) =>
              d.status == DonationStatus.available ||
              d.status == DonationStatus.claimed ||
              d.status == DonationStatus.partiallyClaimed).toList();

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('My Donations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${active.length} active',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 12),
            if (active.isEmpty)
              DashboardCard(child: Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('no active donations'.tr(),
                      style: TextStyle(color: Colors.grey[600])),
                ]),
              )))
            else
              ...active.map((d) => _buildMyDonationCard(d, colorScheme)),
          ]);
        },
      ),
    );
  }

  Widget _buildMyDonationCard(DonationModel d, ColorScheme colorScheme) {
    final statusColor = _statusColor(d.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(d.statusDisplayName,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Text(d.formattedTimestamp,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 10),
          DonationImage(imageUrls: d.imageUrls, width: double.infinity, height: 120,
              borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Text(d.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ExpiryCountdownWidget(expiryTime: d.expiryTime),
          const SizedBox(height: 10),
          Row(children: [
            if (d.status == DonationStatus.claimed)
              ElevatedButton.icon(
                onPressed: () => _completeDonation(d),
                icon: const Icon(Icons.check, size: 16),
                label: Text('complete'.tr()),
              ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _deleteDonation(d),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text(''),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(40, 36),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ]),
          if (d.status == DonationStatus.claimed && d.claimedBy != null) ...[
            const SizedBox(height: 8),
            _ChatButton(
              label: 'Chat with Recipient',
              donationId: d.id,
              otherUserId: d.claimedBy!,
              color: Colors.teal,
            ),
          ],
        ]),
      ),
    );
  }

  void _completeDonation(DonationModel d) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('complete donation'.tr()),
      content: Text('confirm complete donation'.tr()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _donationService.completeDonation(d.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('donation completed'.tr()), backgroundColor: Colors.green));
            }
          },
          child: Text('confirm'.tr()),
        ),
      ],
    ));
  }

  void _deleteDonation(DonationModel d) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('delete donation'.tr()),
      content: Text('confirm delete donation'.tr()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _donationService.deleteDonation(d.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('donation deleted'.tr()), backgroundColor: Colors.green));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: Text('delete'.tr()),
        ),
      ],
    ));
  }

  // ── My Claims ─────────────────────────────────────────────────────────────
  Widget _buildMyClaims(UserModel user, ColorScheme colorScheme) {
    return Container(
      key: _claimsKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getNGOClaimedDonations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final claims = snapshot.data ?? [];

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('My Claims',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${claims.length} items',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 12),
            if (claims.isEmpty)
              DashboardCard(child: Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('no claims yet'.tr(), style: TextStyle(color: Colors.grey[600])),
                ]),
              )))
            else
              ...claims.map((d) => _buildClaimCard(d, user, colorScheme)),
          ]);
        },
      ),
    );
  }

  Widget _buildClaimCard(DonationModel d, UserModel user, ColorScheme colorScheme) {
    final statusColor = _statusColor(d.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(d.statusDisplayName,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            if (d.claimedAt != null)
              Text('${d.claimedAt!.day}/${d.claimedAt!.month}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 10),
          DonationImage(imageUrls: d.imageUrls, width: double.infinity, height: 120,
              borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Text(d.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${d.quantity} ${d.unit} · ${d.category}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 10),
          if (d.status == DonationStatus.claimed ||
              d.status == DonationStatus.partiallyClaimed)
            OutlinedButton.icon(
              onPressed: () => _releaseDonation(d),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('release'.tr()),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange),
            ),
          const SizedBox(height: 8),
          _ChatButton(
            label: 'Chat with Donor',
            donationId: d.id,
            otherUserId: d.donorId,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _requestVolunteer(d, user),
              icon: const Icon(Icons.hail, size: 16),
              label: const Text('Request Volunteer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary, foregroundColor: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  void _releaseDonation(DonationModel d) {
    // Calculate how much was claimed (total - remaining)
    final claimedQty = d.quantity - d.remainingQuantity;
    final qtyController = TextEditingController(
        text: claimedQty > 0 ? claimedQty.toStringAsFixed(1) : d.quantity.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Icon(Icons.refresh_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Text('release donation'.tr()),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donation summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${d.quantity} ${d.unit}   ·   Remaining: ${d.remainingQuantity} ${d.unit}   ·   Claimed: ${claimedQty.toStringAsFixed(1)} ${d.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How much do you want to release?',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  suffixText: d.unit,
                  border: const OutlineInputBorder(),
                  helperText: 'Max releasable: ${claimedQty > 0 ? claimedQty.toStringAsFixed(1) : d.quantity.toStringAsFixed(1)} ${d.unit}',
                ),
              ),
              const SizedBox(height: 8),
              // Quick-select buttons
              Wrap(
                spacing: 8,
                children: [0.25, 0.5, 0.75, 1.0].map((frac) {
                  final max = claimedQty > 0 ? claimedQty : d.quantity;
                  final qty = max * frac;
                  return ActionChip(
                    label: Text('${(frac * 100).toInt()}%'),
                    onPressed: () => setDialogState(() =>
                        qtyController.text = qty.toStringAsFixed(1)),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final qty = double.tryParse(qtyController.text.trim());
                final maxRelease = claimedQty > 0 ? claimedQty : d.quantity;
                if (qty == null || qty <= 0 || qty > maxRelease) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Enter a valid quantity (max $maxRelease ${d.unit})'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _donationService.releaseDonation(d.id, releaseQuantity: qty);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Released ${qty.toStringAsFixed(1)} ${d.unit} back to available pool'),
                      backgroundColor: Colors.orange,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('release'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _requestVolunteer(DonationModel d, UserModel user) {
    final name = user.organizationName?.isNotEmpty == true
        ? user.organizationName! : user.userName ?? user.email;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Request Volunteer Transport?'),
      content: const Text(
          'A notification will be sent to nearby volunteers to help transport this donation.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await FirebaseFirestore.instance.collection('deliveries').add({
                'donationId': d.id, 'volunteerId': '',
                'donorId': d.donorId, 'ngoId': user.uid, 'ngoName': name,
                'donationTitle': d.title, 'status': 'pending',
                'scheduledAt': FieldValue.serverTimestamp(),
              });
              await NotificationService().createRemoteNotificationForUser(
                userId: d.donorId,
                notification: AppNotification(
                  id: 'vol_${d.id}_${user.uid}',
                  title: 'Volunteer Requested',
                  message: '$name requested a volunteer for ${d.title}.',
                  type: NotificationType.general,
                  priority: NotificationPriority.high,
                  timestamp: DateTime.now(),
                  relatedDonationId: d.id,
                ),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Volunteer request sent!'), backgroundColor: Colors.green));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    ));
  }

  Color _statusColor(DonationStatus s) {
    switch (s) {
      case DonationStatus.available: return Colors.green;
      case DonationStatus.partiallyClaimed: return Colors.orange;
      case DonationStatus.claimed: return Colors.blue;
      case DonationStatus.completed: return Colors.purple;
      case DonationStatus.expired: return Colors.red;
    }
  }
}

// ── Helper models ─────────────────────────────────────────────────────────────
class _ActionBtn {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.bg, this.fg, this.onTap);
}

// ── Reusable Chat Button ───────────────────────────────────────────────────────
class _ChatButton extends StatefulWidget {
  final String label;
  final String donationId;
  final String otherUserId;
  final Color color;
  const _ChatButton({required this.label, required this.donationId,
      required this.otherUserId, required this.color});

  @override
  State<_ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<_ChatButton> {
  bool _loading = false;

  Future<void> _open() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null || uid == widget.otherUserId) return;
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      String? roomId;
      final existing = await db.collection('chat_rooms')
          .where('donationId', isEqualTo: widget.donationId)
          .where('participantIds', arrayContains: uid)
          .get();
      for (final doc in existing.docs) {
        final p = List<String>.from(doc.data()['participantIds'] ?? []);
        if (p.contains(widget.otherUserId)) { roomId = doc.id; break; }
      }
      if (roomId == null) {
        final ref = db.collection('chat_rooms').doc();
        await ref.set({
          'participantIds': [uid, widget.otherUserId],
          'donationId': widget.donationId,
          'lastMessage': null,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'type': 'donor_recipient',
          'unreadCounts': {uid: 0, widget.otherUserId: 0},
        });
        roomId = ref.id;
      }
      if (!mounted) return;
      String otherName = 'User';
      try {
        final snap = await db.collection('users').doc(widget.otherUserId).get();
        if (snap.exists) {
          final d = snap.data()!;
          otherName = (d['userName'] ?? d['organizationName'] ?? d['email'])?.toString() ?? 'User';
        }
      } catch (_) {}
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(chatRoomId: roomId!, otherUserName: otherName)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _open,
        icon: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.chat_outlined),
        label: Text(widget.label),
        style: ElevatedButton.styleFrom(
            backgroundColor: widget.color, foregroundColor: Colors.white),
      ),
    );
  }
}
