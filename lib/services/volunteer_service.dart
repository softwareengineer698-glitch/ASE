import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';
import '../models/delivery_model.dart';

class VolunteerService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Create or update volunteer profile
  Future<void> updateVolunteerProfile(VolunteerModel volunteer) async {
    await _firestore.collection('volunteers').doc(volunteer.userId).set(
          volunteer.toMap(),
          SetOptions(merge: true),
        );
  }

  // Get volunteer profile
  Future<VolunteerModel?> getVolunteerProfile(String userId) async {
    final doc = await _firestore.collection('volunteers').doc(userId).get();
    if (doc.exists) {
      return VolunteerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Stream of volunteer profile
  Stream<VolunteerModel?> streamVolunteerProfile(String userId) {
    return _firestore
        .collection('volunteers')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return VolunteerModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update volunteer status
  Future<void> updateStatus(String userId, VolunteerStatus status) async {
    await _firestore.collection('volunteers').doc(userId).update({
      'status': status.name,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Update volunteer location
  Future<void> updateLocation(String userId, double lat, double lng) async {
    await _firestore.collection('volunteers').doc(userId).update({
      'latitude': lat,
      'longitude': lng,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Get available volunteers nearby
  Future<List<VolunteerModel>> getAvailableVolunteers() async {
    final snapshot = await _firestore
        .collection('volunteers')
        .where('status', isEqualTo: VolunteerStatus.available.name)
        .where('isVerified', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => VolunteerModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get assigned deliveries
  Stream<List<DeliveryModel>> streamAssignedDeliveries(String volunteerId) {
    return _firestore
        .collection('deliveries')
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', whereIn: ['pending', 'picked_up', 'in_transit'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update delivery status
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'status': status,
      if (status == 'picked_up') 'pickedUpAt': FieldValue.serverTimestamp(),
      if (status == 'delivered') 'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream available delivery tasks (those without an assigned volunteer)
  Stream<List<DeliveryModel>> streamAvailableTasks() {
    return _firestore
        .collection('deliveries')
        .where('volunteerId', isEqualTo: '')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Claim a delivery task
  Future<void> claimDelivery(String deliveryId, String volunteerId) async {
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'volunteerId': volunteerId,
      'status': 'pending', // Re-confirming pending status upon assignment
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream deliveries for a specific NGO
  Stream<List<DeliveryModel>> streamNGODeliveries(String ngoId) {
    return _firestore
        .collection('deliveries')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream deliveries for a specific Donor
  Stream<List<DeliveryModel>> streamDonorDeliveries(String donorId) {
    return _firestore
        .collection('deliveries')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
