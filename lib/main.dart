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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize services
  await _initializeServices();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Brief delay to ensure Firebase is fully ready
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'app_title'.tr(),
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
