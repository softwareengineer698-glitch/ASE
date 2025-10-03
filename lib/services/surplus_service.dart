import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/surplus_report_model.dart';

class SurplusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new surplus report
  Future<String> createSurplusReport(SurplusReportModel report) async {
    try {
      final docRef = await _firestore
          .collection('surplus_reports')
          .add(report.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create surplus report: $e';
    }
  }

  // Get surplus reports for a specific donor
  Stream<List<SurplusReportModel>> getDonorSurplusReports(String donorId) {
    return _firestore
        .collection('surplus_reports')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map((doc) => SurplusReportModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort on client side to avoid composite index requirement
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reports;
        });
  }

  // Get all available surplus reports (for NGOs)
  Stream<List<SurplusReportModel>> getAvailableSurplusReports() {
    return _firestore
        .collection('surplus_reports')
        .snapshots()
        .map((snapshot) {
          // Filter and sort on client side to avoid composite index requirement
          final availableReports = snapshot.docs
              .where((doc) => doc.data()['status'] == 'available')
              .map((doc) => SurplusReportModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by timestamp descending
          availableReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return availableReports;
        });
  }

  // Update surplus report status
  Future<void> updateSurplusStatus(String reportId, String status) async {
    try {
      await _firestore
          .collection('surplus_reports')
          .doc(reportId)
          .update({'status': status});
    } catch (e) {
      throw 'Failed to update surplus status: $e';
    }
  }

  // Get a specific surplus report
  Future<SurplusReportModel?> getSurplusReport(String reportId) async {
    try {
      final doc = await _firestore
          .collection('surplus_reports')
          .doc(reportId)
          .get();
      
      if (doc.exists) {
        return SurplusReportModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get surplus report: $e';
    }
  }

  // Delete surplus report
  Future<void> deleteSurplusReport(String reportId) async {
    try {
      await _firestore
          .collection('surplus_reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      throw 'Failed to delete surplus report: $e';
    }
  }
}
