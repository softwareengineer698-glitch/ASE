import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/delivery_confirmation_model.dart';

/// Service for managing delivery confirmations with photo uploads and signatures
/// Handles the complete delivery verification workflow
class DeliveryConfirmationService extends ChangeNotifier {
  // Singleton pattern
  static final DeliveryConfirmationService _instance = DeliveryConfirmationService._internal();
  factory DeliveryConfirmationService() => _instance;
  DeliveryConfirmationService._internal();

  // Storage
  final List<DeliveryConfirmation> _deliveries = [];

  // Getters
  List<DeliveryConfirmation> get allDeliveries => List.unmodifiable(_deliveries);
  List<DeliveryConfirmation> get pendingDeliveries => 
    _deliveries.where((d) => d.status == DeliveryStatus.pending).toList();
  List<DeliveryConfirmation> get completedDeliveries => 
    _deliveries.where((d) => d.status == DeliveryStatus.completed || d.status == DeliveryStatus.confirmed).toList();

  /// Initialize service with mock data
  Future<void> initialize() async {
    await _generateMockDeliveries();
    notifyListeners();
  }

  /// Generate mock delivery confirmations for demo
  Future<void> _generateMockDeliveries() async {
    final now = DateTime.now();
    
    _deliveries.addAll([
      DeliveryConfirmation(
        id: _generateId(),
        donationId: 'donation_001',
        donorId: 'donor_001',
        ngoId: 'ngo_001',
        donorName: 'Green Grocery Store',
        ngoName: 'Hope Foundation',
        deliveryDate: now.subtract(const Duration(hours: 2)),
        status: DeliveryStatus.completed,
        photos: [
          DeliveryPhoto(
            id: _generateId(),
            filePath: '/mock/delivery_photo_1.jpg',
            firebaseUrl: 'https://example.com/photo1.jpg',
            type: PhotoType.delivery,
            capturedAt: now.subtract(const Duration(hours: 2)),
            caption: 'Fresh vegetables delivered',
            latitude: 24.8607,
            longitude: 67.0011,
          ),
          DeliveryPhoto(
            id: _generateId(),
            filePath: '/mock/food_photo_1.jpg',
            type: PhotoType.food,
            capturedAt: now.subtract(const Duration(hours: 2)),
            caption: 'Quality food items',
          ),
        ],
        donorSignature: DeliverySignature(
          id: _generateId(),
          signatureData: _generateMockSignature(),
          signerName: 'Ahmed Khan',
          signerRole: 'donor',
          signedAt: now.subtract(const Duration(hours: 1, minutes: 30)),
          signerEmail: 'ahmed@greengrocery.com',
        ),
        ngoSignature: DeliverySignature(
          id: _generateId(),
          signatureData: _generateMockSignature(),
          signerName: 'Fatima Ali',
          signerRole: 'ngo',
          signedAt: now.subtract(const Duration(hours: 1)),
          signerEmail: 'fatima@hopefoundation.org',
        ),
        notes: 'Delivery completed successfully. All items in excellent condition.',
        quantityDelivered: 25.5,
        foodCategory: 'Vegetables',
        createdAt: now.subtract(const Duration(hours: 3)),
        confirmedAt: now.subtract(const Duration(hours: 1)),
      ),
      
      DeliveryConfirmation(
        id: _generateId(),
        donationId: 'donation_002',
        donorId: 'donor_002',
        ngoId: 'ngo_002',
        donorName: 'City Bakery',
        ngoName: 'Care Center',
        deliveryDate: now.subtract(const Duration(minutes: 30)),
        status: DeliveryStatus.inProgress,
        photos: [
          DeliveryPhoto(
            id: _generateId(),
            filePath: '/mock/bakery_delivery.jpg',
            type: PhotoType.delivery,
            capturedAt: now.subtract(const Duration(minutes: 30)),
            caption: 'Fresh bread and pastries',
          ),
        ],
        ngoSignature: DeliverySignature(
          id: _generateId(),
          signatureData: _generateMockSignature(),
          signerName: 'Omar Hassan',
          signerRole: 'ngo',
          signedAt: now.subtract(const Duration(minutes: 20)),
          signerEmail: 'omar@carecenter.org',
        ),
        notes: 'Awaiting donor signature for completion.',
        quantityDelivered: 15.0,
        foodCategory: 'Bakery Items',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),

      DeliveryConfirmation(
        id: _generateId(),
        donationId: 'donation_003',
        donorId: 'donor_003',
        ngoId: 'ngo_003',
        donorName: 'Fresh Market',
        ngoName: 'Community Kitchen',
        deliveryDate: now.add(const Duration(hours: 2)),
        status: DeliveryStatus.pending,
        photos: [],
        notes: 'Scheduled for delivery this afternoon.',
        quantityDelivered: 40.0,
        foodCategory: 'Mixed Items',
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
    ]);
  }

  /// Create new delivery confirmation
  Future<DeliveryConfirmation> createDeliveryConfirmation({
    required String donationId,
    required String donorId,
    required String ngoId,
    required String donorName,
    required String ngoName,
    required DateTime deliveryDate,
    required double quantityDelivered,
    required String foodCategory,
    String? notes,
  }) async {
    final delivery = DeliveryConfirmation(
      id: _generateId(),
      donationId: donationId,
      donorId: donorId,
      ngoId: ngoId,
      donorName: donorName,
      ngoName: ngoName,
      deliveryDate: deliveryDate,
      status: DeliveryStatus.pending,
      photos: [],
      notes: notes,
      quantityDelivered: quantityDelivered,
      foodCategory: foodCategory,
      createdAt: DateTime.now(),
    );

    _deliveries.insert(0, delivery);
    notifyListeners();

    return delivery;
  }

  /// Add photo to delivery confirmation
  Future<void> addPhoto({
    required String deliveryId,
    required String filePath,
    required PhotoType type,
    String? caption,
    double? latitude,
    double? longitude,
  }) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final photo = DeliveryPhoto(
      id: _generateId(),
      filePath: filePath,
      firebaseUrl: await _uploadPhoto(filePath), // Simulate upload
      type: type,
      capturedAt: DateTime.now(),
      caption: caption,
      latitude: latitude,
      longitude: longitude,
    );

    final updatedPhotos = List<DeliveryPhoto>.from(_deliveries[index].photos);
    updatedPhotos.add(photo);

    _deliveries[index] = _deliveries[index].copyWith(photos: updatedPhotos);
    notifyListeners();
  }

  /// Remove photo from delivery confirmation
  Future<void> removePhoto(String deliveryId, String photoId) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final updatedPhotos = _deliveries[index].photos
        .where((photo) => photo.id != photoId)
        .toList();

    _deliveries[index] = _deliveries[index].copyWith(photos: updatedPhotos);
    notifyListeners();
  }

  /// Add signature to delivery confirmation
  Future<void> addSignature({
    required String deliveryId,
    required String signatureData,
    required String signerName,
    required String signerRole,
    String? signerEmail,
  }) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final signature = DeliverySignature(
      id: _generateId(),
      signatureData: signatureData,
      signerName: signerName,
      signerRole: signerRole,
      signedAt: DateTime.now(),
      signerEmail: signerEmail,
    );

    DeliveryConfirmation updatedDelivery;
    if (signerRole == 'donor') {
      updatedDelivery = _deliveries[index].copyWith(donorSignature: signature);
    } else {
      updatedDelivery = _deliveries[index].copyWith(ngoSignature: signature);
    }

    // Update status if both signatures are present
    if (updatedDelivery.donorSignature != null && updatedDelivery.ngoSignature != null) {
      updatedDelivery = updatedDelivery.copyWith(status: DeliveryStatus.completed);
    } else {
      updatedDelivery = updatedDelivery.copyWith(status: DeliveryStatus.inProgress);
    }

    _deliveries[index] = updatedDelivery;
    notifyListeners();
  }

  /// Update delivery notes
  Future<void> updateNotes(String deliveryId, String notes) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    _deliveries[index] = _deliveries[index].copyWith(notes: notes);
    notifyListeners();
  }

  /// Confirm delivery (final step)
  Future<void> confirmDelivery(String deliveryId) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    final delivery = _deliveries[index];
    if (!delivery.isComplete) {
      throw Exception('Delivery is not complete. Missing photos or signatures.');
    }

    _deliveries[index] = delivery.copyWith(
      status: DeliveryStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Reject delivery with reason
  Future<void> rejectDelivery(String deliveryId, String reason) async {
    final index = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (index == -1) throw Exception('Delivery not found');

    _deliveries[index] = _deliveries[index].copyWith(
      status: DeliveryStatus.rejected,
      rejectionReason: reason,
    );
    notifyListeners();
  }

  /// Get deliveries by user ID and role
  List<DeliveryConfirmation> getDeliveriesByUser(String userId, String role) {
    if (role == 'donor') {
      return _deliveries.where((d) => d.donorId == userId).toList();
    } else {
      return _deliveries.where((d) => d.ngoId == userId).toList();
    }
  }

  /// Get delivery by ID
  DeliveryConfirmation? getDeliveryById(String deliveryId) {
    try {
      return _deliveries.firstWhere((d) => d.id == deliveryId);
    } catch (e) {
      return null;
    }
  }

  /// Get delivery statistics
  Map<String, dynamic> getDeliveryStats() {
    final total = _deliveries.length;
    final pending = _deliveries.where((d) => d.status == DeliveryStatus.pending).length;
    final inProgress = _deliveries.where((d) => d.status == DeliveryStatus.inProgress).length;
    final completed = _deliveries.where((d) => d.status == DeliveryStatus.completed).length;
    final confirmed = _deliveries.where((d) => d.status == DeliveryStatus.confirmed).length;
    final rejected = _deliveries.where((d) => d.status == DeliveryStatus.rejected).length;

    final totalQuantity = _deliveries.fold<double>(0, (sum, d) => sum + d.quantityDelivered);
    final avgDeliveryTime = _calculateAverageDeliveryTime();

    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'confirmed': confirmed,
      'rejected': rejected,
      'totalQuantity': totalQuantity,
      'averageDeliveryTime': avgDeliveryTime,
    };
  }

  /// Check if delivery template requirements are met
  bool checkTemplateRequirements(String deliveryId, String templateId) {
    final delivery = getDeliveryById(deliveryId);
    final template = DeliveryTemplate.templates[templateId];
    
    if (delivery == null || template == null) return false;

    // Check required photos
    for (final requiredType in template.requiredPhotos) {
      if (!delivery.photos.any((photo) => photo.type == requiredType)) {
        return false;
      }
    }

    // Check signatures
    if (template.requiresDonorSignature && delivery.donorSignature == null) {
      return false;
    }
    if (template.requiresNgoSignature && delivery.ngoSignature == null) {
      return false;
    }

    return true;
  }

  /// Simulate photo upload to Firebase Storage
  Future<String> _uploadPhoto(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate upload
    return 'https://firebasestorage.googleapis.com/mock/${_generateId()}.jpg';
  }

  /// Generate mock signature data
  String _generateMockSignature() {
    // In real app, this would be actual signature data
    return base64Encode('mock_signature_${_generateId()}'.codeUnits);
  }

  /// Calculate average delivery time
  double _calculateAverageDeliveryTime() {
    final completedDeliveries = _deliveries.where((d) => 
      d.status == DeliveryStatus.completed || d.status == DeliveryStatus.confirmed).toList();
    
    if (completedDeliveries.isEmpty) return 0.0;

    final totalHours = completedDeliveries.fold<double>(0, (sum, delivery) {
      if (delivery.confirmedAt != null) {
        return sum + delivery.confirmedAt!.difference(delivery.createdAt).inHours;
      }
      return sum;
    });

    return totalHours / completedDeliveries.length;
  }

  /// Generate unique ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Search deliveries
  List<DeliveryConfirmation> searchDeliveries(String query) {
    final lowerQuery = query.toLowerCase();
    return _deliveries.where((delivery) =>
      delivery.donorName.toLowerCase().contains(lowerQuery) ||
      delivery.ngoName.toLowerCase().contains(lowerQuery) ||
      delivery.foodCategory.toLowerCase().contains(lowerQuery) ||
      delivery.notes?.toLowerCase().contains(lowerQuery) == true
    ).toList();
  }

  /// Export delivery data (for reporting)
  Map<String, dynamic> exportDeliveryData(String deliveryId) {
    final delivery = getDeliveryById(deliveryId);
    if (delivery == null) throw Exception('Delivery not found');

    return {
      'delivery': delivery.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'exportedBy': 'system',
    };
  }
}
