import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/forecast_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/local_surplus_service.dart';
import 'services/donation_expiry_service.dart';
import 'services/volunteer_service.dart';
import 'providers/volunteer_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/request/request_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase FIRST before any services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    return;
  }

  // Initialize services AFTER Firebase is ready
  await _initializeServices();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
        Locale('ru'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  // Initialize all singleton services
  NotificationService();
  ProfileService();
  LocalSurplusService();
  VolunteerService();

  // Start the donation expiry service
  DonationExpiryService().start();

  // Initialize FCM (token registration + foreground/tap handlers).
  // Runs after Firebase is ready; silently ignored if user not yet signed in
  // (token is saved when user logs in via AuthProvider → AuthService).
  try {
    await NotificationService().initializeFCM();
  } catch (e) {
    debugPrint('FCM initialization skipped: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set notification context for in-app notifications
    NotificationService().setContext(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final themeProvider = ThemeProvider();
            themeProvider.initialize(); // Initialize theme preferences
            return themeProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final languageProvider = LanguageProvider();
            languageProvider.initialize(); // Initialize language preferences
            return languageProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ForecastProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => VolunteerProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final adminProvider = AdminProvider();
            adminProvider.initialize();
            return adminProvider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'FoodBridge',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: context.locale, // Use EasyLocalization's locale
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const SplashScreen(),
            routes: {
              '/requests': (context) => const RequestListScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
