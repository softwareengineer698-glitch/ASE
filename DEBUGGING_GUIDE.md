# Debugging Account Creation Issues

## Steps to Debug "Unexpected Error Occurred"

### 1. Check Console Logs
I've added detailed logging to the sign-up process. When you try to create an account, check the console for these messages:

```
Starting sign up process for email: user@example.com
User created successfully, creating Firestore document...
Firestore document created, saving role locally...
Sign up completed successfully
```

If you see an error, it will show exactly where the process failed.

### 2. Common Issues and Solutions

#### A. Firebase Authentication Issues
**Error Pattern**: `FirebaseAuthException during sign up: [error_code] - [message]`

**Common Codes**:
- `email-already-in-use`: Try with a different email
- `weak-password`: Use a password with at least 6 characters
- `invalid-email`: Check email format
- `operation-not-allowed`: Email/Password auth not enabled in Firebase Console

**Solution**: Go to Firebase Console → Authentication → Sign-in method → Enable Email/Password

#### B. Firestore Permission Issues
**Error Pattern**: `Unexpected error during sign up: [firestore error]`

**Most Likely Cause**: Firestore security rules are too restrictive

**Solution**: Update Firestore Rules in Firebase Console:
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

#### C. Missing google-services.json
**Error Pattern**: `Firebase initialization error` or `No Firebase App`

**Solution**: 
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Restart the app

### 3. Test Steps

1. **Try creating an account with these details**:
   - Email: `test@example.com`
   - Password: `password123`
   - Role: Donor

2. **Check the console output** for detailed error messages

3. **If Firestore error occurs**:
   - Go to Firebase Console → Firestore Database
   - Check if the `users` collection exists
   - Verify security rules allow authenticated users to write

### 4. Quick Firestore Test

If you want to test Firestore connectivity separately, you can temporarily add this test function to your AuthService:

```dart
// Test Firestore connectivity
Future<void> testFirestore() async {
  try {
    await firestore.collection('test').doc('test').set({'test': 'data'});
    print('Firestore test successful');
  } catch (e) {
    print('Firestore test failed: $e');
  }
}
```

### 5. Firebase Console Checklist

Ensure these are configured in your Firebase Console:

- ✅ **Authentication** → Sign-in method → Email/Password (Enabled)
- ✅ **Firestore Database** → Created (Start in test mode or with proper rules)
- ✅ **Project Settings** → Your apps → Android app registered
- ✅ **google-services.json** downloaded and placed correctly

### 6. If All Else Fails

Try creating a user directly in Firebase Console:
1. Go to Authentication → Users
2. Click "Add user"
3. Add email/password manually
4. See if the user appears in your app's sign-in

This will help isolate if the issue is with account creation or with your app's authentication flow.
