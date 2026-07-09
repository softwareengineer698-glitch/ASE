import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';

/// Real-time leaderboard screen showing top performers
/// Displays separate leaderboards for donors and NGOs using live Firestore data
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DonationService _donationService = DonationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: Text('leaderboard_title'.tr()),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                    text: 'top_donors'.tr(),
                    icon: const Icon(Icons.volunteer_activism)),
                Tab(text: 'top_ngos'.tr(), icon: const Icon(Icons.business)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDonorLeaderboard(user, themeProvider),
              _buildNGOLeaderboard(user, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonorLeaderboard(UserModel? user, ThemeProvider themeProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _donationService.getDonorLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'error_loading_leaderboard'.tr(),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('retry'.tr()),
                ),
              ],
            ),
          );
        }

        final leaderboard = snapshot.data ?? [];

        if (leaderboard.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'no_donors_yet'.tr(),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'start_making_difference'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Current User Highlight (if donor)
                if (user?.role == UserRole.donor)
                  _buildCurrentUserCard(
                      leaderboard, user!, themeProvider, UserRole.donor),

                const SizedBox(height: 20),

                // Top 3 Podium
                _buildPodium(
                    leaderboard, themeProvider, 'kg_donated_metric'.tr()),

                const SizedBox(height: 24),

                // Full Leaderboard
                _buildFullLeaderboard(
                  leaderboard,
                  themeProvider,
                  'kg_donated_metric'.tr(),
                  user?.uid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNGOLeaderboard(UserModel? user, ThemeProvider themeProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _donationService.getNGOLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading leaderboard',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final leaderboard = snapshot.data ?? [];

        if (leaderboard.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No NGOs yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'start_making_difference'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Current User Highlight (if NGO)
                if (user?.role == UserRole.ngo)
                  _buildCurrentUserCard(
                      leaderboard, user!, themeProvider, UserRole.ngo),

                const SizedBox(height: 20),

                // Top 3 Podium
                _buildPodium(leaderboard, themeProvider, 'pickups_metric'.tr()),

                const SizedBox(height: 24),

                // Full Leaderboard
                _buildFullLeaderboard(
                  leaderboard,
                  themeProvider,
                  'pickups_metric'.tr(),
                  user?.uid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserCard(List<Map<String, dynamic>> leaderboard,
      UserModel user, ThemeProvider themeProvider, UserRole role) {
    final userIndex =
        leaderboard.indexWhere((item) => item['userId'] == user.uid);

    if (userIndex == -1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: themeProvider.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'your_progress'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'start_donating_to_appear'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userData = leaderboard[userIndex];
    final rank = userIndex + 1;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              themeProvider.primaryColor.withOpacity(0.1),
              themeProvider.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'you'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    role == UserRole.donor
                        ? '${userData['completedDonations']} ${'donations_count'.tr()}'
                        : '${userData['completedPickups']} ${'pickups_count'.tr()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userData['totalQuantity']?.toStringAsFixed(1) ?? '0.0'} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> leaderboard,
      ThemeProvider themeProvider, String metric) {
    if (leaderboard.isEmpty) return const SizedBox.shrink();

    final top3 = leaderboard.take(3).toList();

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events,
                    color: themeProvider.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'top_performers'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: top3.asMap().entries.map((entry) {
                final index = entry.key;
                final userData = entry.value;
                final rank = index + 1;

                Color medalColor;
                double scale;
                if (rank == 1) {
                  medalColor = Colors.amber;
                  scale = 1.2;
                } else if (rank == 2) {
                  medalColor = Colors.grey[400]!;
                  scale = 1.1;
                } else {
                  medalColor = Colors.brown[400]!;
                  scale = 1.0;
                }

                return Column(
                  children: [
                    Container(
                      width: 60 * scale,
                      height: 60 * scale,
                      decoration: BoxDecoration(
                        color: medalColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24 * scale,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        userData['name'] ?? userData['email'].split('@')[0],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${userData['completedDonations'] ?? userData['completedPickups']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      metric,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullLeaderboard(List<Map<String, dynamic>> leaderboard,
      ThemeProvider themeProvider, String metric, String? currentUserId) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.list, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'full_rankings'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final userData = leaderboard[index];
              final rank = index + 1;
              final isCurrentUser = userData['userId'] == currentUserId;

              return Container(
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? themeProvider.primaryColor.withOpacity(0.1)
                      : null,
                  border: isCurrentUser
                      ? Border.all(color: themeProvider.primaryColor)
                      : null,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(rank),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    userData['name'] ?? userData['email'].split('@')[0],
                    style: TextStyle(
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    userData['email'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${userData['completedDonations'] ?? userData['completedPickups']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${userData['totalQuantity'].toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[400]!;
    return Colors.blue;
  }
}
