import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_request_model.dart';
import '../services/notification_service.dart';

class FoodRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Collection name
  static const String collectionName = 'food_requests';

  // Stream all active requests
  Stream<List<FoodRequest>> streamActiveRequests() {
    return _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .orderBy('neededBy', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodRequest.fromDocument(doc))
            .where((req) => !req.isExpired)
            .toList());
  }

  // Stream requests by user
  Stream<List<FoodRequest>> streamRequestsByUser(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodRequest.fromDocument(doc))
            .toList());
  }

  // Create new request
  Future<FoodRequest> createRequest({
    required String userId,
    required String userName,
    required String organizationName,
    required String foodType,
    required String description,
    required int quantity,
    required String unit,
    required DateTime neededBy,
    String? location,
    bool isUrgent = false,
  }) async {
    final request = FoodRequest(
      id: _firestore.collection(collectionName).doc().id,
      userId: userId,
      userName: userName,
      organizationName: organizationName,
      foodType: foodType,
      description: description,
      quantity: quantity,
      unit: unit,
      neededBy: neededBy,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      location: location,
      isUrgent: isUrgent,
    );

    await _firestore
        .collection(collectionName)
        .doc(request.id)
        .set(request.toMap());

    // Notify donors about new request
    await _notificationService.notifyRequestCreated(
      requestTitle: foodType,
      requestedByNGO: organizationName,
      quantity: quantity,
      requestId: request.id,
    );

    return request;
  }

  // Fulfill a request (donor provides the food)
  Future<void> fulfillRequest({
    required String requestId,
    required String donorId,
    required String donorName,
  }) async {
    final requestDoc = await _firestore.collection(collectionName).doc(requestId).get();
    if (!requestDoc.exists) return;

    final request = FoodRequest.fromDocument(requestDoc);

    await _firestore.collection(collectionName).doc(requestId).update({
      'status': RequestStatus.fulfilled.name,
      'fulfilledByDonorId': donorId,
      'fulfilledByDonorName': donorName,
      'fulfilledAt': DateTime.now().toIso8601String(),
    });

    // Notify the NGO that their request is fulfilled
    await _notificationService.notifyRequestFulfilled(
      requestTitle: request.foodType,
      fulfilledByDonor: donorName,
      requestId: requestId,
    );
  }

  // Cancel a request
  Future<void> cancelRequest(String requestId) async {
    await _firestore.collection(collectionName).doc(requestId).update({
      'status': RequestStatus.cancelled.name,
    });
  }

  // Delete a request
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection(collectionName).doc(requestId).delete();
  }

  // Get single request
  Future<FoodRequest?> getRequest(String requestId) async {
    final doc = await _firestore.collection(collectionName).doc(requestId).get();
    if (doc.exists) {
      return FoodRequest.fromDocument(doc);
    }
    return null;
  }

  // Get requests by user (non-streaming)
  Future<List<FoodRequest>> getRequestsByUser(String userId) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => FoodRequest.fromDocument(doc)).toList();
  }

  // Get active requests (non-streaming)
  Future<List<FoodRequest>> getActiveRequests() async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .orderBy('neededBy', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => FoodRequest.fromDocument(doc))
        .where((req) => !req.isExpired)
        .toList();
  }

  // Expire old requests (should be called periodically)
  Future<void> expireOldRequests() async {
    final now = DateTime.now().toIso8601String();
    
    // Get all pending requests past their deadline
    final snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .where('neededBy', isLessThan: now)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'status': RequestStatus.expired.name,
      });
    }
  }

  // Search requests by food type
  Future<List<FoodRequest>> searchRequests(String query) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .get();

    final allRequests = snapshot.docs
        .map((doc) => FoodRequest.fromDocument(doc))
        .where((req) => !req.isExpired)
        .toList();

    if (query.isEmpty) return allRequests;

    final lowerQuery = query.toLowerCase();
    return allRequests.where((req) {
      return req.foodType.toLowerCase().contains(lowerQuery) ||
          req.description.toLowerCase().contains(lowerQuery) ||
          req.organizationName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get statistics for a user
  Future<Map<String, int>> getUserRequestStats(String userId) async {
    final requests = await getRequestsByUser(userId);
    
    return {
      'total': requests.length,
      'pending': requests.where((r) => r.status == RequestStatus.pending && !r.isExpired).length,
      'fulfilled': requests.where((r) => r.status == RequestStatus.fulfilled).length,
      'expired': requests.where((r) => r.status == RequestStatus.expired).length,
      'cancelled': requests.where((r) => r.status == RequestStatus.cancelled).length,
    };
  }
}