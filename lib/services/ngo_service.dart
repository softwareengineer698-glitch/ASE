import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_request_model.dart';
import '../models/surplus_report_model.dart';

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
    try {
      print('NGO Service: Querying requests for NGO: $ngoId');
      return _firestore
          .collection('ngo_requests')
          .where('ngoId', isEqualTo: ngoId)
          .snapshots()
          .map((snapshot) {
            print('NGO Service: Received ${snapshot.docs.length} request documents');
            final requests = <NGORequestModel>[];
            
            for (var doc in snapshot.docs) {
              try {
                final request = NGORequestModel.fromMap(doc.data(), doc.id);
                requests.add(request);
                print('NGO Service: Parsed request ${request.id} with status ${request.status}');
              } catch (e) {
                print('NGO Service: Error parsing request document ${doc.id}: $e');
              }
            }
            
            // Sort on client side to avoid composite index requirement
            requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            print('NGO Service: Returning ${requests.length} sorted requests');
            return requests;
          });
    } catch (e) {
      print('NGO Service: Error in getNGORequests: $e');
      throw 'Failed to get NGO requests: $e';
    }
  }

  // Get requests for a specific surplus (for donors to see who requested)
  Stream<List<NGORequestModel>> getRequestsForSurplus(String surplusId) {
    return _firestore
        .collection('ngo_requests')
        .where('surplusId', isEqualTo: surplusId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => NGORequestModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort on client side to avoid composite index requirement
          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
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

  // Get accepted donations for a specific NGO
  Stream<List<NGORequestModel>> getAcceptedDonations(String ngoId) {
    return _firestore
        .collection('ngo_requests')
        .where('ngoId', isEqualTo: ngoId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => NGORequestModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by timestamp descending (most recent first)
          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
  }

  // Get all donations with surplus details for a specific NGO (for filtering in UI)
  Stream<List<Map<String, dynamic>>> getAcceptedDonationsWithDetails(String ngoId) {
    try {
      print('NGO Service: Getting donations for NGO ID: $ngoId');
      return getNGORequests(ngoId).asyncMap((requests) async {
        print('NGO Service: Found ${requests.length} requests');
        List<Map<String, dynamic>> donationsWithDetails = [];
        
        for (NGORequestModel request in requests) {
          try {
            print('NGO Service: Processing request ${request.id} for surplus ${request.surplusId}');
            
            // Get surplus details for each request
            final surplusDoc = await _firestore
                .collection('surplus_reports')
                .doc(request.surplusId)
                .get();
            
            if (surplusDoc.exists && surplusDoc.data() != null) {
              final surplusData = SurplusReportModel.fromMap(surplusDoc.data()!, surplusDoc.id);
              print('NGO Service: Found surplus data for ${request.surplusId}');
              
              // Get donor details
              final donorDoc = await _firestore
                  .collection('users')
                  .doc(surplusData.donorId)
                  .get();
              
              String donorEmail = 'Unknown Donor';
              if (donorDoc.exists && donorDoc.data() != null) {
                donorEmail = donorDoc.data()?['email'] ?? 'Unknown Donor';
                print('NGO Service: Found donor email: $donorEmail');
              } else {
                print('NGO Service: Donor document not found for ${surplusData.donorId}');
              }
              
              donationsWithDetails.add({
                'request': request,
                'surplus': surplusData,
                'donorEmail': donorEmail,
              });
            } else {
              // Handle case where surplus document doesn't exist or is null
              print('Warning: Surplus document ${request.surplusId} not found or is null');
              donationsWithDetails.add({
                'request': request,
                'surplus': null,
                'donorEmail': 'Unknown Donor',
                'error': 'Surplus data not found',
              });
            }
          } catch (e) {
            print('Error fetching details for request ${request.id}: $e');
            // Add request without surplus details if there's an error
            donationsWithDetails.add({
              'request': request,
              'surplus': null,
              'donorEmail': 'Unknown Donor',
              'error': e.toString(),
            });
          }
        }
        
        print('NGO Service: Returning ${donationsWithDetails.length} donations with details');
        return donationsWithDetails;
      });
    } catch (e) {
      print('NGO Service: Critical error in getAcceptedDonationsWithDetails: $e');
      throw 'Failed to get donations with details: $e';
    }
  }

  // Mark donation as collected/completed
  Future<void> markDonationAsCollected(String requestId, String surplusId) async {
    try {
      // Update NGO request status to completed
      await _firestore
          .collection('ngo_requests')
          .doc(requestId)
          .update({'status': 'completed'});
      
      // Update surplus status to completed
      await _firestore
          .collection('surplus_reports')
          .doc(surplusId)
          .update({'status': 'completed'});
    } catch (e) {
      throw 'Failed to mark donation as collected: $e';
    }
  }

  // Get donation statistics for NGO
  Future<Map<String, int>> getDonationStatistics(String ngoId) async {
    try {
      final snapshot = await _firestore
          .collection('ngo_requests')
          .where('ngoId', isEqualTo: ngoId)
          .get();
      
      int totalRequests = snapshot.docs.length;
      int acceptedRequests = 0;
      int completedRequests = 0;
      int pendingRequests = 0;
      
      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'accepted':
            acceptedRequests++;
            break;
          case 'completed':
            completedRequests++;
            break;
          case 'pending':
            pendingRequests++;
            break;
        }
      }
      
      return {
        'total': totalRequests,
        'accepted': acceptedRequests,
        'completed': completedRequests,
        'pending': pendingRequests,
      };
    } catch (e) {
      throw 'Failed to get donation statistics: $e';
    }
  }
}
