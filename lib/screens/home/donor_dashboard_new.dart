import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/donation_image.dart';
import '../../widgets/enhanced_button.dart';
import '../../widgets/responsive_widget.dart';
import '../auth/sign_in_screen.dart';
import '../history/history_screen.dart';
import '../donor/create_donation_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final DonationService _donationService = DonationService();

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

  @override
  void initState() {
    super.initState();
    _selectedFoodIcon =
        _foodIcons[(DateTime.now().millisecondsSinceEpoch) % _foodIcons.length];
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
            child: ResponsiveLayout(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section with improved spacing
                    _buildHeaderSection(user, colorScheme),
                    const SizedBox(height: 24),

                    // 2. Main Actions - Responsive layout
                    ResponsiveWidget(
                      mobile: _buildMainActionsMobile(context, colorScheme),
                      tablet: _buildMainActionsDesktop(context, colorScheme),
                      desktop: _buildMainActionsDesktop(context, colorScheme),
                    ),
                    const SizedBox(height: 24),

                    // 3. Active Donations List with better spacing
                    SizedBox(
                      height: 300,
                      child: _buildActiveDonationsSection(user, colorScheme),
                    ),
                  ],
                ),
              ),
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
              Icons.person,
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
                        .then()
                        .scale(
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1, 1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ready_to_help_today'.tr(),
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

  // 3. Main Actions - Mobile Layout
  Widget _buildMainActionsMobile(
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
        Column(
          children: [
            EnhancedButton(
              text: 'create donation'.tr(),
              icon: Icons.add_circle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateDonationScreen(),
                  ),
                );
              },
              semanticLabel: 'Create new food donation',
            ),
            const SizedBox(height: 12),
            EnhancedOutlinedButton(
              text: 'view history'.tr(),
              icon: Icons.history,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              semanticLabel: 'View donation history',
            ),
          ],
        ),
      ],
    );
  }

  // 3. Main Actions - Desktop/Tablet Layout
  Widget _buildMainActionsDesktop(
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
              child: EnhancedButton(
                text: 'create donation'.tr(),
                icon: Icons.add_circle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateDonationScreen(),
                    ),
                  );
                },
                semanticLabel: 'Create new food donation',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EnhancedOutlinedButton(
                text: 'view history'.tr(),
                icon: Icons.history,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                semanticLabel: 'View donation history',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Active Donations List
  Widget _buildActiveDonationsSection(UserModel user, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: StreamBuilder<List<DonationModel>>(
        stream: _donationService.getDonorDonations(user.uid),
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
          final activeDonations = donations
              .where((d) =>
                  d.status == DonationStatus.available ||
                  d.status == DonationStatus.claimed)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'active donations'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${activeDonations.length} ${'items'.tr()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: activeDonations.isEmpty
                    ? DashboardCard(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'no active donations'.tr(),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'create first donation'.tr(),
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeDonations.length,
                        itemBuilder: (context, index) {
                          final donation = activeDonations[index];
                          return _buildDonationCard(donation, colorScheme);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation, ColorScheme colorScheme) {
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
                Expanded(
                  child: Text(
                    donation.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${donation.quantity} ${donation.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (donation.status == DonationStatus.claimed) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _completeDonation(donation),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('complete'.tr()),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showDonationDetails(donation),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text(''),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(40, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteDonation(donation),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(''),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(40, 36),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // NGO verification status inline
              if (donation.claimedBy != null)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(donation.claimedBy)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final ngoName = data['organizationName'] ??
                        data['userName'] ??
                        'NGO';
                    final isVerified = data['isVerified'] == true;
                    return Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.pending,
                          size: 14,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isVerified
                                ? '$ngoName · Verified NGO'
                                : '$ngoName · Verification Pending',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isVerified ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ] else if (donation.status == DonationStatus.available) ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showDonationDetails(donation),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text(''),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(40, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteDonation(donation),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(''),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(40, 36),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
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

  void _showDonationDetails(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donation.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${donation.category}'),
              const SizedBox(height: 8),
              Text('Quantity: ${donation.quantity} ${donation.unit}'),
              const SizedBox(height: 8),
              Text('Location: ${donation.location}'),
              const SizedBox(height: 8),
              Text('Status: ${donation.statusDisplayName}'),
              const SizedBox(height: 8),
              const Text('Description:'),
              Text(donation.description),
              const SizedBox(height: 8),
              Text('Posted: ${donation.formattedTimestamp}'),
              const SizedBox(height: 8),
              Text('Expires: ${donation.expiryTime}'),
              if (donation.status == DonationStatus.claimed &&
                  donation.claimedBy != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Claimed by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(donation.claimedBy)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading NGO info...'),
                        ],
                      );
                    }

                    String ngoName = 'NGO';
                    bool isVerified = false;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      ngoName = data['organizationName'] ??
                          data['userName'] ??
                          data['email'] ??
                          'NGO';
                      isVerified = data['isVerified'] == true;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.withOpacity(0.08)
                            : Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isVerified
                              ? Colors.green.withOpacity(0.4)
                              : Colors.orange.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isVerified
                                ? Colors.green.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            child: Icon(
                              Icons.business,
                              size: 20,
                              color:
                                  isVerified ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ngoName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified
                                          : Icons.pending,
                                      size: 14,
                                      color: isVerified
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVerified
                                          ? 'Verified NGO'
                                          : 'Verification Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isVerified
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete donation'.tr()),
        content: Text('confirm delete donation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _donationService.deleteDonation(donation.id);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('donation deleted'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error deleting donation'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _completeDonation(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('complete donation'.tr()),
        content: Text('confirm complete donation'.tr()),
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
                      content: Text('donation completed'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error completing donation'.tr()),
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
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const MetricCard({
    required this.title, required this.value, required this.icon, required this.color, super.key,
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
