import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

/// Dedicated leaderboard screen showing top performers
/// Displays separate leaderboards for donors and NGOs
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadLeaderboards() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);

    if (authProvider.user != null) {
      analyticsProvider.loadLeaderboards(
        authProvider.user!.uid,
        authProvider.user!.role,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AnalyticsProvider, AuthProvider, ThemeProvider>(
      builder:
          (context, analyticsProvider, authProvider, themeProvider, child) {
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadLeaderboards(),
              ),
            ],
          ),
          body: analyticsProvider.isLoadingLeaderboard
              ? LoadingWidget(message: 'loading'.tr())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDonorLeaderboard(
                        analyticsProvider, user, themeProvider),
                    _buildNGOLeaderboard(
                        analyticsProvider, user, themeProvider),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDonorLeaderboard(AnalyticsProvider analyticsProvider,
      UserModel? user, ThemeProvider themeProvider) {
    return RefreshIndicator(
      onRefresh: () => analyticsProvider.loadLeaderboards(
        user?.uid ?? '',
        user?.role ?? UserRole.donor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period Selector
            _buildPeriodSelector(analyticsProvider, user, themeProvider),

            const SizedBox(height: 20),

            // Current User Highlight (if donor)
            if (user?.role == UserRole.donor)
              _buildCurrentUserCard(
                  analyticsProvider, user!, themeProvider, UserRole.donor),

            const SizedBox(height: 20),

            // Top 3 Podium
            _buildPodium(analyticsProvider.donorLeaderboard, themeProvider,
                'kg_donated_metric'.tr()),

            const SizedBox(height: 24),

            // Full Leaderboard
            _buildFullLeaderboard(
              analyticsProvider.donorLeaderboard,
              themeProvider,
              'kg_donated_metric'.tr(),
              user?.uid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNGOLeaderboard(AnalyticsProvider analyticsProvider,
      UserModel? user, ThemeProvider themeProvider) {
    return RefreshIndicator(
      onRefresh: () => analyticsProvider.loadLeaderboards(
        user?.uid ?? '',
        user?.role ?? UserRole.ngo,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period Selector
            _buildPeriodSelector(analyticsProvider, user, themeProvider),

            const SizedBox(height: 20),

            // Current User Highlight (if NGO)
            if (user?.role == UserRole.ngo)
              _buildCurrentUserCard(
                  analyticsProvider, user!, themeProvider, UserRole.ngo),

            const SizedBox(height: 20),

            // Top 3 Podium
            _buildPodium(analyticsProvider.ngoLeaderboard, themeProvider,
                'pickups_metric'.tr()),

            const SizedBox(height: 24),

            // Full Leaderboard
            _buildFullLeaderboard(
              analyticsProvider.ngoLeaderboard,
              themeProvider,
              'pickups_metric'.tr(),
              user?.uid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider analyticsProvider,
      UserModel? user, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'time_period'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  analyticsProvider.leaderboardPeriodOptions.map((option) {
                final isSelected =
                    analyticsProvider.selectedLeaderboardPeriod ==
                        option['value'];
                return FilterChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && user != null) {
                      analyticsProvider.setLeaderboardPeriod(
                        option['value']!,
                        user.uid,
                        user.role,
                      );
                    }
                  },
                  selectedColor: themeProvider.primaryColor.withOpacity(0.2),
                  checkmarkColor: themeProvider.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(AnalyticsProvider analyticsProvider,
      UserModel user, ThemeProvider themeProvider, UserRole role) {
    final rank = analyticsProvider.getUserRank(user.uid, role);
    final badge = analyticsProvider.getUserBadge(user.uid, role);

    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeProvider.primaryColor.withOpacity(0.1),
              themeProvider.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 35,
                backgroundColor: themeProvider.primaryColor,
                child: Text(
                  user.email.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Rank',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank != null ? '#$rank' : 'Not ranked',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trophy Icon
              Icon(
                Icons.emoji_events,
                size: 40,
                color: themeProvider.primaryColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(
      List<dynamic> leaderboard, ThemeProvider themeProvider, String unit) {
    if (leaderboard.length < 3) {
      return const EmptyStateWidget(
        icon: Icons.emoji_events,
        title: 'Not Enough Data',
        message: 'Need at least 3 participants for podium display.',
      );
    }

    final top3 = leaderboard.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Top Performers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                if (top3.length > 1)
                  _buildPodiumPosition(top3[1], 2, Colors.grey, 80, unit),

                // 1st Place
                _buildPodiumPosition(top3[0], 1, Colors.amber, 100, unit),

                // 3rd Place
                if (top3.length > 2)
                  _buildPodiumPosition(top3[2], 3, Colors.brown, 60, unit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPosition(
      dynamic entry, int position, Color color, double height, String unit) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 25,
          backgroundColor: color,
          child: Text(
            position.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // Value
        Text(
          '${entry.value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Podium Bar
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullLeaderboard(List<dynamic> leaderboard,
      ThemeProvider themeProvider, String unit, String? currentUserId) {
    if (leaderboard.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.leaderboard,
        title: 'no_data'.tr(),
        message: 'Leaderboard data will appear here once available.',
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Full Rankings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...leaderboard.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final isCurrentUser = entry.isCurrentUser;
            final isTopThree = index < 3;

            return Container(
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? themeProvider.primaryColor.withOpacity(0.1)
                    : null,
                border: isCurrentUser
                    ? Border.all(
                        color: themeProvider.primaryColor.withOpacity(0.3))
                    : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isTopThree
                      ? _getRankColor(entry.rank)
                      : themeProvider.primaryColor.withOpacity(0.7),
                  child: isTopThree
                      ? Icon(
                          _getRankIcon(entry.rank),
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          entry.rank.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          fontWeight: isCurrentUser
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(entry.badge),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.value.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isCurrentUser ? themeProvider.primaryColor : null,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }
}
