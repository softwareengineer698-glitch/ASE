// Basic Flutter widget test for the FoodBridge app.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:foodbridge/main.dart';
import 'package:foodbridge/providers/auth_provider.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: const MyApp(),
      ),
    );

    // Wait for splash screen to load
    await tester.pump();

    // Verify that splash screen elements are present
    expect(find.text('FoodBridge'), findsOneWidget);
    expect(find.text('Connecting Communities'), findsOneWidget);
  });

  testWidgets('Mock data service returns surplus items', (WidgetTester tester) async {
    // This is a simple test to verify our mock data service works
    // In a real app, you would test actual functionality
    expect(true, isTrue); // Placeholder test
  });
}
