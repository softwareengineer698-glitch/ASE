import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'screens/chat/chat_rooms_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- EasyLocalization ---
  try {
    await EasyLocalization.ensureInitialized();
    // Always force Roman Urdu unless user has explicitly chosen another lang
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale');
    // Override 'en' (old default) with Roman Urdu. Respect user's own choices.
    if (saved == null || saved == 'en') {
      await prefs.setString('locale', 'ur_PK');
    }
  } catch (e) {
    debugPrint('EasyLocalization init error: $e');
  }

  // --- Firebase ---
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // --- Services (fire-and-forget, never block UI) ---
  _initializeServicesInBackground();

  // --- Launch the app (MUST always execute) ---
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ur', 'PK'), // Roman Urdu — default
        Locale('en'),
        Locale('ur'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('ur', 'PK'),
      useOnlyLangCode: false,
      child: const MyApp(),
    ),
  );
}

/// Initialize services in the background. Each service is individually
/// wrapped so a failure in one doesn't block the others. Nothing here
/// returns a Future that is awaited.
void _initializeServicesInBackground() {
  try {
    NotificationService();
  } catch (_) {}
  try {
    ProfileService();
  } catch (_) {}
  try {
    LocalSurplusService();
  } catch (_) {}
  try {
    VolunteerService();
  } catch (_) {}
  try {
    DonationExpiryService().start();
  } catch (_) {}

  // FCM is completely fire-and-forget
  Future.microtask(() async {
    try {
      await NotificationService().initializeFCM();
    } catch (e) {
      debugPrint('FCM initialization skipped: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final t = ThemeProvider();
            t.initialize();
            return t;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final l = LanguageProvider();
            l.initialize();
            return l;
          },
        ),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ForecastProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          // Safe to call here: context is valid, no async side-effects
          try {
            NotificationService().setContext(context);
          } catch (_) {}
          return MaterialApp(
            title: 'CareCircle',
            theme: themeProvider.lightTheme.copyWith(
              // Force LTR for all widgets regardless of locale
              extensions: themeProvider.lightTheme.extensions.values.toList(),
            ),
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) {
              // Always LTR — Roman Urdu is Latin script, reads left-to-right
              return Directionality(
                textDirection: ui.TextDirection.ltr,
                child: child!,
              );
            },
            home: const SplashScreen(),
            routes: {
              '/requests': (_) => const RequestListScreen(),
              '/chats': (_) => const ChatRoomsScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
