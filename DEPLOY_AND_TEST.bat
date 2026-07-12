@echo off
echo ============================================
echo CHAT FIX DEPLOYMENT SCRIPT
echo ============================================
echo.

echo Step 1: Deploying Firestore Rules...
echo.
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Firebase rules deployment failed!
    echo Make sure you're logged in with: firebase login
    pause
    exit /b 1
)

echo.
echo ============================================
echo Step 2: Rules deployed successfully!
echo ============================================
echo.
echo Now you need to RESTART your Flutter app:
echo.
echo Option 1: If Flutter is running in another terminal:
echo   - Press Ctrl+C to stop it
echo   - Run: flutter run -d chrome
echo.
echo Option 2: If Flutter is running in this terminal:
echo   - Press Shift+R for hot restart
echo.
echo After restart, test the chat:
echo   1. Open browser DevTools (F12) and check Console
echo   2. Type a message and click Send
echo   3. Look for these debug prints:
echo      - "💬 Send button tapped!"
echo      - "💬 _sendMessage called:"
echo      - "💬 ✅ Message written successfully:"
echo.
echo If you see success messages but no messages appear,
echo check Firebase Console → Firestore to verify writes.
echo.
pause
