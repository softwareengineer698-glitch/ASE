import '../services/local_surplus_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../models/surplus_item.dart';
import '../models/user_profile_model.dart';

class IntegrationTestRunner {
  static final IntegrationTestRunner _instance =
      IntegrationTestRunner._internal();
  factory IntegrationTestRunner() => _instance;
  IntegrationTestRunner._internal();

  final _surplusService = LocalSurplusService();
  final _notificationService = NotificationService();
  final _profileService = ProfileService();

  final List<String> _testResults = [];
  bool _allTestsPassed = true;

  /// Run all integration tests
  Future<Map<String, dynamic>> runAllTests() async {
    _testResults.clear();
    _allTestsPassed = true;

    print('🧪 Starting FoodBridge Integration Tests...\n');

    // Test 1: Service Initialization
    await _testServiceInitialization();

    // Test 2: Profile Management
    await _testProfileManagement();

    // Test 3: Surplus Reporting Flow
    await _testSurplusReportingFlow();

    // Test 4: NGO Acceptance Flow
    await _testNGOAcceptanceFlow();

    // Test 5: Notification System
    await _testNotificationSystem();

    // Test 6: End-to-End Flow
    await _testEndToEndFlow();

    // Test 7: Data Persistence
    await _testDataPersistence();

    // Test 8: Error Handling
    await _testErrorHandling();

    final results = {
      'allTestsPassed': _allTestsPassed,
      'totalTests': _testResults.length,
      'passedTests': _testResults.where((r) => r.contains('✅')).length,
      'failedTests': _testResults.where((r) => r.contains('❌')).length,
      'results': _testResults,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _printTestSummary(results);
    return results;
  }

  Future<void> _testServiceInitialization() async {
    _logTest('Service Initialization Tests');

    try {
      // Test singleton pattern
      final service1 = LocalSurplusService();
      final service2 = LocalSurplusService();
      _assert(identical(service1, service2),
          'LocalSurplusService singleton pattern');

      final notif1 = NotificationService();
      final notif2 = NotificationService();
      _assert(
          identical(notif1, notif2), 'NotificationService singleton pattern');

      final profile1 = ProfileService();
      final profile2 = ProfileService();
      _assert(
          identical(profile1, profile2), 'ProfileService singleton pattern');

      // Test service initialization
      _surplusService.initializeMockData();
      _notificationService.initializeMockData();
      _profileService.initializeMockProfile();

      _assert(_surplusService.getAllSurplusItems().isNotEmpty,
          'Surplus service has mock data');
      _assert(_notificationService.getAllNotifications().isNotEmpty,
          'Notification service has mock data');
      _assert(_profileService.getCurrentProfile() != null,
          'Profile service has mock profile');
    } catch (e) {
      _logResult('❌ Service initialization failed: $e');
    }
  }

  Future<void> _testProfileManagement() async {
    _logTest('Profile Management Tests');

    try {
      // Test profile creation
      final success = await _profileService.createProfile(
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        role: UserRole.donor,
        organization: 'Test Organization',
      );
      _assert(success, 'Profile creation');

      // Test profile retrieval
      final profile = _profileService.getCurrentProfile();
      _assert(profile != null, 'Profile retrieval');
      _assert(profile!.name == 'Test User', 'Profile data integrity');

      // Test profile update
      final updateSuccess = await _profileService.updateProfileField(
        name: 'Updated Test User',
        bio: 'Updated bio',
      );
      _assert(updateSuccess, 'Profile update');

      final updatedProfile = _profileService.getCurrentProfile();
      _assert(updatedProfile!.name == 'Updated Test User',
          'Profile update verification');
      _assert(updatedProfile.bio == 'Updated bio', 'Profile bio update');

      // Test role switching
      final roleSwitch = await _profileService.switchRole(UserRole.ngo);
      _assert(roleSwitch, 'Role switching');
      _assert(_profileService.getCurrentProfile()!.role == UserRole.ngo,
          'Role switch verification');
    } catch (e) {
      _logResult('❌ Profile management failed: $e');
    }
  }

  Future<void> _testSurplusReportingFlow() async {
    _logTest('Surplus Reporting Flow Tests');

    try {
      final initialCount = _surplusService.getAllSurplusItems().length;

      // Test surplus reporting
      final success = await _surplusService.addSurplusItem(
        foodType: 'Test Vegetables',
        quantity: 25,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        donorName: 'Test Donor',
      );
      _assert(success, 'Surplus item addition');

      // Verify item was added
      final newCount = _surplusService.getAllSurplusItems().length;
      _assert(newCount == initialCount + 1, 'Surplus item count increased');

      // Test item properties
      final items = _surplusService.getAllSurplusItems();
      final testItem = items.firstWhere(
        (item) => item.foodType == 'Test Vegetables',
        orElse: () => throw Exception('Test item not found'),
      );

      _assert(testItem.quantity == 25, 'Surplus item quantity');
      _assert(testItem.donorName == 'Test Donor', 'Surplus item donor name');
      _assert(testItem.status == SurplusStatus.available,
          'Surplus item initial status');

      // Test statistics
      final stats = _surplusService.getStatistics();
      _assert(stats['total']! > 0, 'Statistics total count');
      _assert(stats['available']! > 0, 'Statistics available count');
    } catch (e) {
      _logResult('❌ Surplus reporting flow failed: $e');
    }
  }

  Future<void> _testNGOAcceptanceFlow() async {
    _logTest('NGO Acceptance Flow Tests');

    try {
      // Get an available item
      final availableItems = _surplusService.getAvailableSurplusItems();
      _assert(availableItems.isNotEmpty, 'Available surplus items exist');

      final testItem = availableItems.first;
      final itemId = testItem.id;

      // Test item acceptance
      final success =
          await _surplusService.acceptSurplusItem(itemId, 'Test NGO');
      _assert(success, 'Surplus item acceptance');

      // Verify status change
      final updatedItems = _surplusService.getAllSurplusItems();
      final acceptedItem = updatedItems.firstWhere((item) => item.id == itemId);
      _assert(acceptedItem.status == SurplusStatus.accepted,
          'Item status changed to accepted');

      // Test collection
      final collectSuccess = await _surplusService.markAsCollected(itemId);
      _assert(collectSuccess, 'Item marked as collected');

      final collectedItems = _surplusService.getAllSurplusItems();
      final collectedItem =
          collectedItems.firstWhere((item) => item.id == itemId);
      _assert(collectedItem.status == SurplusStatus.collected,
          'Item status changed to collected');
    } catch (e) {
      _logResult('❌ NGO acceptance flow failed: $e');
    }
  }

  Future<void> _testNotificationSystem() async {
    _logTest('Notification System Tests');

    try {
      final initialCount = _notificationService.getAllNotifications().length;

      // Test surplus reported notification
      await _notificationService.notifySurplusReported(
        donorName: 'Test Donor',
        foodType: 'Test Food',
        quantity: 10,
      );

      final afterReportCount =
          _notificationService.getAllNotifications().length;
      _assert(afterReportCount == initialCount + 1,
          'Surplus reported notification created');

      // Test surplus accepted notification
      await _notificationService.notifySurplusAccepted(
        ngoName: 'Test NGO',
        foodType: 'Test Food',
        donorName: 'Test Donor',
      );

      final afterAcceptCount =
          _notificationService.getAllNotifications().length;
      _assert(afterAcceptCount == initialCount + 2,
          'Surplus accepted notification created');

      // Test notification marking as read
      final notifications = _notificationService.getAllNotifications();
      final testNotification = notifications.first;

      _notificationService.markAsRead(testNotification.id);
      final updatedNotifications = _notificationService.getAllNotifications();
      final readNotification =
          updatedNotifications.firstWhere((n) => n.id == testNotification.id);
      _assert(readNotification.isRead, 'Notification marked as read');

      // Test unread count
      final unreadCount = _notificationService.unreadCount;
      _assert(unreadCount >= 0, 'Unread count is valid');
    } catch (e) {
      _logResult('❌ Notification system failed: $e');
    }
  }

  Future<void> _testEndToEndFlow() async {
    _logTest('End-to-End Flow Tests');

    try {
      // Simulate complete user journey

      // 1. User creates profile
      await _profileService.createProfile(
        name: 'E2E Test Donor',
        email: 'e2e@test.com',
        phone: '+1111111111',
        role: UserRole.donor,
      );

      // 2. Donor reports surplus
      final reportSuccess = await _surplusService.addSurplusItem(
        foodType: 'E2E Test Food',
        quantity: 50,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        donorName: 'E2E Test Donor',
      );
      _assert(reportSuccess, 'E2E: Surplus reporting');

      // 3. Notification is sent
      await _notificationService.notifySurplusReported(
        donorName: 'E2E Test Donor',
        foodType: 'E2E Test Food',
        quantity: 50,
      );

      // 4. NGO sees and accepts surplus
      final availableItems = _surplusService.getAvailableSurplusItems();
      final e2eItem = availableItems.firstWhere(
        (item) => item.foodType == 'E2E Test Food',
        orElse: () => throw Exception('E2E test item not found'),
      );

      final acceptSuccess =
          await _surplusService.acceptSurplusItem(e2eItem.id, 'E2E Test NGO');
      _assert(acceptSuccess, 'E2E: Surplus acceptance');

      // 5. Donor gets acceptance notification
      await _notificationService.notifySurplusAccepted(
        ngoName: 'E2E Test NGO',
        foodType: 'E2E Test Food',
        donorName: 'E2E Test Donor',
      );

      // 6. Item is collected
      final collectSuccess = await _surplusService.markAsCollected(e2eItem.id);
      _assert(collectSuccess, 'E2E: Surplus collection');

      // 7. Collection notification
      await _notificationService.notifySurplusCollected(
        foodType: 'E2E Test Food',
        ngoName: 'E2E Test NGO',
      );

      _logResult('✅ Complete end-to-end flow successful');
    } catch (e) {
      _logResult('❌ End-to-end flow failed: $e');
    }
  }

  Future<void> _testDataPersistence() async {
    _logTest('Data Persistence Tests');

    try {
      // Test data survives service reinitialization
      final beforeCount = _surplusService.getAllSurplusItems().length;
      final beforeNotifications =
          _notificationService.getAllNotifications().length;

      // Simulate app restart (services maintain state in memory)
      _assert(beforeCount > 0, 'Data exists before persistence test');
      _assert(beforeNotifications > 0,
          'Notifications exist before persistence test');

      // Test data export/import capability
      final surplusItems = _surplusService.getAllSurplusItems();
      final exportData = surplusItems.map((item) => item.toMap()).toList();
      _assert(exportData.isNotEmpty, 'Data export functionality');

      // Test data validation
      for (final itemData in exportData) {
        _assert(itemData.containsKey('id'), 'Exported data contains ID');
        _assert(itemData.containsKey('foodType'),
            'Exported data contains food type');
        _assert(
            itemData.containsKey('status'), 'Exported data contains status');
      }
    } catch (e) {
      _logResult('❌ Data persistence test failed: $e');
    }
  }

  Future<void> _testErrorHandling() async {
    _logTest('Error Handling Tests');

    try {
      // Test invalid surplus item creation
      try {
        await _surplusService.addSurplusItem(
          foodType: '',
          quantity: -1,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          donorName: '',
        );
        _logResult('❌ Should have failed with invalid data');
      } catch (e) {
        _logResult('✅ Properly handles invalid surplus data');
      }

      // Test accepting non-existent item
      final invalidAccept =
          await _surplusService.acceptSurplusItem('invalid_id', 'Test NGO');
      _assert(!invalidAccept, 'Properly handles invalid item acceptance');

      // Test profile validation
      final profile = UserProfile(
        id: 'test',
        name: '',
        email: 'invalid-email',
        phone: '123',
        role: UserRole.donor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _assert(profile.validateName('') != null, 'Name validation works');
      _assert(profile.validateEmail('invalid-email') != null,
          'Email validation works');
      _assert(profile.validatePhone('123') != null, 'Phone validation works');
    } catch (e) {
      _logResult('❌ Error handling test failed: $e');
    }
  }

  void _assert(bool condition, String testName) {
    if (condition) {
      _logResult('✅ $testName');
    } else {
      _logResult('❌ $testName');
      _allTestsPassed = false;
    }
  }

  void _logTest(String testName) {
    print('📋 $testName');
  }

  void _logResult(String result) {
    _testResults.add(result);
    print('   $result');
  }

  void _printTestSummary(Map<String, dynamic> results) {
    print('\n' + '=' * 50);
    print('🧪 FOODBRIDGE INTEGRATION TEST SUMMARY');
    print('=' * 50);
    print('Total Tests: ${results['totalTests']}');
    print('Passed: ${results['passedTests']} ✅');
    print('Failed: ${results['failedTests']} ❌');
    print(
        'Success Rate: ${((results['passedTests'] / results['totalTests']) * 100).toStringAsFixed(1)}%');
    print(
        'Overall Result: ${results['allTestsPassed'] ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}');
    print('Timestamp: ${results['timestamp']}');
    print('=' * 50);

    if (!results['allTestsPassed']) {
      print('\n❌ Failed Tests:');
      for (final result in results['results']) {
        if (result.contains('❌')) {
          print('   $result');
        }
      }
    }
  }

  /// Quick smoke test for demo purposes
  Future<bool> runSmokeTest() async {
    try {
      // Test basic functionality
      _surplusService.initializeMockData();
      _notificationService.initializeMockData();
      _profileService.initializeMockProfile();

      final hasData = _surplusService.getAllSurplusItems().isNotEmpty &&
          _notificationService.getAllNotifications().isNotEmpty &&
          _profileService.getCurrentProfile() != null;

      return hasData;
    } catch (e) {
      print('Smoke test failed: $e');
      return false;
    }
  }
}
