# Firebase Setup Instructions

## Prerequisites
Before running your Flutter app with Firebase, you need to complete the following setup steps:

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter your project name (e.g., "ASE Project")
4. Follow the setup wizard to create your project

## 2. Add Android App to Firebase Project

1. In your Firebase project console, click "Add app" and select Android
2. Enter your Android package name: `com.example.ase`
3. Enter an app nickname (optional): "ASE Android App"
4. Enter SHA-1 certificate fingerprint (optional for development)

## 3. Download google-services.json

1. After registering your app, Firebase will provide a `google-services.json` file
2. Download this file
3. Place it in the following location in your project:
   ```
   android/app/google-services.json
   ```

## 4. Enable Firebase Services (Optional)

Depending on your needs, enable the following services in your Firebase console:

### Authentication
- Go to Authentication > Sign-in method
- Enable the sign-in providers you want to use (Email/Password, Google, etc.)

### Firestore Database
- Go to Firestore Database
- Click "Create database"
- Choose production mode or test mode
- Select a location for your database

### Cloud Storage
- Go to Storage
- Click "Get started"
- Set up security rules as needed

### Cloud Messaging
- Go to Cloud Messaging
- No additional setup required for basic functionality

## 5. Run Your App

After placing the `google-services.json` file in the correct location:

1. Run `flutter pub get` to install dependencies
2. Run `flutter run` to start your app

## Firebase Services Available

Your project is now configured with the following Firebase packages:

- **firebase_core**: Core Firebase functionality
- **firebase_auth**: User authentication
- **cloud_firestore**: NoSQL database
- **firebase_storage**: File storage
- **firebase_messaging**: Push notifications

## Example Usage

### Initialize Firebase (Already done in main.dart)
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### Firebase Authentication Example
```dart
import 'package:firebase_auth/firebase_auth.dart';

// Sign up with email and password
Future<UserCredential> signUp(String email, String password) async {
  return await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}

// Sign in with email and password
Future<UserCredential> signIn(String email, String password) async {
  return await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}
```

### Firestore Database Example
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Add data to Firestore
Future<void> addUser(String name, String email) async {
  await FirebaseFirestore.instance.collection('users').add({
    'name': name,
    'email': email,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// Read data from Firestore
Stream<QuerySnapshot> getUsers() {
  return FirebaseFirestore.instance.collection('users').snapshots();
}
```

## Troubleshooting

### Common Issues:

1. **Build fails with "google-services.json not found"**
   - Ensure the file is placed in `android/app/google-services.json`
   - Check that the file name is exactly `google-services.json`

2. **Firebase not initialized error**
   - Make sure `Firebase.initializeApp()` is called before `runApp()`
   - Ensure `WidgetsFlutterBinding.ensureInitialized()` is called first

3. **Minimum SDK version error**
   - Firebase requires minimum SDK version 21 (already configured)

4. **Multidex error**
   - Multidex is already enabled in the build.gradle configuration

## Next Steps

1. Download and place your `google-services.json` file
2. Run `flutter pub get`
3. Test your app with `flutter run`
4. Start implementing Firebase features as needed

For more detailed documentation, visit the [Firebase Flutter documentation](https://firebase.flutter.dev/).
