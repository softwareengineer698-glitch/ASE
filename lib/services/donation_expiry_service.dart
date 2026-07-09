import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_service.dart';

/// Background service to handle automatic expiry of donations
/// This service runs periodically to check and expire donations
class DonationExpiryService {
  static final DonationExpiryService _instance =
      DonationExpiryService._internal();
  factory DonationExpiryService() => _instance;
  DonationExpiryService._internal();

  final DonationService _donationService = DonationService();
  Timer? _expiryTimer;
  bool _isRunning = false;

  /// Start the expiry service
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint('Donation expiry service started');

    // Check for expired donations every 5 minutes
    _expiryTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkAndExpireDonations();
    });

    // Also run immediately on start
    _checkAndExpireDonations();
  }

  /// Stop the expiry service
  void stop() {
    if (!_isRunning) return;

    _expiryTimer?.cancel();
    _expiryTimer = null;
    _isRunning = false;
    debugPrint('Donation expiry service stopped');
  }

  /// Check and expire donations that are past their expiry time
  Future<void> _checkAndExpireDonations() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('Skip checking for expired donations: No user signed in');
        return;
      }
      debugPrint('Checking for expired donations...');
      await _donationService.expireDonations();
      debugPrint('Expiry check completed');
    } catch (e) {
      debugPrint('Error during expiry check: $e');
    }
  }

  /// Manual expiry check (can be called from UI)
  Future<void> checkExpiryNow() async {
    await _checkAndExpireDonations();
  }

  bool get isRunning => _isRunning;
}
