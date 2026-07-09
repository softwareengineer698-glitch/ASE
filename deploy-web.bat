@echo off
REM FoodBridge Web Deployment Script for GitHub Pages (Windows)

echo ========================================
echo 🚀 FoodBridge Web Deployment Script
echo ========================================
echo.

REM Check if build/web exists
if not exist "build\web" (
    echo ❌ Error: build\web directory not found!
    echo Please run: flutter build web --release --base-href /ASE-main/
    exit /b 1
)

echo 📦 Found web build directory
echo.

REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i
echo 📍 Current branch: %CURRENT_BRANCH%
echo.

REM Confirm deployment
set /p CONFIRM="Deploy to GitHub Pages? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo ❌ Deployment cancelled
    exit /b 0
)

echo 🔄 Starting deployment...
echo.

REM Create temporary directory
set TEMP_DIR=%TEMP%\foodbridge-deploy-%RANDOM%
mkdir "%TEMP_DIR%"
echo 📁 Created temp directory: %TEMP_DIR%

REM Copy build files
xcopy build\web "%TEMP_DIR%" /E /I /Q
echo ✅ Copied build files

REM Switch to gh-pages branch
git checkout gh-pages 2>nul || git checkout -b gh-pages
echo ✅ Switched to gh-pages branch

REM Remove old files (except .git)
git rm -rf . 2>nul
echo ✅ Cleaned old files

REM Copy new build
xcopy "%TEMP_DIR%" . /E /I /Q /Y
echo ✅ Copied new build

REM Clean up temp directory
rmdir /s /q "%TEMP_DIR%"
echo ✅ Cleaned temp directory

REM Add all files
git add .
echo ✅ Staged files

REM Commit
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a:%%b)
git commit -m "Deploy FoodBridge v1.2.0 - %mydate% %mytime%"
echo ✅ Created commit

REM Push
git push origin gh-pages --force
echo ✅ Pushed to GitHub Pages

REM Switch back to original branch
git checkout %CURRENT_BRANCH%
echo ✅ Switched back to %CURRENT_BRANCH%

echo.
echo ========================================
echo 🎉 Deployment complete!
echo ========================================
echo 📍 Your app will be available at:
echo    https://YOUR-USERNAME.github.io/ASE-main/
echo.
echo ⏱️  GitHub Pages may take 2-3 minutes to update
echo.
pause
