import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/donation_service.dart';

/// Unified leaderboard — single ranking by total kg donated across all users.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DonationService _donationService = DonationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard_title'.tr()),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                  Text(snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No donations yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Be the first to donate!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final rank = index + 1;
                final name = entry['userName'] as String? ??
                    entry['email'] as String? ?? 'Anonymous';
                final kg = (entry['totalQuantity'] as num?)?.toDouble() ?? 0.0;
                final donations = entry['donationCount'] as int? ?? 0;

                return _buildRankCard(context, rank, name, kg, donations);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, int rank, String name,
      double kg, int donations) {
    Color rankColor;
    IconData rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // gold
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // silver
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // bronze
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.grey.shade400;
      rankIcon = Icons.person;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: rank <= 3 ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: rank <= 3
            ? BorderSide(color: rankColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rankColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 26)
                  : Center(
                      child: Text('$rank',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: rankColor))),
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.length > 20
                        ? '${name.substring(0, 17)}...'
                        : name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('$donations donation${donations != 1 ? "s" : ""}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            // KG donated
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${kg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: rankColor == Colors.grey.shade400
                            ? Colors.blueGrey
                            : rankColor)),
                const Text('donated',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
