# FoodBridge App Icon and Name Setup Guide

## 🎯 Overview
This guide explains how to set up the custom app icon and change the app name to "FoodBridge" using flutter_launcher_icons.

## 📱 What's Been Configured

### 1. App Name Changes
- ✅ **pubspec.yaml**: Changed from "ase" to "foodbridge"
- ✅ **Android**: Updated AndroidManifest.xml label to "FoodBridge"
- ✅ **iOS**: Updated Info.plist CFBundleDisplayName and CFBundleName to "FoodBridge"
- ✅ **Main App**: Updated MaterialApp title to "FoodBridge"
- ✅ **Splash Screen**: Updated display text to "FoodBridge"

### 2. App Icon Configuration
- ✅ **Added flutter_launcher_icons dependency**: Version ^0.13.1
- ✅ **Icon asset**: Using `assets/icon.jpg`
- ✅ **Platform support**: Android, iOS, Web, Windows
- ✅ **Android icon name**: `launcher_icon`
- ✅ **Updated AndroidManifest.xml**: Points to new icon

## 🛠️ Setup Instructions

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate App Icons
```bash
flutter pub run flutter_launcher_icons:main
```

### Step 3: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## 📋 Configuration Details

### pubspec.yaml Configuration
```yaml
name: foodbridge
description: "FoodBridge - Connecting food donors with NGOs to reduce waste and feed communities."

dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.jpg"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon.jpg"
  windows:
    generate: true
    image_path: "assets/icon.jpg"
    icon_size: 48

assets:
  - assets/icon.jpg
```

### Android Configuration
**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<application
    android:label="FoodBridge"
    android:icon="@mipmap/launcher_icon">
```

### iOS Configuration
**File**: `ios/Runner/Info.plist`
```xml
<key>CFBundleDisplayName</key>
<string>FoodBridge</string>
<key>CFBundleName</key>
<string>FoodBridge</string>
```

## 🎨 Icon Requirements

### Current Icon
- **Location**: `assets/icon.jpg`
- **Format**: JPG
- **Recommended size**: 1024x1024 pixels minimum

### Optimal Icon Specifications
- **Size**: 1024x1024 pixels
- **Format**: PNG (preferred) or JPG
- **Background**: Should work on various backgrounds
- **Design**: Simple, recognizable, scalable

## 🔧 Troubleshooting

### Common Issues

#### 1. Icons Not Updating
```bash
# Clean everything
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter run
```

#### 2. Android Icon Issues
- Ensure `launcher_icon` is generated in `android/app/src/main/res/mipmap-*` folders
- Check AndroidManifest.xml points to `@mipmap/launcher_icon`

#### 3. iOS Icon Issues
- Verify icons are generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Ensure Info.plist has correct bundle names

#### 4. Asset Not Found
- Verify `assets/icon.jpg` exists
- Check `pubspec.yaml` assets section includes the icon
- Run `flutter pub get` after changes

## 📱 Platform-Specific Notes

### Android
- Icons generated in multiple resolutions (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Uses `launcher_icon` as the resource name
- Supports adaptive icons for Android 8.0+

### iOS
- Generates complete AppIcon.appiconset
- Includes all required sizes for different devices
- Supports iPhone, iPad, and Apple Watch

### Web
- Generates favicon and web app icons
- Includes manifest.json entries
- Supports PWA installation

### Windows
- Generates ICO file for Windows desktop
- Configurable icon size (48px default)
- Supports Windows 10/11 apps

## 🚀 Next Steps

### After Icon Generation
1. **Test on Device**: Install on physical device to verify icon appearance
2. **Test Different Themes**: Check icon visibility on light/dark themes
3. **App Store Preparation**: Ensure icon meets store guidelines

### Future Improvements
- Consider creating adaptive icons for Android
- Add app icon variants for different contexts
- Create branded splash screen with new icon

## ✅ Verification Checklist

- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run flutter_launcher_icons:main`
- [ ] Build and install app on device
- [ ] Verify app name shows as "FoodBridge"
- [ ] Verify custom icon appears correctly
- [ ] Test on both Android and iOS (if available)
- [ ] Check app launcher/home screen appearance

---

**Note**: After running the icon generation command, you may need to uninstall and reinstall the app on your device to see the new icon, especially on iOS.

**App Name**: FoodBridge
**Icon Source**: assets/icon.jpg
**Last Updated**: October 2025
