# FoodBridge Web Deployment Guide

## 🌐 Web Build Information

**Build Date**: July 3, 2026  
**Version**: 1.2.0  
**Platform**: Flutter Web (Release Build)  
**Base URL**: `/ASE-main/` (configured for GitHub Pages)

---

## 📦 Build Output

The web build is located in: `build/web/`

**Key Files**:
- `index.html` - Main entry point
- `main.dart.js` - Compiled Dart code
- `flutter.js` - Flutter web engine
- `manifest.json` - PWA configuration
- `.nojekyll` - GitHub Pages configuration (prevents Jekyll processing)
- `assets/` - Images, fonts, and other assets
- `canvaskit/` - Flutter's canvas rendering engine
- `icons/` - App icons for PWA

---

## 🚀 GitHub Pages Deployment Steps

### Method 1: Using GitHub Actions (Recommended)

1. **Create GitHub Actions Workflow**:
   Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release --base-href /ASE-main/
      
      - name: Add .nojekyll
        run: touch build/web/.nojekyll
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

2. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Source: Deploy from a branch
   - Branch: `gh-pages` (will be created by action)
   - Click Save

3. **Push changes and wait for deployment** (usually takes 2-3 minutes)

---

### Method 2: Manual Deployment

1. **Commit the build/web folder**:
```bash
git add build/web
git commit -m "Add web build for GitHub Pages"
```

2. **Push to gh-pages branch**:
```bash
git subtree push --prefix build/web origin gh-pages
```

Or create a new branch:
```bash
git checkout -b gh-pages
git rm -rf . --cached
git add build/web/*
git commit -m "Deploy web build"
git push origin gh-pages
```

3. **Configure GitHub Pages**:
   - Go to Settings → Pages
   - Source: Deploy from a branch
   - Branch: `gh-pages`
   - Folder: `/ (root)`

---

### Method 3: Direct Folder Deployment (Current Build)

Since the build is already complete, you can:

1. **Copy the build/web contents to a separate branch**:
```powershell
# Create a temporary directory
mkdir temp-deploy
xcopy build\web temp-deploy\ /E /I

# Switch to gh-pages branch (or create it)
git checkout -b gh-pages
git rm -rf .
xcopy ..\temp-deploy\* . /E

# Commit and push
git add .
git commit -m "Deploy FoodBridge v1.2.0"
git push origin gh-pages
```

2. **Enable GitHub Pages** pointing to `gh-pages` branch

---

## ⚙️ Configuration Details

### Base HREF
The web build is configured with `--base-href /ASE-main/` which assumes:
- Repository name: `ASE-main`
- GitHub Pages URL: `https://username.github.io/ASE-main/`

**If your repository name is different**, rebuild with:
```bash
flutter build web --release --base-href /YOUR-REPO-NAME/
```

### PWA Configuration
The app is configured as a Progressive Web App (PWA):
- **Name**: FoodBridge
- **Short Name**: FoodBridge
- **Theme Color**: #4CAF50 (Green)
- **Description**: Connect food donors with NGOs to reduce food waste and fight hunger
- **Icons**: 192x192, 512x512 (standard and maskable)

---

## 🧪 Testing the Web Build Locally

Before deploying, test locally:

```bash
# Install a simple HTTP server
flutter pub global activate dhttpd

# Serve the web build
dhttpd --path build/web --port 8080

# Open in browser
# Navigate to: http://localhost:8080
```

Or use Python:
```bash
cd build\web
python -m http.server 8080
```

---

## 🌍 Expected Deployment URL

After successful deployment, your app will be available at:

```
https://YOUR-USERNAME.github.io/ASE-main/
```

Example:
- If username is `john-doe`: https://john-doe.github.io/ASE-main/

---

## 📱 Features Available on Web

All FoodBridge features are available on web except:
- **Camera capture** (web uses file picker instead)
- **Push notifications** (requires FCM web setup)
- **Background location** (limited by browser security)
- **Voice input** (requires microphone permissions)

Location services work via browser's Geolocation API (user must grant permission).

---

## 🔧 Troubleshooting

### Issue: 404 Error or Blank Page
**Solution**: 
- Ensure `.nojekyll` file exists in build/web
- Check base-href matches repository name
- Verify gh-pages branch contains web files at root

### Issue: Assets Not Loading
**Solution**:
- Rebuild with correct `--base-href`
- Check browser console for 404 errors
- Ensure assets folder is included in deployment

### Issue: Firebase Not Working
**Solution**:
- Ensure Firebase is configured for web in Firebase Console
- Add your GitHub Pages domain to Firebase authorized domains
- Check `web/index.html` has Firebase initialization scripts if needed

### Issue: Routing Not Working
**Solution**:
- Flutter web uses hash routing by default (#/route)
- For clean URLs, add a 404.html redirect (copy of index.html)

---

## 🔐 Security Notes

1. **API Keys**: Ensure Firebase API keys are web-safe (domain restricted)
2. **CORS**: Firebase services handle CORS automatically
3. **HTTPS**: GitHub Pages serves over HTTPS automatically

---

## 📊 Build Statistics

- **Total Size**: ~5-10 MB (varies with assets)
- **Main JS Bundle**: ~2-3 MB (compressed)
- **Tree-shaken Icons**: 
  - MaterialIcons: Reduced from 1.6MB to 25KB (98.4% reduction)
  - CupertinoIcons: Reduced from 257KB to 1.5KB (99.4% reduction)
- **Canvaskit**: ~2 MB (Flutter rendering engine)

---

## 🎯 Post-Deployment Checklist

- [ ] Web app loads successfully
- [ ] All pages/routes work correctly
- [ ] Images and assets load properly
- [ ] Firebase authentication works
- [ ] Location services prompt appears
- [ ] Responsive design works on mobile/tablet
- [ ] PWA can be installed (Add to Home Screen)
- [ ] Performance is acceptable (check with Lighthouse)

---

## 📝 Additional Notes

- The web build uses Flutter's CanvasKit renderer for better performance
- Service workers are included for offline capability
- The app is optimized for modern browsers (Chrome, Firefox, Safari, Edge)
- Consider enabling WASM builds for better performance (experimental)

---

## 🔄 Updating the Deployment

To update after changes:

1. Make code changes
2. Rebuild: `flutter build web --release --base-href /ASE-main/`
3. Deploy using your chosen method above
4. Wait 2-3 minutes for GitHub Pages to update

---

## 📞 Support

For issues with:
- **Flutter Web**: https://docs.flutter.dev/platform-integration/web
- **GitHub Pages**: https://docs.github.com/en/pages
- **Firebase Web**: https://firebase.google.com/docs/web/setup

---

**Deployment Status**: ✅ Build Complete - Ready for GitHub Pages!
