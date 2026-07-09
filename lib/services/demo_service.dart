import 'dart:math';
import '../models/surplus_item.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'local_surplus_service.dart';
import 'notification_service.dart';
import 'profile_service.dart';

class DemoService {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  final _surplusService = LocalSurplusService();
  final _notificationService = NotificationService();
  final _profileService = ProfileService();

  bool _isDemoMode = false;
  String _currentDemoScenario = 'default';

  // Demo scenarios
  static const Map<String, String> demoScenarios = {
    'default': 'Balanced mix of surplus items and notifications',
    'high_activity': 'High volume of surplus items and notifications',
    'donor_focused': 'Donor-centric view with multiple donations',
    'ngo_focused': 'NGO-centric view with many available items',
    'emergency': 'Emergency scenario with urgent surplus items',
    'success_story': 'Success story with completed donations',
  };

  bool get isDemoMode => _isDemoMode;
  String get currentScenario => _currentDemoScenario;

  /// Initialize demo mode with rich seed data
  Future<void> initializeDemoMode({String scenario = 'default'}) async {
    _isDemoMode = true;
    _currentDemoScenario = scenario;

    // Clear existing data
    _surplusService.clearAllData();
    _notificationService.clearAllNotifications();
    _profileService.resetProfile();

    // Load scenario-specific data
    await _loadScenarioData(scenario);

    print('🎭 Demo mode initialized with scenario: $scenario');
  }

  /// Exit demo mode and restore normal operation
  void exitDemoMode() {
    _isDemoMode = false;
    _currentDemoScenario = 'default';

    // Restore normal mock data
    _surplusService.initializeMockData();
    _notificationService.initializeMockData();
    _profileService.initializeMockProfile();

    print('🎭 Demo mode exited, restored to normal operation');
  }

  /// Load data based on demo scenario
  Future<void> _loadScenarioData(String scenario) async {
    switch (scenario) {
      case 'high_activity':
        await _loadHighActivityScenario();
        break;
      case 'donor_focused':
        await _loadDonorFocusedScenario();
        break;
      case 'ngo_focused':
        await _loadNGOFocusedScenario();
        break;
      case 'emergency':
        await _loadEmergencyScenario();
        break;
      case 'success_story':
        await _loadSuccessStoryScenario();
        break;
      default:
        await _loadDefaultScenario();
    }
  }

  Future<void> _loadDefaultScenario() async {
    // Create balanced demo profile
    await _profileService.createProfile(
      name: 'Demo User',
      email: 'demo@foodbridge.com',
      phone: '+1 (555) 123-DEMO',
      role: UserRole.donor,
      organization: 'FoodBridge Demo Restaurant',
      address: '123 Demo Street, Demo City, DC 12345',
      bio:
          'Passionate about reducing food waste and helping the community through FoodBridge.',
    );

    // Add diverse surplus items
    final demoItems = [
      {
        'foodType': 'Fresh Organic Vegetables',
        'quantity': 45,
        'expiryDays': 2,
        'donor': 'Green Valley Farm',
        'status': SurplusStatus.available,
      },
      {
        'foodType': 'Artisan Bread & Pastries',
        'quantity': 30,
        'expiryDays': 1,
        'donor': 'City Bakery',
        'status': SurplusStatus.accepted,
      },
      {
        'foodType': 'Premium Dairy Products',
        'quantity': 20,
        'expiryDays': 3,
        'donor': 'Mountain Dairy Co.',
        'status': SurplusStatus.available,
      },
      {
        'foodType': 'Gourmet Prepared Meals',
        'quantity': 15,
        'expiryDays': 1,
        'donor': 'Downtown Bistro',
        'status': SurplusStatus.collected,
      },
      {
        'foodType': 'Fresh Fruits & Berries',
        'quantity': 60,
        'expiryDays': 4,
        'donor': 'Orchard Fresh Market',
        'status': SurplusStatus.available,
      },
    ];

    for (final item in demoItems) {
      await _surplusService.addSurplusItem(
        foodType: item['foodType'] as String,
        quantity: item['quantity'] as int,
        expiryDate:
            DateTime.now().add(Duration(days: item['expiryDays'] as int)),
        donorName: item['donor'] as String,
      );
    }

    // Add demo notifications
    await _addDemoNotifications([
      {
        'type': NotificationType.surplusReported,
        'title': '🥬 New Organic Vegetables Available!',
        'message':
            'Green Valley Farm has donated 45kg of fresh organic vegetables. Perfect for your community kitchen!',
        'hoursAgo': 2,
      },
      {
        'type': NotificationType.surplusAccepted,
        'title': '✅ Your Bread Donation Accepted!',
        'message':
            'Community Food Bank has accepted your artisan bread donation. They\'ll pick it up within 2 hours.',
        'hoursAgo': 4,
      },
      {
        'type': NotificationType.general,
        'title': '🎉 Welcome to FoodBridge!',
        'message':
            'Thank you for joining our mission to reduce food waste and feed communities. Every donation makes a difference!',
        'hoursAgo': 24,
      },
    ]);
  }

  Future<void> _loadHighActivityScenario() async {
    await _profileService.createProfile(
      name: 'Busy Restaurant Manager',
      email: 'manager@busyrestaurant.com',
      phone: '+1 (555) 999-BUSY',
      role: UserRole.donor,
      organization: 'Metro Grill & Kitchen',
      bio:
          'Managing a high-volume restaurant and committed to zero food waste.',
    );

    // Generate many surplus items
    final foodTypes = [
      'Fresh Vegetables',
      'Bread & Bakery',
      'Dairy Products',
      'Prepared Meals',
      'Fruits',
      'Meat & Poultry',
      'Seafood',
      'Grains & Rice',
      'Canned Goods',
      'Frozen Items',
      'Beverages',
      'Desserts',
      'Salads',
      'Soups'
    ];

    final donors = [
      'Metro Grill',
      'City Supermarket',
      'Fresh Market',
      'Corner Deli',
      'Pizza Palace',
      'Healthy Cafe',
      'Family Restaurant',
      'Food Truck Co.'
    ];

    for (int i = 0; i < 25; i++) {
      await _surplusService.addSurplusItem(
        foodType: foodTypes[Random().nextInt(foodTypes.length)],
        quantity: Random().nextInt(50) + 10,
        expiryDate: DateTime.now().add(Duration(days: Random().nextInt(5) + 1)),
        donorName: donors[Random().nextInt(donors.length)],
      );
    }

    // Generate many notifications
    for (int i = 0; i < 15; i++) {
      await _notificationService.addNotification(
        AppNotification(
          id: 'demo_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: 'High Activity Notification ${i + 1}',
          message: 'This is a demo notification for high activity scenario.',
          type: NotificationType
              .values[Random().nextInt(NotificationType.values.length)],
          timestamp:
              DateTime.now().subtract(Duration(hours: Random().nextInt(48))),
        ),
      );
    }
  }

  Future<void> _loadDonorFocusedScenario() async {
    await _profileService.createProfile(
      name: 'Sarah Chen',
      email: 'sarah@greenbistro.com',
      phone: '+1 (555) 777-FOOD',
      role: UserRole.donor,
      organization: 'Green Bistro',
      address: '456 Eco Street, Green City, GC 54321',
      bio:
          'Award-winning chef and restaurant owner dedicated to sustainable practices and community support.',
    );

    // Focus on donor's perspective with their donations
    final donorItems = [
      'Organic Quinoa Salad',
      'Vegan Protein Bowls',
      'Fresh Herb Collection',
      'Artisan Sourdough',
      'Seasonal Vegetable Medley',
      'Plant-Based Desserts'
    ];

    for (final item in donorItems) {
      await _surplusService.addSurplusItem(
        foodType: item,
        quantity: Random().nextInt(30) + 15,
        expiryDate: DateTime.now().add(Duration(days: Random().nextInt(3) + 1)),
        donorName: 'Green Bistro',
      );
    }

    await _addDemoNotifications([
      {
        'type': NotificationType.surplusAccepted,
        'title': '🎉 Your Quinoa Salad Donation Accepted!',
        'message':
            'Helping Hands NGO has accepted your organic quinoa salad donation. Impact: 25 meals for families in need.',
        'hoursAgo': 1,
      },
      {
        'type': NotificationType.surplusCollected,
        'title': '✅ Donation Successfully Collected!',
        'message':
            'Your vegan protein bowls have been collected and are now feeding 20 community members. Thank you!',
        'hoursAgo': 6,
      },
    ]);
  }

  Future<void> _loadNGOFocusedScenario() async {
    await _profileService.createProfile(
      name: 'Michael Rodriguez',
      email: 'michael@communitykitchen.org',
      phone: '+1 (555) 444-HELP',
      role: UserRole.ngo,
      organization: 'Community Kitchen Network',
      address: '789 Service Ave, Helper City, HC 98765',
      bio:
          'Coordinating food rescue operations and community meal programs. Every rescued meal matters.',
    );

    // Many available items for NGO to choose from
    final availableItems = [
      'Restaurant Quality Meals',
      'Fresh Produce Mix',
      'Bakery Surplus',
      'Dairy & Eggs',
      'Frozen Prepared Foods',
      'Canned Goods Collection',
      'Fresh Meat & Poultry',
      'Seasonal Fruits',
      'Vegetarian Options'
    ];

    final donors = [
      'Premium Restaurant',
      'Gourmet Market',
      'Family Diner',
      'Cafe Corner',
      'Food Mart',
      'Organic Store',
      'Catering Company',
      'Hotel Kitchen'
    ];

    for (int i = 0; i < availableItems.length; i++) {
      await _surplusService.addSurplusItem(
        foodType: availableItems[i],
        quantity: Random().nextInt(40) + 20,
        expiryDate: DateTime.now().add(Duration(days: Random().nextInt(4) + 1)),
        donorName: donors[i % donors.length],
      );
    }

    await _addDemoNotifications([
      {
        'type': NotificationType.surplusReported,
        'title': '🍽️ Premium Meals Available!',
        'message':
            'High-end restaurant has 30 gourmet meals available. Perfect for your evening service!',
        'hoursAgo': 0.5,
      },
      {
        'type': NotificationType.surplusReported,
        'title': '🥖 Fresh Bakery Items Ready!',
        'message':
            'Local bakery has surplus bread, pastries, and desserts. Great for breakfast program!',
        'hoursAgo': 2,
      },
    ]);
  }

  Future<void> _loadEmergencyScenario() async {
    await _profileService.createProfile(
      name: 'Emergency Coordinator',
      email: 'emergency@foodbridge.com',
      phone: '+1 (555) 911-FOOD',
      role: UserRole.ngo,
      organization: 'Emergency Food Response',
      bio: 'Coordinating emergency food distribution during crisis situations.',
    );

    // Urgent surplus items
    final urgentItems = [
      'Emergency Food Kits',
      'Ready-to-Eat Meals',
      'Baby Formula & Food',
      'Medical Nutrition Drinks',
      'Non-Perishable Essentials',
      'Water & Beverages'
    ];

    for (final item in urgentItems) {
      await _surplusService.addSurplusItem(
        foodType: item,
        quantity: Random().nextInt(100) + 50,
        expiryDate:
            DateTime.now().add(Duration(hours: Random().nextInt(24) + 6)),
        donorName: 'Emergency Donor Network',
      );
    }

    await _addDemoNotifications([
      {
        'type': NotificationType.surplusReported,
        'title': '🚨 URGENT: Emergency Food Available!',
        'message':
            'Large quantity of emergency food kits available for immediate distribution. Contact donor ASAP!',
        'hoursAgo': 0.1,
        'priority': NotificationPriority.urgent,
      },
      {
        'type': NotificationType.general,
        'title': '⚡ Emergency Response Activated',
        'message':
            'Emergency food distribution network is now active. Priority given to urgent requests.',
        'hoursAgo': 1,
        'priority': NotificationPriority.high,
      },
    ]);
  }

  Future<void> _loadSuccessStoryScenario() async {
    await _profileService.createProfile(
      name: 'Community Champion',
      email: 'champion@foodbridge.com',
      phone: '+1 (555) 123-HERO',
      role: UserRole.donor,
      organization: 'Success Story Restaurant',
      bio:
          'Proud FoodBridge partner with 500+ successful donations and zero food waste achieved!',
    );

    // Mix of completed and ongoing donations
    final successItems = [
      {
        'food': 'Thanksgiving Feast Portions',
        'status': SurplusStatus.collected
      },
      {'food': 'Holiday Dessert Collection', 'status': SurplusStatus.collected},
      {'food': 'Community Celebration Meals', 'status': SurplusStatus.accepted},
      {'food': 'Fresh Seasonal Produce', 'status': SurplusStatus.available},
    ];

    for (final item in successItems) {
      await _surplusService.addSurplusItem(
        foodType: item['food'] as String,
        quantity: Random().nextInt(50) + 25,
        expiryDate: DateTime.now().add(Duration(days: Random().nextInt(3) + 1)),
        donorName: 'Success Story Restaurant',
      );
    }

    await _addDemoNotifications([
      {
        'type': NotificationType.surplusCollected,
        'title': '🎉 Milestone Achieved: 500th Donation!',
        'message':
            'Congratulations! Your 500th donation has been successfully collected. You\'ve helped feed 2,500+ people!',
        'hoursAgo': 2,
      },
      {
        'type': NotificationType.general,
        'title': '🏆 Community Impact Award',
        'message':
            'You\'ve been nominated for the Community Impact Award for your outstanding contribution to reducing food waste!',
        'hoursAgo': 24,
      },
    ]);
  }

  Future<void> _addDemoNotifications(
      List<Map<String, dynamic>> notifications) async {
    for (final notif in notifications) {
      await _notificationService.addNotification(
        AppNotification(
          id: 'demo_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
          title: notif['title'] as String,
          message: notif['message'] as String,
          type: notif['type'] as NotificationType,
          priority: notif['priority'] as NotificationPriority? ??
              NotificationPriority.medium,
          timestamp: DateTime.now().subtract(
            Duration(
              hours: ((notif['hoursAgo'] as num) * 60).toInt(),
            ),
          ),
        ),
      );
    }
  }

  /// Generate realistic demo activity
  Future<void> simulateLiveActivity() async {
    if (!_isDemoMode) return;

    // Simulate new surplus being reported
    final foodTypes = [
      'Fresh Salads',
      'Soup of the Day',
      'Dinner Specials',
      'Bakery Items'
    ];
    final donors = ['Live Demo Restaurant', 'Active Cafe', 'Busy Kitchen'];

    await _surplusService.addSurplusItem(
      foodType: foodTypes[Random().nextInt(foodTypes.length)],
      quantity: Random().nextInt(30) + 10,
      expiryDate: DateTime.now().add(Duration(hours: Random().nextInt(12) + 6)),
      donorName: donors[Random().nextInt(donors.length)],
    );

    // Send live notification
    await _notificationService.notifySurplusReported(
      donorName: donors[Random().nextInt(donors.length)],
      foodType: foodTypes[Random().nextInt(foodTypes.length)],
      quantity: Random().nextInt(30) + 10,
    );

    print('🎭 Live demo activity simulated');
  }

  /// Get demo statistics for presentation
  Map<String, dynamic> getDemoStatistics() {
    final surplusStats = _surplusService.getStatistics();
    final notificationStats = _notificationService.getStatistics();
    final profile = _profileService.getCurrentProfile();

    return {
      'isDemoMode': _isDemoMode,
      'scenario': _currentDemoScenario,
      'scenarioDescription': demoScenarios[_currentDemoScenario],
      'surplus': surplusStats,
      'notifications': notificationStats,
      'profile': {
        'name': profile?.name ?? 'No Profile',
        'role': profile?.roleDisplayName ?? 'Unknown',
        'organization': profile?.organization ?? 'N/A',
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Quick demo reset for presentations
  Future<void> quickReset() async {
    if (_isDemoMode) {
      await _loadScenarioData(_currentDemoScenario);
      print('🎭 Demo data reset for scenario: $_currentDemoScenario');
    }
  }
}
