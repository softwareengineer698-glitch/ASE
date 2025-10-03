import 'dart:math';
import '../models/surplus_item.dart';

class LocalSurplusService {
  // Singleton pattern for global state management
  static final LocalSurplusService _instance = LocalSurplusService._internal();
  factory LocalSurplusService() => _instance;
  LocalSurplusService._internal();

  // In-memory storage (will be replaced with Firestore later)
  final List<SurplusItem> _surplusItems = [];

  // Stream controller for real-time updates (simulating Firestore streams)
  final List<Function(List<SurplusItem>)> _listeners = [];

  // Initialize with some mock data for testing
  void initializeMockData() {
    if (_surplusItems.isEmpty) {
      _surplusItems.addAll([
        SurplusItem(
          id: _generateId(),
          foodType: 'Fresh Vegetables',
          quantity: 50,
          expiryDate: DateTime.now().add(const Duration(days: 3)),
          reportedDate: DateTime.now().subtract(const Duration(hours: 2)),
          donorName: 'Green Grocery Store',
          status: SurplusStatus.available,
        ),
        SurplusItem(
          id: _generateId(),
          foodType: 'Bread & Bakery Items',
          quantity: 20,
          expiryDate: DateTime.now().add(const Duration(days: 1)),
          reportedDate: DateTime.now().subtract(const Duration(hours: 4)),
          donorName: 'City Bakery',
          status: SurplusStatus.available,
        ),
        SurplusItem(
          id: _generateId(),
          foodType: 'Canned Goods',
          quantity: 100,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          reportedDate: DateTime.now().subtract(const Duration(hours: 6)),
          donorName: 'Supermart',
          status: SurplusStatus.accepted,
        ),
        SurplusItem(
          id: _generateId(),
          foodType: 'Rice & Grains',
          quantity: 75,
          expiryDate: DateTime.now().add(const Duration(days: 60)),
          reportedDate: DateTime.now().subtract(const Duration(days: 2)),
          donorName: 'Wholesale Market',
          status: SurplusStatus.collected,
        ),
        SurplusItem(
          id: _generateId(),
          foodType: 'Dairy Products',
          quantity: 30,
          expiryDate: DateTime.now().add(const Duration(days: 5)),
          reportedDate: DateTime.now().subtract(const Duration(days: 1)),
          donorName: 'Local Dairy Farm',
          status: SurplusStatus.collected,
        ),
        SurplusItem(
          id: _generateId(),
          foodType: 'Frozen Meals',
          quantity: 40,
          expiryDate: DateTime.now().add(const Duration(days: 14)),
          reportedDate: DateTime.now().subtract(const Duration(hours: 8)),
          donorName: 'Restaurant Chain',
          status: SurplusStatus.collected,
        ),
      ]);
      _notifyListeners();
    }
  }

  // Get all surplus items
  List<SurplusItem> getAllSurplusItems() {
    return List.unmodifiable(_surplusItems);
  }

  // Get available surplus items (for NGOs)
  List<SurplusItem> getAvailableSurplusItems() {
    return _surplusItems
        .where((item) => item.status == SurplusStatus.available && !item.isExpired)
        .toList();
  }

  // Get surplus items by donor (for donor dashboard)
  List<SurplusItem> getSurplusItemsByDonor(String donorName) {
    return _surplusItems
        .where((item) => item.donorName == donorName)
        .toList();
  }

  // Add new surplus item
  Future<bool> addSurplusItem({
    required String foodType,
    required int quantity,
    required DateTime expiryDate,
    required String donorName,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final newItem = SurplusItem(
        id: _generateId(),
        foodType: foodType,
        quantity: quantity,
        expiryDate: expiryDate,
        reportedDate: DateTime.now(),
        donorName: donorName,
        status: SurplusStatus.available,
      );

      _surplusItems.add(newItem);
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error adding surplus item: $e');
      return false;
    }
  }

  // Accept surplus item (NGO action)
  Future<bool> acceptSurplusItem(String itemId, String ngoName) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final itemIndex = _surplusItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        _surplusItems[itemIndex] = _surplusItems[itemIndex].copyWith(
          status: SurplusStatus.accepted,
        );
        _notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error accepting surplus item: $e');
      return false;
    }
  }

  // Mark item as collected
  Future<bool> markAsCollected(String itemId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final itemIndex = _surplusItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        _surplusItems[itemIndex] = _surplusItems[itemIndex].copyWith(
          status: SurplusStatus.collected,
        );
        _notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking item as collected: $e');
      return false;
    }
  }

  // Delete surplus item
  Future<bool> deleteSurplusItem(String itemId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _surplusItems.removeWhere((item) => item.id == itemId);
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting surplus item: $e');
      return false;
    }
  }

  // Listen to changes (simulating Firestore streams)
  void addListener(Function(List<SurplusItem>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(List<SurplusItem>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(List.unmodifiable(_surplusItems));
    }
  }

  // Helper methods
  String _generateId() {
    return 'surplus_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Get statistics for dashboard
  Map<String, int> getStatistics({String? donorName}) {
    List<SurplusItem> items = donorName != null 
        ? getSurplusItemsByDonor(donorName)
        : _surplusItems;

    return {
      'total': items.length,
      'available': items.where((item) => item.status == SurplusStatus.available).length,
      'accepted': items.where((item) => item.status == SurplusStatus.accepted).length,
      'collected': items.where((item) => item.status == SurplusStatus.collected).length,
      'expired': items.where((item) => item.isExpired).length,
    };
  }

  // Clear all data (for testing)
  void clearAllData() {
    _surplusItems.clear();
    _notifyListeners();
  }

  // Update expired items status
  void updateExpiredItems() {
    bool hasChanges = false;
    for (int i = 0; i < _surplusItems.length; i++) {
      if (_surplusItems[i].isExpired && 
          _surplusItems[i].status != SurplusStatus.expired &&
          _surplusItems[i].status != SurplusStatus.collected) {
        _surplusItems[i] = _surplusItems[i].copyWith(status: SurplusStatus.expired);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _notifyListeners();
    }
  }
}
