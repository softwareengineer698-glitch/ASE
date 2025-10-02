import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/local_surplus_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  _initializeServices();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully in main');

    // Give Firebase a moment to fully initialize
    await Future.delayed(const Duration(milliseconds: 100));
  } catch (e) {
    print('Firebase initialization error in main: $e');
  }

  runApp(const MyApp());
}

void _initializeServices() {
  // Initialize all singleton services
  NotificationService();
  ProfileService();
  LocalSurplusService();
  
  print('Services initialized successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set notification context for in-app notifications
    NotificationService().setContext(context);
    
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'FoodBridge',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
