import 'package:flutter/material.dart';
import '../models/volunteer_model.dart';
import '../models/delivery_model.dart';
import '../services/volunteer_service.dart';

class VolunteerProvider extends ChangeNotifier {
  final VolunteerService _volunteerService = VolunteerService();

  VolunteerModel? _currentVolunteer;
  List<DeliveryModel> _assignedDeliveries = [];
  List<DeliveryModel> _availableTasks = [];
  bool _isLoading = false;
  String? _error;

  VolunteerModel? get currentVolunteer => _currentVolunteer;
  List<DeliveryModel> get assignedDeliveries => _assignedDeliveries;
  List<DeliveryModel> get availableTasks => _availableTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAvailable =>
      _currentVolunteer?.status == VolunteerStatus.available;

  // Initialize for a volunteer user
  void initialize(String userId, {String? name}) async {
    // Check if profile exists; if not, create it
    final existing = await _volunteerService.getVolunteerProfile(userId);
    if (existing == null) {
      await registerAsVolunteer(
        userId: userId,
        name: name ?? 'Volunteer',
        phone: '',
      );
    }

    _volunteerService.streamVolunteerProfile(userId).listen((volunteer) {
      _currentVolunteer = volunteer;
      notifyListeners();
    });

    _volunteerService.streamAssignedDeliveries(userId).listen((deliveries) {
      _assignedDeliveries = deliveries;
      notifyListeners();
    });

    _volunteerService.streamAvailableTasks().listen((tasks) {
      _availableTasks = tasks;
      notifyListeners();
    });
  }

  // Specialized listener for NGOs
  void initializeForNGO(String ngoId) {
    _volunteerService.streamNGODeliveries(ngoId).listen((deliveries) {
      _assignedDeliveries = deliveries; // Reuse list for NGO perspective
      notifyListeners();
    });
  }

  // Specialized listener for Donors
  void initializeForDonor(String donorId) {
    _volunteerService.streamDonorDeliveries(donorId).listen((deliveries) {
      _assignedDeliveries = deliveries; // Reuse list for Donor perspective
      notifyListeners();
    });
  }

  // Toggle availability
  Future<void> toggleAvailability() async {
    if (_currentVolunteer == null) {
      _error = 'Volunteer profile not found. Please try again in a moment.';
      notifyListeners();
      return;
    }

    final newStatus = _currentVolunteer!.status == VolunteerStatus.available
        ? VolunteerStatus.offline
        : VolunteerStatus.available;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _volunteerService.updateStatus(
          _currentVolunteer!.userId, newStatus);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update status
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      await _volunteerService.updateDeliveryStatus(deliveryId, status);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Claim a delivery task
  Future<void> claimDelivery(String deliveryId) async {
    if (_currentVolunteer == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _volunteerService.claimDelivery(
          deliveryId, _currentVolunteer!.userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register as volunteer
  Future<void> registerAsVolunteer({
    required String userId,
    required String name,
    required String phone,
    List<String> preferredAreas = const [],
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newVolunteer = VolunteerModel(
        id: userId,
        userId: userId,
        name: name,
        phone: phone,
        preferredAreas: preferredAreas,
      );

      await _volunteerService.updateVolunteerProfile(newVolunteer);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
