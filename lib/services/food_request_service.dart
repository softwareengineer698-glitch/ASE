import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/food_request_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class FoodRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection name
  static const String collectionName = 'food_requests';

  List<FoodRequest> _sortActiveRequests(Iterable<FoodRequest> requests) {
    final sorted = requests.where((req) => !req.isExpired).toList();
    sorted.sort((a, b) => a.neededBy.compareTo(b.neededBy));
    return sorted;
  }

  List<FoodRequest> _sortUserRequests(Iterable<FoodRequest> requests) {
    final sorted = requests.toList();
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // Stream all active requests
  Stream<List<FoodRequest>> streamActiveRequests() {
    return _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .snapshots()
        .map((snapshot) =>
            _sortActiveRequests(snapshot.docs.map(FoodRequest.fromDocument)));
  }

  // Stream requests by user
  Stream<List<FoodRequest>> streamRequestsByUser(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            _sortUserRequests(snapshot.docs.map(FoodRequest.fromDocument)));
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

    // Notify all other users about the new food request
    await _broadcastNewRequestNotification(request);

    return request;
  }

  /// Push a Firestore notification to every user except the requester,
  /// so they see the new food request in their notification centre.
  Future<void> _broadcastNewRequestNotification(FoodRequest request) async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final notifId =
          'req_created_${request.id}_${DateTime.now().millisecondsSinceEpoch}';
      for (final userDoc in usersSnap.docs) {
        if (userDoc.id == request.userId) continue; // skip the requester
        await _notificationService.createRemoteNotificationForUser(
          userId: userDoc.id,
          notification: AppNotification(
            id: '${notifId}_${userDoc.id}',
            title: '🍽️ New Food Request',
            message:
                '${request.organizationName} needs ${request.quantity} ${request.unit} of ${request.foodType}.',
            type: NotificationType.requestCreated,
            priority: request.isUrgent
                ? NotificationPriority.urgent
                : NotificationPriority.medium,
            timestamp: DateTime.now(),
            actionData: 'request_${request.id}',
            relatedRequestId: request.id,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to broadcast request notification: $e');
    }
  }

  // Fulfill a request (donor provides the food)
  Future<void> fulfillRequest({
    required String requestId,
    required String donorId,
    required String donorName,
  }) async {
    final requestDoc =
        await _firestore.collection(collectionName).doc(requestId).get();
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
    final doc =
        await _firestore.collection(collectionName).doc(requestId).get();
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
        .get();

    return _sortUserRequests(snapshot.docs.map(FoodRequest.fromDocument));
  }

  // Get active requests (non-streaming)
  Future<List<FoodRequest>> getActiveRequests() async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .get();

    return _sortActiveRequests(snapshot.docs.map(FoodRequest.fromDocument));
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
      'pending': requests
          .where((r) => r.status == RequestStatus.pending && !r.isExpired)
          .length,
      'fulfilled':
          requests.where((r) => r.status == RequestStatus.fulfilled).length,
      'expired':
          requests.where((r) => r.status == RequestStatus.expired).length,
      'cancelled':
          requests.where((r) => r.status == RequestStatus.cancelled).length,
    };
  }
}
