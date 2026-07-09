@echo off
REM FoodBridge - GitHub Deployment Script
REM This script commits and pushes the fixed vercel.json to GitHub

echo ====================================
echo FoodBridge - GitHub Deployment
echo ====================================
echo.

echo Step 1: Checking git status...
git status
echo.

echo Step 2: Adding all changes...
git add .
echo.

echo Step 3: Committing changes...
git commit -m "Fix Vercel deployment: Add outputDirectory to vercel.json - Resolves 404 error"
echo.

echo Step 4: Pushing to GitHub...
git push origin main
echo.

echo ====================================
echo Deployment Complete!
echo ====================================
echo.
echo Next steps:
echo 1. Go to your Vercel dashboard
echo 2. Wait for automatic deployment to complete
echo 3. Visit your deployment URL
echo 4. Verify the app loads (no more 404)
echo.
echo If 404 persists:
echo - Check Vercel dashboard Source tab
echo - Verify web-build files are deployed
echo - See VERCEL_DEPLOYMENT_FIX.md for troubleshooting
echo.

pause
