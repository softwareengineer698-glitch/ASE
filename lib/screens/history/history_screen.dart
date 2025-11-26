import 'package:flutter/material.dart';
import 'package:foodbridge/models/donation_model.dart';
import 'package:foodbridge/models/user_model.dart';
import 'package:foodbridge/providers/auth_provider.dart';
import 'package:foodbridge/services/donation_service.dart';
import 'package:foodbridge/services/profile_service.dart';
import 'package:foodbridge/widgets/empty_state_widget.dart';
import 'package:foodbridge/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying user's donation/request history
/// Shows different content based on user role (Donor/NGO)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DonationService _donationService = DonationService();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Only 2 tabs needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view history'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.role == UserRole.donor ? 'History' : 'Pickup'),
        bottom: TabBar(
          controller: _tabController,
          tabs: user.role == UserRole.donor
              ? [
                  Tab(
                      text: 'my_donations'.tr(),
                      icon: const Icon(Icons.volunteer_activism)),
                  Tab(
                      text: 'completed'.tr(),
                      icon: const Icon(Icons.check_circle)),
                ]
              : [
                  Tab(text: 'claimed'.tr(), icon: const Icon(Icons.handshake)),
                  Tab(
                      text: 'completed'.tr(),
                      icon: const Icon(Icons.check_circle)),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: user.role == UserRole.donor
            ? [
                _buildDonorDonations(user),
                _buildDonorCompletedDonations(user),
              ]
            : [
                _buildNGOClaimedDonations(user),
                _buildNGOCompletedDonations(user),
              ],
      ),
    );
  }

  Widget _buildDonorDonations(UserModel user) {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getDonorDonations(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            title: 'error_loading_history'.tr(),
            message: snapshot.error.toString(),
            icon: Icons.error,
          );
        }

        final donations = snapshot.data ?? [];
        final activeDonations = donations
            .where((d) =>
                d.status == DonationStatus.available ||
                d.status == DonationStatus.claimed)
            .toList();

        if (activeDonations.isEmpty) {
          return EmptyStateWidget(
            title: 'no_active_donations'.tr(),
            message: 'no_active_donations_desc'.tr(),
            icon: Icons.volunteer_activism,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeDonations.length,
          itemBuilder: (context, index) {
            final donation = activeDonations[index];
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildDonorCompletedDonations(UserModel user) {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getDonorDonations(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            title: 'error_loading_history'.tr(),
            message: snapshot.error.toString(),
            icon: Icons.error,
          );
        }

        final donations = snapshot.data ?? [];
        final completedDonations = donations
            .where((d) => d.status == DonationStatus.completed)
            .toList();

        if (completedDonations.isEmpty) {
          return EmptyStateWidget(
            title: 'no_completed_donations'.tr(),
            message: 'no_completed_donations_desc'.tr(),
            icon: Icons.check_circle,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedDonations.length,
          itemBuilder: (context, index) {
            final donation = completedDonations[index];
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildNGOClaimedDonations(UserModel user) {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getNGOClaimedDonations(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            title: 'error_loading_history'.tr(),
            message: snapshot.error.toString(),
            icon: Icons.error,
          );
        }

        final donations = snapshot.data ?? [];
        final claimedDonations =
            donations.where((d) => d.status == DonationStatus.claimed).toList();

        if (claimedDonations.isEmpty) {
          return EmptyStateWidget(
            title: 'no_claimed_donations'.tr(),
            message: 'no_claimed_donations_desc'.tr(),
            icon: Icons.handshake,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claimedDonations.length,
          itemBuilder: (context, index) {
            final donation = claimedDonations[index];
            return _buildNGOClaimedDonationCard(donation, user);
          },
        );
      },
    );
  }

  Widget _buildNGOCompletedDonations(UserModel user) {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getNGOClaimedDonations(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            title: 'error_loading_history'.tr(),
            message: snapshot.error.toString(),
            icon: Icons.error,
          );
        }

        final donations = snapshot.data ?? [];
        final completedDonations = donations
            .where((d) => d.status == DonationStatus.completed)
            .toList();

        if (completedDonations.isEmpty) {
          return EmptyStateWidget(
            title: 'no_completed_pickups'.tr(),
            message: 'no_completed_pickups_desc'.tr(),
            icon: Icons.check_circle,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedDonations.length,
          itemBuilder: (context, index) {
            final donation = completedDonations[index];
            return _buildDonationCard(donation);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
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
              ],
            ),
            if (donation.status == DonationStatus.claimed &&
                donation.claimedBy != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _showNGOContact(donation.claimedBy!),
                    icon: const Icon(Icons.business, color: Colors.blue),
                    tooltip: 'Contact NGO',
                  ),
                  IconButton(
                    onPressed: () => _showDonationDetails(donation),
                    icon: const Icon(Icons.info, color: Colors.green),
                    tooltip: 'Details',
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
      case DonationStatus.claimed:
        return Colors.blue;
      case DonationStatus.completed:
        return Colors.purple;
      case DonationStatus.expired:
        return Colors.red;
    }
  }

  Widget _buildNGOClaimedDonationCard(DonationModel donation, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _showDonorContact(donation.donorId),
                  icon: const Icon(Icons.phone, color: Colors.blue),
                  tooltip: 'Contact Donor',
                ),
                IconButton(
                  onPressed: () => _showDonationDetails(donation),
                  icon: const Icon(Icons.info, color: Colors.green),
                  tooltip: 'Details',
                ),
                IconButton(
                  onPressed: () => _openLocationInMaps(donation.location),
                  icon: const Icon(Icons.location_on, color: Colors.red),
                  tooltip: 'Location',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDonorContact(String donorId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Donor Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading donor information...'),
          ],
        ),
      ),
    );

    try {
      final profileService = ProfileService();
      final donorProfile = await profileService.getUserProfile(donorId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(donorProfile?.name ?? 'Donor Contact'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donorProfile?.name != null) ...[
                  Text('Name: ${donorProfile!.name}'),
                  const SizedBox(height: 8),
                ],
                if (donorProfile?.email != null) ...[
                  Text('Email: ${donorProfile!.email}'),
                  const SizedBox(height: 8),
                ],
                if (donorProfile?.phone != null) ...[
                  Text('Phone: ${donorProfile!.phone}'),
                  const SizedBox(height: 8),
                ],
                if (donorProfile?.address != null) ...[
                  Text('Address: ${donorProfile!.address}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (donorProfile?.phone != null)
                TextButton(
                  onPressed: () async {
                    final phoneUrl = 'tel:${donorProfile!.phone}';
                    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                      await launchUrl(Uri.parse(phoneUrl));
                    }
                  },
                  child: const Text('Call'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading donor info: $e')),
        );
      }
    }
  }

  void _openLocationInMaps(String location) async {
    try {
      // Create Google Maps URL for the location
      final encodedLocation = Uri.encodeComponent(location);
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$encodedLocation';

      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: show location in dialog if can't launch maps
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pickup Location'),
              content: Text(
                  'Location: $location\n\nCould not open maps app. Please copy the location and search manually.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    // Copy location to clipboard
                    // TODO: Add clipboard functionality if needed
                    Navigator.pop(context);
                  },
                  child: const Text('Copy Location'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
  }

  void _showNGOContact(String ngoId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('NGO Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading NGO information...'),
          ],
        ),
      ),
    );

    try {
      final profileService = ProfileService();
      final ngoProfile = await profileService.getUserProfile(ngoId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(ngoProfile?.name ?? 'NGO Contact'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ngoProfile?.name != null) ...[
                  Text('Name: ${ngoProfile!.name}'),
                  const SizedBox(height: 8),
                ],
                if (ngoProfile?.email != null) ...[
                  Text('Email: ${ngoProfile!.email}'),
                  const SizedBox(height: 8),
                ],
                if (ngoProfile?.phone != null) ...[
                  Text('Phone: ${ngoProfile!.phone}'),
                  const SizedBox(height: 8),
                ],
                if (ngoProfile?.organization != null) ...[
                  Text('Organization: ${ngoProfile!.organization}'),
                  const SizedBox(height: 8),
                ],
                if (ngoProfile?.address != null) ...[
                  Text('Address: ${ngoProfile!.address}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (ngoProfile?.phone != null)
                TextButton(
                  onPressed: () async {
                    final phoneUrl = 'tel:${ngoProfile!.phone}';
                    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                      await launchUrl(Uri.parse(phoneUrl));
                    }
                  },
                  child: const Text('Call'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading NGO info: $e')),
        );
      }
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
}
