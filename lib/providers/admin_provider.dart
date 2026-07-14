import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  // Note: pendingNGOs stat removed - NGO verification layer removed per requirements
  Map<String, int> _stats = {
    'totalUsers': 0,
    'activeNGOs': 0,
    'donors': 0,
    'volunteers': 0,
  };
  List<UserModel> _allDonors = [];
  List<UserModel> _allNGOs = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _statsSubscription;
  StreamSubscription? _donorsSubscription;
  StreamSubscription? _ngosSubscription;

  Map<String, int> get stats => _stats;
  List<UserModel> get allDonors => _allDonors;
  List<UserModel> get allNGOs => _allNGOs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _cancelSubscriptions();

    _statsSubscription = _adminService.streamSystemStats().listen((newStats) {
      _stats = newStats;
      notifyListeners();
    }, onError: (e) {
      _error = 'Error loading stats: $e';
      notifyListeners();
    });

    _donorsSubscription = _adminService.streamAllDonors().listen((donors) {
      _allDonors = donors;
      notifyListeners();
    }, onError: (e) {
      _error = 'Error loading donors: $e';
      notifyListeners();
    });

    _ngosSubscription = _adminService.streamAllNGOs().listen((ngos) {
      _allNGOs = ngos;
      notifyListeners();
    }, onError: (e) {
      _error = 'Error loading NGOs: $e';
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _statsSubscription?.cancel();
    _donorsSubscription?.cancel();
    _ngosSubscription?.cancel();

    _statsSubscription = null;
    _donorsSubscription = null;
    _ngosSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  Future<bool> deleteUser(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _adminService.deleteUser(uid);
      return true;
    } catch (e) {
      _error = 'Error deleting user: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
