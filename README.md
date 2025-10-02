# DonateConnect - Flutter Firebase Authentication App

A complete Flutter application with Firebase Authentication and role-based access control for Donors and NGOs.

## Features

### 🔐 Authentication
- **Email/Password Authentication** with Firebase Auth
- **Role-based Registration** (Donor/NGO)
- **Forgot Password** functionality
- **Persistent Login** sessions
- **Secure Logout**

### 👥 Role-Based Access
- **Donor Dashboard** - For users who want to donate
- **NGO Dashboard** - For organizations receiving donations
- **Automatic Role-based Navigation** after login

### 🎨 UI/UX
- **Modern Material Design 3** interface
- **Clean, intuitive forms** with validation
- **Animated Splash Screen**
- **Error handling** with user-friendly messages
- **Loading states** for better UX

### 🏗️ Architecture
- **Provider State Management** for authentication state
- **Service Layer** for Firebase operations
- **Model Classes** for type safety
- **Modular Code Structure** for maintainability

## Project Structure

```
lib/
├── models/
│   └── user_model.dart              # User data model with roles
├── providers/
│   └── auth_provider.dart           # Authentication state management
├── services/
│   └── auth_service.dart            # Firebase Auth & Firestore operations
├── screens/
│   ├── auth/
│   │   ├── sign_in_screen.dart      # Login screen
│   │   ├── sign_up_screen.dart      # Registration screen
│   │   └── forgot_password_screen.dart # Password reset
│   ├── home/
│   │   ├── donor_home_page.dart     # Donor dashboard
│   │   └── ngo_home_page.dart       # NGO dashboard
│   └── splash_screen.dart           # App initialization
├── widgets/
│   ├── custom_button.dart           # Reusable button component
│   └── custom_text_field.dart       # Reusable input field
└── main.dart                        # App entry point
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.10
  
  # State Management & Utilities
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  
  # UI
  cupertino_icons: ^1.0.6
```

## Setup Instructions

### 1. Firebase Configuration

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one

2. **Add Android App**
   - Package name: `com.example.ase`
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

3. **Enable Firebase Services**
   - **Authentication**: Enable Email/Password provider
   - **Firestore**: Create database in production/test mode
   - **Storage**: Enable for file uploads (optional)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## Authentication Flow

### 1. Splash Screen
- Checks authentication state
- Navigates to appropriate screen based on login status

### 2. Registration Flow
```
Sign Up → Enter Email/Password/Role → Create Firebase Account → 
Create Firestore User Document → Navigate to Role-based Home
```

### 3. Login Flow
```
Sign In → Enter Email/Password → Authenticate with Firebase → 
Fetch User Role from Firestore → Navigate to Role-based Home
```

### 4. Password Reset
```
Forgot Password → Enter Email → Send Reset Email → 
User Clicks Email Link → Reset Password → Login
```

## User Roles

### Donor
- **Purpose**: Users who want to make donations
- **Dashboard Features**:
  - Make donations
  - Find NGOs
  - View donation history
  - Manage profile

### NGO
- **Purpose**: Organizations that receive donations
- **Dashboard Features**:
  - Create campaigns
  - Manage donations
  - View analytics
  - Organization profile

## Firebase Security Rules

### Firestore Rules (users collection)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## State Management

The app uses **Provider** for state management:

- **AuthProvider**: Manages authentication state, user data, and loading states
- **Persistent Storage**: User role saved locally for quick access
- **Real-time Updates**: Authentication state changes trigger UI updates

## Error Handling

- **Firebase Auth Exceptions**: Translated to user-friendly messages
- **Network Errors**: Graceful handling with retry options
- **Validation Errors**: Real-time form validation
- **Loading States**: Visual feedback during async operations

## Security Features

- **Email Validation**: Regex-based email format checking
- **Password Strength**: Minimum 6 characters requirement
- **Secure Storage**: User sessions managed by Firebase
- **Role Verification**: Server-side role validation
- **Auto-logout**: Session expiry handling

## Customization

### Themes
The app uses Material Design 3 with customizable themes in `main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
  // Custom theme configurations
),
```

### Adding New Features
1. Create new screens in `lib/screens/`
2. Add navigation routes
3. Update user roles if needed
4. Extend Firestore data models

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `google-services.json` is in correct location
   - Check Firebase project configuration

2. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Check minimum SDK version (21+)

3. **Authentication errors**
   - Verify Firebase Auth is enabled
   - Check email/password provider settings

### Debug Mode
- Firebase initialization logs are printed to console
- Authentication errors are displayed via SnackBars
- Loading states provide visual feedback

## Future Enhancements

- [ ] Social media authentication (Google, Facebook)
- [ ] Email verification requirement
- [ ] Two-factor authentication
- [ ] Admin role and dashboard
- [ ] Push notifications
- [ ] Offline support
- [ ] Multi-language support

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
