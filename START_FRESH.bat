@echo off
cls
echo ============================================
echo    CHAT FIX - FRESH START
echo ============================================
echo.
echo This will start Flutter with the chat fixes.
echo.
echo What you'll see after it starts:
echo   1. Open the chat screen
echo   2. Look for "v2.0" badge in the app bar
echo   3. Open browser console (F12)
echo   4. Look for "ChatScreen initialized - NEW CODE LOADED"
echo.
echo ============================================
echo.

echo Starting Flutter on Chrome...
echo.
flutter run -d chrome

pause
