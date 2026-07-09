@echo off
REM Vercel Deployment Fix - Use Vercel CLI

echo ========================================
echo 🚀 FoodBridge Vercel Deployment
echo ========================================
echo.

echo ⚠️  IMPORTANT: Vercel cannot build Flutter automatically!
echo.
echo 📋 You have 2 options:
echo.
echo   Option 1: Deploy with Vercel CLI (RECOMMENDED)
echo   ------------------------------------------
echo   1. Install: npm install -g vercel
echo   2. Login: vercel login
echo   3. Deploy: cd build\web ^&^& vercel --prod
echo.
echo   Option 2: Commit build files to Git
echo   ------------------------------------------
echo   1. We'll commit the build/web folder
echo   2. Push to GitHub
echo   3. Configure Vercel to use Root Directory: build/web
echo.

set /p CHOICE="Choose option (1 or 2): "

if "%CHOICE%"=="1" (
    echo.
    echo 📦 Checking if Vercel CLI is installed...
    where vercel >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo ❌ Vercel CLI not found!
        echo.
        echo Please install it first:
        echo   npm install -g vercel
        echo.
        echo Then run this script again.
        pause
        exit /b 1
    )
    
    echo ✅ Vercel CLI found!
    echo.
    echo 🚀 Deploying to Vercel...
    cd build\web
    vercel --prod
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ========================================
        echo 🎉 Deployment Complete!
        echo ========================================
        echo.
        echo Your app is now live!
        echo.
        echo ⚠️  Don't forget to add Vercel domain to Firebase:
        echo    https://console.firebase.google.com
        echo    Authentication → Settings → Authorized domains
        echo.
    ) else (
        echo.
        echo ❌ Deployment failed. Please check the error above.
        echo.
    )
    
    cd ..\..
    pause
    exit /b 0
)

if "%CHOICE%"=="2" (
    echo.
    echo ⚠️  WARNING: This will add ~5-10MB to your git repository!
    echo.
    set /p CONFIRM="Continue? (y/n): "
    if /i not "%CONFIRM%"=="y" (
        echo.
        echo ❌ Cancelled
        pause
        exit /b 0
    )
    
    echo.
    echo 📦 Adding build/web to git...
    git add -f build/web
    
    echo.
    echo 💾 Committing...
    git commit -m "Add pre-built web files for Vercel deployment"
    
    echo.
    echo 🚀 Pushing to GitHub...
    git push origin main
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ========================================
        echo ✅ Files Pushed!
        echo ========================================
        echo.
        echo 📋 Now configure Vercel:
        echo.
        echo 1. Go to: https://vercel.com/dashboard
        echo 2. Select your project
        echo 3. Settings → General
        echo 4. Root Directory: build/web
        echo 5. Build Command: (leave empty)
        echo 6. Save
        echo 7. Deployments → Redeploy
        echo.
        echo After configuration, Vercel will deploy successfully!
        echo.
    ) else (
        echo.
        echo ❌ Push failed!
        echo.
    )
    
    pause
    exit /b 0
)

echo.
echo ❌ Invalid choice. Please run the script again.
pause
