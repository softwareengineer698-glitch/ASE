import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/sign_in_screen.dart';

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
          backgroundColor: colorScheme.background,
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
                      maxWidth:
                          constraints.maxWidth > 800 ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section
                        _buildHeaderSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 2. Real-time Stats Dashboard Cards
                        _buildRealTimeStatsSection(user, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 3. Available Donations Count
                        _buildAvailableCountSection(colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 4. Main Actions
                        _buildMainActionsSection(context, colorScheme),
                        SizedBox(height: constraints.maxHeight * 0.03),

                        // 5. Available Donations List
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
            backgroundColor: colorScheme.primary.withOpacity(0.1),
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

  // 2. Real-time Stats Dashboard Cards
  Widget _buildRealTimeStatsSection(UserModel user, ColorScheme colorScheme) {
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
        final claimedDonations = stats['claimedDonations'] ?? 0;
        final completedPickups = stats['completedPickups'] ?? 0;
        final pendingPickups = stats['pendingPickups'] ?? 0;
        final totalQuantityReceived = stats['totalQuantityReceived'] ?? 0.0;
        final recentActivity = stats['recentActivity'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your impact'.tr(),
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
                  child: MetricCard(
                    title: 'claimed'.tr(),
                    value: '$claimedDonations',
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    subtitle: 'total claims'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'pending'.tr(),
                    value: '$pendingPickups',
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    subtitle: 'awaiting pickup'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'completed'.tr(),
                    value: '$completedPickups',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    subtitle: 'successful pickups'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'food received'.tr(),
                    value: '${totalQuantityReceived.toStringAsFixed(1)} kg',
                    icon: Icons.inventory,
                    color: Colors.purple,
                    subtitle: 'total quantity'.tr(),
                  ),
                ),
              ],
            ),
            if (recentActivity != null) ...[
              const SizedBox(height: 16),
              DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'recent activity'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recentActivity['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recentActivity['quantity']} ${recentActivity['unit']} - ${recentActivity['category']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                text: 'my claims'.tr(),
                icon: Icons.list,
                onPressed: () {
                  _scrollToSection(_claimsKey);
                },
                backgroundColor: Colors.grey[300],
                textColor: Colors.black87,
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
                    color: Colors.green.withOpacity(0.1),
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
                      color: Colors.orange.withOpacity(0.1),
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
                Text(
                  donation.formattedExpiryDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
                    color: _getStatusColor(donation.status).withOpacity(0.1),
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
                        'claimed on'.tr() +
                            ': ${donation.claimedAt!.day}/${donation.claimedAt!.month}',
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
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return Colors.green;
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
                await _donationService.claimDonation(donation.id, user.uid);
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
                  value: _selectedCategory,
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
                  value: _selectedSortBy,
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
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
                  color: color.withOpacity(0.1),
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
