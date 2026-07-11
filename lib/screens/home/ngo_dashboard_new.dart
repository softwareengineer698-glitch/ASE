import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/donation_image.dart';
import '../../widgets/expiry_countdown_widget.dart';
import '../auth/sign_in_screen.dart';
import '../impact/ngo_impact_screen.dart';
import '../request/create_request_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_rooms_screen.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard> {
  final DonationService _donationService = DonationService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Newest';

  // Random food icon list
  final List<IconData> _foodIcons = [
    Icons.fastfood,
    Icons.local_pizza,
    Icons.restaurant,
    Icons.emoji_food_beverage,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.cake,
    Icons.icecream,
  ];

  IconData _selectedFoodIcon = Icons.fastfood; // Default fallback

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Bakery',
    'Other'
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Expiry Soon',
    'Quantity High',
    'Quantity Low'
  ];

  @override
  void initState() {
    super.initState();
    // Select a random food icon for animation
    _selectedFoodIcon =
        _foodIcons[(DateTime.now().millisecondsSinceEpoch) % _foodIcons.length];
  }

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _browseKey = GlobalKey();
  final GlobalKey _claimsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ThemeProvider, LanguageProvider>(
      builder: (context, authProvider, themeProvider, languageProvider, child) {
        final user = authProvider.user;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (user == null) {
          return const SignInScreen();
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section
                        _buildHeaderSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 2. Available Donations Count
                        _buildAvailableCountSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 3. Main Actions
                        _buildMainActionsSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 4. Available Donations List
                        _buildAvailableDonationsSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.02),

                        // 6. My Claims Section
                        _buildMyClaimsSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.02),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 1. Header Section
  Widget _buildHeaderSection(UserModel user, ColorScheme colorScheme) {
    return DashboardCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.business,
              size: 30,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'hello_user'.tr(namedArgs: {
                        'name': user.userName ?? user.email.split('@')[0]
                      }),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _selectedFoodIcon,
                      size: 24,
                      color: colorScheme.primary,
                    )
                        .animate()
                        .scale(duration: 700.ms)
                        .then()
                        .scale(
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1, 1))
                        .then(delay: 1000.ms)
                        .scale(duration: 700.ms)
                        .then(delay: 1000.ms)
                        .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1)),
                  ],
                ),
                if (user.organizationName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.organizationName!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'ready_to_receive'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Quick Overview Section (Simplified for better HCI)
  Widget _buildQuickOverviewSection(UserModel user, ColorScheme colorScheme) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _donationService.getNGOStatistics(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return DashboardCard(
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading statistics',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final pendingPickups = stats['pendingPickups'] ?? 0;
        final totalQuantityReceived = stats['totalQuantityReceived'] ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'quick overview'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NGOImpactScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 16),
                  label: Text('view impact'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_shipping,
                            color: Colors.blue, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'pending pickups'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '$pendingPickups',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.inventory,
                            color: Colors.green, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'food received'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${totalQuantityReceived.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 3. Available Donations Count
  Widget _buildAvailableCountSection(ColorScheme colorScheme) {
    return StreamBuilder<int>(
      stream: _donationService.getAvailableDonationsCount(),
      builder: (context, snapshot) {
        final availableCount = snapshot.data ?? 0;

        return DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fastfood, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'available_donations'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$availableCount',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'items ready for pickup'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Main Actions
  Widget _buildMainActionsSection(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick actions'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'browse donations'.tr(),
                icon: Icons.search,
                onPressed: () {
                  _scrollToSection(_browseKey);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'food requests'.tr(),
                icon: Icons.request_page,
                onPressed: () {
                  Navigator.pushNamed(context, '/requests');
                },
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                textColor: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'my claims'.tr(),
          icon: Icons.list,
          onPressed: () {
            _scrollToSection(_claimsKey);
          },
          backgroundColor: Colors.grey[200],
          textColor: Colors.black87,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'my_chats'.tr(),
                icon: Icons.chat_outlined,
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatRoomsScreen())),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                textColor: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'request_food'.tr(),
                icon: Icons.add_circle_outline,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateRequestScreen())),
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                textColor: Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'notifications'.tr(),
                icon: Icons.notifications_outlined,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                textColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Available Donations List
  Widget _buildAvailableDonationsSection(ColorScheme colorScheme) {
    return Container(
      key: _browseKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getAvailableDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return DashboardCard(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading donations',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final donations = snapshot.data ?? [];
          final filteredDonations = _filterAndSortDonations(donations);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'available_donations'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${filteredDonations.length} ${'items'.tr()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search and Filter Section
              _buildSearchAndFilterSection(colorScheme),
              const SizedBox(height: 16),
              if (filteredDonations.isEmpty)
                DashboardCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'no_donations_found'.tr(),
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'try_adjusting_filters'.tr(),
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredDonations.map((donation) =>
                    _buildAvailableDonationCard(donation, colorScheme)),
            ],
          );
        },
      ),
    );
  }

  // 6. My Claims Section
  Widget _buildMyClaimsSection(UserModel user, ColorScheme colorScheme) {
    return Container(
      key: _claimsKey,
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getNGOClaimedDonations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return DashboardCard(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading claims',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final donations = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'my claims'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${donations.length} ${'items'.tr()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (donations.isEmpty)
                DashboardCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'no claims yet'.tr(),
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'claim donations above'.tr(),
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...donations.map((donation) =>
                    _buildClaimedDonationCard(donation, colorScheme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableDonationCard(
      DonationModel donation, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'available'.tr(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (donation.isExpiringSoon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'expiring soon'.tr(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ExpiryCountdownWidget(
                  expiryTime: donation.expiryTime,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DonationImage(
              imageUrls: donation.imageUrls,
              width: double.infinity,
              height: 140,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text(
              donation.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              donation.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  donation.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${donation.quantity} ${donation.unit}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    donation.location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _claimDonation(donation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('claim donation'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimedDonationCard(
      DonationModel donation, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(donation.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(donation.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  donation.formattedTimestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DonationImage(
              imageUrls: donation.imageUrls,
              width: double.infinity,
              height: 140,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text(
              donation.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              donation.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      donation.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${donation.quantity} ${donation.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (donation.claimedAt != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${'claimed on'.tr()}: ${donation.claimedAt!.day}/${donation.claimedAt!.month}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (donation.status == DonationStatus.claimed)
              OutlinedButton.icon(
                onPressed: () => _releaseDonation(donation),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('release'.tr()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                ),
              ),
            const SizedBox(height: 8),
            if (donation.status == DonationStatus.claimed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestVolunteerTransport(donation),
                  icon: const Icon(Icons.hail),
                  label: const Text('Request Volunteer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            // Chat with Donor — opens the chat room for this claim
            if (donation.status == DonationStatus.claimed ||
                donation.status == DonationStatus.partiallyClaimed ||
                donation.status == DonationStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ChatWithDonorButton(donation: donation),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return Colors.green;
      case DonationStatus.partiallyClaimed:
        return Colors.orange;
      case DonationStatus.claimed:
        return Colors.blue;
      case DonationStatus.completed:
        return Colors.purple;
      case DonationStatus.expired:
        return Colors.red;
    }
  }

  void _claimDonation(DonationModel donation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('claim donation'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('confirm claim donation'.tr()),
            const SizedBox(height: 12),
            Text(
              donation.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${donation.quantity} ${donation.unit} - ${donation.category}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Location: ${donation.location}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _donationService.claimDonation(
                  donationId: donation.id,
                  claimantId: user.uid,
                );
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('donation claimed'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error claiming donation'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _requestVolunteerTransport(DonationModel donation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    final ngoDisplayName =
        user.organizationName?.trim().isNotEmpty == true
            ? user.organizationName!.trim()
            : user.userName?.trim().isNotEmpty == true
                ? user.userName!.trim()
                : user.email;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Volunteer Transport?'),
        content: const Text(
            'A notification will be sent to nearby volunteers to help transport this donation from the donor to your location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                final deliveryData = {
                  'claimId': donation.id, // Linking to donation ID
                  'donationId': donation.id,
                  'volunteerId': '', // Empty means available for any volunteer
                  'donorId': donation.donorId,
                  'ngoId': user.uid,
                  'ngoName': ngoDisplayName,
                  'donationTitle': donation.title,
                  'status': 'pending',
                  'scheduledAt': FieldValue.serverTimestamp(),
                  'notes':
                      'Volunteer transport requested by $ngoDisplayName',
                };

                await firestore.collection('deliveries').add(deliveryData);
                await NotificationService().createRemoteNotificationForUser(
                  userId: donation.donorId,
                  notification: AppNotification(
                    id: 'volunteer_request_${donation.id}_${user.uid}',
                    title: 'Volunteer Requested',
                    message:
                        '$ngoDisplayName requested a volunteer for ${donation.title}.',
                    type: NotificationType.general,
                    priority: NotificationPriority.high,
                    timestamp: DateTime.now(),
                    actionData: 'donor_dashboard',
                    relatedDonationId: donation.id,
                  ),
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Volunteer request sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.secondary),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _releaseDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('release donation'.tr()),
        content: Text('confirm release donation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _donationService.releaseDonation(donation.id);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('donation released'.tr()),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error releasing donation'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('release'.tr()),
          ),
        ],
      ),
    );
  }

  void _completeClaimedDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('complete pickup'.tr()),
        content: Text('confirm complete pickup'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _donationService.completeDonation(donation.id);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('pickup completed'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error completing pickup'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('complete'.tr()),
          ),
        ],
      ),
    );
  }

  // Search and Filter Methods
  Widget _buildSearchAndFilterSection(ColorScheme colorScheme) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'search_donations'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Filter Row
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSortBy,
                  decoration: InputDecoration(
                    labelText: 'sort_by'.tr(),
                    prefixIcon: const Icon(Icons.sort),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSortBy = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DonationModel> _filterAndSortDonations(List<DonationModel> donations) {
    List<DonationModel> filtered = List.from(donations);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((donation) {
        return donation.title.toLowerCase().contains(searchLower) ||
            donation.description.toLowerCase().contains(searchLower) ||
            donation.category.toLowerCase().contains(searchLower) ||
            donation.location.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((donation) {
        return donation.category == _selectedCategory;
      }).toList();
    }

    // Apply sorting
    switch (_selectedSortBy) {
      case 'Newest':
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'Expiry Soon':
        filtered.sort((a, b) => a.expiryTime.compareTo(b.expiryTime));
        break;
      case 'Quantity High':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Quantity Low':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
    }

    return filtered;
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens (or creates) a chat room between this NGO and the donor.
/// Strategy:
///   1. Look for an existing chat_room for this donation that includes both UIDs.
///   2. If none found, create one immediately — no claim acceptance needed.
///   3. Navigate to ChatScreen.
class _ChatWithDonorButton extends StatefulWidget {
  final DonationModel donation;
  const _ChatWithDonorButton({required this.donation});

  @override
  State<_ChatWithDonorButton> createState() => _ChatWithDonorButtonState();
}

class _ChatWithDonorButtonState extends State<_ChatWithDonorButton> {
  bool _loading = false;

  Future<void> _openChat() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null) return;

    final donorId = widget.donation.donorId;
    if (donorId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donor information not found.')),
        );
      }
      return;
    }

    if (uid == donorId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot chat with yourself.')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      String? chatRoomId;

      // ── Step 1: find existing room for this donation involving both users ──
      final existingRooms = await db
          .collection('chat_rooms')
          .where('donationId', isEqualTo: widget.donation.id)
          .where('participantIds', arrayContains: uid)
          .get();

      for (final doc in existingRooms.docs) {
        final participants =
            List<String>.from(doc.data()['participantIds'] ?? []);
        if (participants.contains(donorId)) {
          chatRoomId = doc.id;
          break;
        }
      }

      // ── Step 2: if no room exists, create one now ──────────────────────────
      if (chatRoomId == null) {
        final roomRef = db.collection('chat_rooms').doc();
        await roomRef.set({
          'participantIds': [donorId, uid],
          'donationId': widget.donation.id,
          'lastMessage': null,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'type': 'donor_recipient',
          'unreadCounts': {donorId: 0, uid: 0},
        });
        chatRoomId = roomRef.id;

        // Best-effort: also stamp the claim doc so acceptClaim() knows the room
        try {
          final claims = await db
              .collection('claims')
              .where('donationId', isEqualTo: widget.donation.id)
              .where('claimantId', isEqualTo: uid)
              .limit(1)
              .get();
          if (claims.docs.isNotEmpty) {
            await claims.docs.first.reference
                .update({'chatRoomId': chatRoomId});
          }
        } catch (_) {
          // Non-critical — ignore
        }
      }

      if (!mounted) return;

      // ── Step 3: resolve donor display name ────────────────────────────────
      String donorName = 'Donor';
      try {
        final donorSnap =
            await db.collection('users').doc(donorId).get();
        if (donorSnap.exists) {
          final d = donorSnap.data()!;
          donorName = (d['userName'] ?? d['organizationName'] ?? d['email'])
                  ?.toString() ??
              'Donor';
        }
      } catch (_) {}

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId!,
            otherUserName: donorName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        onPressed: _loading ? null : _openChat,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.chat_outlined),
        label: Text('chat_with_donor'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
