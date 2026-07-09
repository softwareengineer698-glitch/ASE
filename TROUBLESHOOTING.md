# Troubleshooting Guide

## ❌ FlutterError: Looking up a deactivated widget's ancestor

### Problem
```
FlutterError (Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.)
```

### Root Cause
This error occurs when trying to access a widget's context after the widget has been disposed or unmounted. Common scenarios:
- Async operations completing after widget disposal
- ShowDialog callbacks accessing context after navigation
- Timer callbacks updating disposed widgets

### ✅ Solution Applied

#### 1. Added Mounted Checks
```dart
// Before async operations
if (!mounted) return;

// After async operations
if (!mounted) return;
```

#### 2. Fixed Dialog Context Usage
```dart
// Before (problematic)
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    // Using same context variable
  ),
);

// After (fixed)
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    // Using separate dialogContext
  ),
);
```

#### 3. Protected State Updates
```dart
// Before
setState(() {
  // Update state
});

// After
if (mounted) {
  setState(() {
    // Update state
  });
}
```

### Files Fixed
- ✅ `ngo_dashboard.dart` - _reserveItem method
- ✅ `ngo_dashboard.dart` - _loadSurplusData method
- ✅ `forecast_dashboard.dart` - _loadForecastData method
- ✅ `add_surplus_screen.dart` - _submitSurplus method

### Prevention Tips
1. Always check `mounted` before async operations
2. Use separate context variables in dialogs
3. Wrap setState calls with mounted checks
4. Cancel timers/streams in dispose()

## 🔧 Other Common Issues

### Issue: Chart not displaying
**Solution**: Ensure `flutter pub get` was run after adding fl_chart dependency

### Issue: Navigation errors
**Solution**: Use proper MaterialPageRoute and check route stack

### Issue: Mock data not loading
**Solution**: Check Future.delayed completion and mounted state

## 🚀 Quick Fixes

### Reset App State
```bash
flutter clean
flutter pub get
flutter run
```

### Debug Widget Tree
Add this to debug widget issues:
```dart
debugPrint('Widget mounted: $mounted');
```

### Check Dependencies
```bash
flutter doctor
flutter pub deps
```

---

**Status**: All known widget lifecycle issues have been resolved ✅
