# FoodBridge Vercel Deployment Guide

**Issue**: Blank page on Vercel deployment  
**Solution**: Proper Vercel configuration + correct build settings

---

## 🔧 What Was Fixed

### 1. Removed Base HREF
The previous build had `--base-href /ASE-main/` which is only for GitHub Pages. Vercel needs the app at root path `/`.

### 2. Added vercel.json
Created proper Vercel configuration file with:
- Correct routing (all routes go to index.html)
- Build command for Flutter web
- Output directory pointing to build/web

---

## 🚀 Quick Fix - Deploy Now

### Option 1: Redeploy on Vercel Dashboard

1. **Go to Vercel Dashboard**: https://vercel.com/dashboard
2. **Find your project**: "foodbridge" or similar
3. **Go to Settings** → **General**
4. **Framework Preset**: None (or Other)
5. **Build Command**: `flutter build web --release`
6. **Output Directory**: `build/web`
7. **Install Command**: `flutter pub get`
8. **Click Save**
9. **Go to Deployments** tab
10. **Click "Redeploy"** on the latest deployment

### Option 2: Commit and Push (Automatic Deployment)

```bash
# Add all changes
git add .

# Commit
git commit -m "Fix Vercel deployment - remove base-href and add vercel.json"

# Push to main branch
git push origin main
```

Vercel will automatically detect the push and redeploy.

---

## 📋 Vercel Configuration (vercel.json)

The `vercel.json` file has been created with these settings:

```json
{
  "version": 2,
  "public": false,
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "flutter pub get",
  "framework": null
}
```

### What This Does:
- **routes**: Redirects all paths to index.html (enables Flutter routing)
- **buildCommand**: Tells Vercel how to build your Flutter app
- **outputDirectory**: Points to the build output
- **installCommand**: Installs Flutter dependencies

---

## 🔍 Troubleshooting

### Issue 1: Still Showing Blank Page After Redeploy

**Check Browser Console:**
1. Press F12 to open Developer Tools
2. Go to Console tab
3. Look for errors (red messages)

**Common Errors:**

**A) MIME Type Error**
```
Failed to load module script: Expected a JavaScript module script but the server responded with a MIME type of "text/html"
```
**Solution**: Clear Vercel cache
```bash
# In Vercel Dashboard → Deployments → [Your Deployment] → More → Clear Cache and Redeploy
```

**B) 404 Errors for Assets**
```
GET https://foodbridge-chi-nine.vercel.app/assets/... 404
```
**Solution**: Rebuild with correct paths
```bash
flutter clean
flutter pub get
flutter build web --release
git add build/web
git commit -m "Rebuild web with correct paths"
git push origin main
```

**C) Firebase Connection Issues**
```
Firebase: Error (auth/...)
```
**Solution**: Add Vercel domain to Firebase authorized domains
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Authentication → Settings → Authorized domains
4. Add: `foodbridge-chi-nine.vercel.app` (your Vercel domain)
5. Click Save

---

### Issue 2: Routing Not Working (404 on Refresh)

**Symptom**: App works initially, but refreshing a page shows 404

**Solution**: Already fixed in vercel.json! The routing configuration handles this.

If still not working:
1. Check vercel.json is in the root directory
2. Redeploy from Vercel dashboard
3. Clear browser cache (Ctrl+Shift+Delete)

---

### Issue 3: App Takes Too Long to Load

**Solutions:**

**A) Enable CanvasKit Compression**
Already done! The build uses tree-shaking.

**B) Use CDN for CanvasKit** (Optional)
Edit `web/index.html` and add:
```html
<script>
  window.flutterConfiguration = {
    canvasKitBaseUrl: "https://unpkg.com/canvaskit-wasm@0.38.0/bin/"
  };
</script>
```

**C) Enable Caching**
Add to `vercel.json`:
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

---

## 🌐 Environment Variables (If Using Firebase)

If you need to set Firebase config as environment variables:

1. **Go to Vercel Dashboard** → Your Project → Settings → Environment Variables
2. **Add these variables**:
   - `FIREBASE_API_KEY`
   - `FIREBASE_AUTH_DOMAIN`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_STORAGE_BUCKET`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_APP_ID`

3. **Update your code** to use environment variables (if needed)

---

## ✅ Verification Steps

After deployment, verify:

1. **Homepage Loads**
   - Visit: https://foodbridge-chi-nine.vercel.app
   - Should show login/signup screen

2. **Routing Works**
   - Navigate to different pages
   - Refresh the page (should not 404)

3. **Assets Load**
   - Images display correctly
   - Icons show properly
   - No 404 errors in console

4. **Firebase Works**
   - Can register new user
   - Can login
   - Can create donations

5. **Responsive Design**
   - Test on mobile view (F12 → Toggle device toolbar)
   - Test on tablet view
   - Test on desktop view

---

## 📊 Deployment Comparison

| Platform | Base HREF | Configuration | Routing |
|----------|-----------|---------------|---------|
| **Vercel** | None (root `/`) | `vercel.json` | SPA redirects |
| **GitHub Pages** | `/ASE-main/` | `.nojekyll` | Hash routing |
| **Firebase Hosting** | None | `firebase.json` | Rewrites |
| **Netlify** | None | `_redirects` | SPA redirects |

---

## 🔄 Updating Deployment

Whenever you make changes:

```bash
# 1. Make code changes
# ... edit files ...

# 2. Test locally (optional)
flutter run -d chrome

# 3. Commit and push
git add .
git commit -m "Your changes description"
git push origin main

# Vercel will automatically build and deploy!
```

---

## 🎯 Custom Domain (Optional)

To use a custom domain like `foodbridge.com`:

1. **Buy domain** (Namecheap, GoDaddy, etc.)
2. **In Vercel Dashboard** → Your Project → Settings → Domains
3. **Add Domain**: Enter your domain
4. **Follow DNS Instructions**: Update your domain's DNS records
5. **Wait for SSL**: Vercel automatically provisions SSL certificate

---

## 🚨 Common Mistakes to Avoid

1. ❌ **Don't use** `--base-href` for Vercel
2. ❌ **Don't commit** `build/` folder to git (too large)
3. ❌ **Don't forget** to add Vercel domain to Firebase
4. ❌ **Don't use** relative paths in assets
5. ✅ **Do use** `vercel.json` for configuration
6. ✅ **Do clear** cache if changes don't appear
7. ✅ **Do test** locally before deploying

---

## 📱 Testing Checklist

Before considering deployment successful:

- [ ] Homepage loads without errors
- [ ] Login/signup works
- [ ] Firebase authentication functions
- [ ] Can create donations
- [ ] Can claim food
- [ ] Images load correctly
- [ ] Navigation works
- [ ] Page refresh doesn't break routing
- [ ] Mobile view is responsive
- [ ] No console errors
- [ ] Performance is acceptable (< 3s load time)

---

## 🔗 Useful Links

- **Your Vercel Dashboard**: https://vercel.com/dashboard
- **Vercel Docs**: https://vercel.com/docs
- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Firebase Console**: https://console.firebase.google.com

---

## 📞 Quick Commands

```bash
# Rebuild web
flutter build web --release

# Test locally
flutter run -d chrome

# Commit changes
git add .
git commit -m "Update"
git push origin main

# Force clear cache
# (In Vercel Dashboard → Deployments → More → Clear Cache)
```

---

## ✅ Current Status

- ✅ Web build completed successfully (no base-href)
- ✅ vercel.json created with correct configuration
- ✅ All compilation errors fixed
- ✅ Ready for deployment

**Next Step**: 
1. Commit changes: `git add . && git commit -m "Fix Vercel deployment"`
2. Push to GitHub: `git push origin main`
3. Wait 2-3 minutes for automatic Vercel deployment
4. Visit: https://foodbridge-chi-nine.vercel.app

---

**Last Updated**: July 3, 2026  
**Status**: ✅ Ready to Deploy
