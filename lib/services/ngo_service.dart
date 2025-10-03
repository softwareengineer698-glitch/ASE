import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_request_model.dart';

class NGOService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new NGO request (when accepting surplus)
  Future<String> createNGORequest(NGORequestModel request) async {
    try {
      final docRef = await _firestore
          .collection('ngo_requests')
          .add(request.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create NGO request: $e';
    }
  }

  // Get NGO requests for a specific NGO
  Stream<List<NGORequestModel>> getNGORequests(String ngoId) {
    return _firestore
        .collection('ngo_requests')
        .where('ngoId', isEqualTo: ngoId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NGORequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get requests for a specific surplus (for donors to see who requested)
  Stream<List<NGORequestModel>> getRequestsForSurplus(String surplusId) {
    return _firestore
        .collection('ngo_requests')
        .where('surplusId', isEqualTo: surplusId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NGORequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update NGO request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('ngo_requests')
          .doc(requestId)
          .update({'status': status});
    } catch (e) {
      throw 'Failed to update request status: $e';
    }
  }

  // Accept a surplus (create request and update surplus status)
  Future<String> acceptSurplus(String ngoId, String surplusId, {String? message}) async {
    try {
      // Create NGO request
      final request = NGORequestModel(
        id: '', // Will be set by Firestore
        ngoId: ngoId,
        surplusId: surplusId,
        status: 'accepted',
        timestamp: DateTime.now(),
        message: message,
      );

      final requestId = await createNGORequest(request);

      // Update surplus status to 'requested'
      await _firestore
          .collection('surplus_reports')
          .doc(surplusId)
          .update({'status': 'requested'});

      return requestId;
    } catch (e) {
      throw 'Failed to accept surplus: $e';
    }
  }

  // Get a specific NGO request
  Future<NGORequestModel?> getNGORequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection('ngo_requests')
          .doc(requestId)
          .get();
      
      if (doc.exists) {
        return NGORequestModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get NGO request: $e';
    }
  }
}
