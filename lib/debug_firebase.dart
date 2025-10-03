import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Simple Firebase debug app to test initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting Firebase initialization...');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
    print('Firebase apps: ${Firebase.apps.length}');
    
    // Test if Firebase is working
    if (Firebase.apps.isNotEmpty) {
      print('✅ Firebase is ready to use');
    } else {
      print('❌ Firebase apps list is empty');
    }
    
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Debug',
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Debug')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud, size: 100, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'Firebase Debug Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Check console for Firebase initialization status'),
            ],
          ),
        ),
      ),
    );
  }
}
