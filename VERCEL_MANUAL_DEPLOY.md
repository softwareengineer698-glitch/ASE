# Vercel Manual Deployment Guide

## The Problem

Vercel doesn't have Flutter pre-installed, so automatic builds fail. The solution is to deploy the **pre-built** `build/web` folder directly.

---

## ✅ Solution: Deploy Pre-Built Files

### Method 1: Vercel CLI (Recommended)

#### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

#### Step 2: Login to Vercel
```bash
vercel login
```

#### Step 3: Deploy from build/web folder
```bash
cd build/web
vercel --prod
```

That's it! Vercel will deploy the pre-built files.

---

### Method 2: Vercel Dashboard (Drag & Drop)

#### Step 1: Disconnect Git Integration (Temporarily)

1. Go to: https://vercel.com/dashboard
2. Select your project: **foodbridge-chi-nine**
3. Settings → Git
4. Click **Disconnect**

#### Step 2: Deploy via Dashboard

1. Go to: https://vercel.com/new
2. Click **Deploy** button
3. Select **Browse** or drag folder
4. Navigate to: `D:\Projects\ASE-main\build\web`
5. Select the **web** folder
6. Click **Deploy**

✅ Your app will deploy successfully!

---

### Method 3: Change Project Settings

Keep Git connected but configure to use pre-built files:

#### Step 1: Update Vercel Project Settings

1. Go to: https://vercel.com/dashboard
2. Select: **foodbridge-chi-nine**
3. Settings → General
4. **Root Directory**: `build/web`
5. **Framework Preset**: Other
6. **Build Command**: Leave empty
7. **Output Directory**: Leave empty (already in root)
8. **Install Command**: Leave empty
9. Click **Save**

#### Step 2: Commit build/web to Git

⚠️ **Warning**: This will add ~5-10MB to your repository

```bash
# Remove build from .gitignore temporarily
# Edit .gitignore and comment out /build/

# Add build/web folder
git add build/web

# Commit
git commit -m "Add pre-built web files for Vercel deployment"

# Push
git push origin main
```

Vercel will now deploy the pre-built files automatically!

---

## 🎯 Recommended Approach: Use Vercel CLI

The Vercel CLI method is cleanest because:
- ✅ No need to commit build files
- ✅ No need to disconnect Git
- ✅ Deploy whenever you want
- ✅ Fast deployment (~30 seconds)

### Quick CLI Workflow

```bash
# 1. Build Flutter web
flutter build web --release

# 2. Deploy to Vercel
cd build/web
vercel --prod

# Done! 🎉
```

---

## 🔄 Alternative: Use GitHub Actions

Create `.github/workflows/deploy-vercel.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./build/web
```

You'll need to add secrets in GitHub:
- `VERCEL_TOKEN` - Get from Vercel Settings → Tokens
- `VERCEL_ORG_ID` - Found in Vercel project settings
- `VERCEL_PROJECT_ID` - Found in Vercel project settings

---

## 📋 Step-by-Step: CLI Deployment (Easiest)

### 1. Install Vercel CLI

**Windows (PowerShell as Administrator):**
```powershell
npm install -g vercel
```

**Mac/Linux:**
```bash
npm install -g vercel
# or
sudo npm install -g vercel
```

### 2. Login to Vercel
```bash
vercel login
```

This will open your browser. Click **Continue** to authorize.

### 3. Navigate to build folder
```bash
cd D:\Projects\ASE-main\build\web
```

### 4. Deploy
```bash
vercel --prod
```

Answer the prompts:
- **Set up and deploy?** → Y
- **Which scope?** → Select your account
- **Link to existing project?** → Y
- **What's the name?** → foodbridge-chi-nine (or similar)
- **Overwrite settings?** → N

### 5. Done!
You'll see:
```
✓ Production: https://foodbridge-chi-nine.vercel.app [copied to clipboard]
```

---

## ✅ Verify Deployment

After deployment:

1. **Visit**: https://foodbridge-chi-nine.vercel.app
2. **Should see**: FoodBridge login screen ✅
3. **Open Console**: F12 → Console tab
4. **Check**: No errors (except Firebase auth if not configured)

---

## 🔧 Troubleshooting

### Issue: "Command not found: vercel"

**Solution**: Make sure Node.js is installed
```bash
# Check Node.js
node --version

# If not installed, download from: https://nodejs.org
```

### Issue: "Error: No existing credentials found"

**Solution**: Run login again
```bash
vercel login
```

### Issue: "This directory is already linked to a different project"

**Solution**: Unlink and redeploy
```bash
vercel unlink
vercel --prod
```

### Issue: Firebase authentication not working

**Solution**: Add Vercel domain to Firebase
1. https://console.firebase.google.com
2. Authentication → Settings → Authorized domains
3. Add: `foodbridge-chi-nine.vercel.app`

---

## 📊 Comparison: Deployment Methods

| Method | Pros | Cons | Recommended |
|--------|------|------|-------------|
| **Vercel CLI** | Fast, no git changes, easy | Need to install CLI | ⭐⭐⭐⭐⭐ |
| **Dashboard Drag-Drop** | No CLI needed | Manual process | ⭐⭐⭐⭐ |
| **Git with build/** | Automatic | Commits build files (large) | ⭐⭐⭐ |
| **GitHub Actions** | Fully automated | Complex setup | ⭐⭐⭐⭐ |

---

## 🎯 My Recommendation

**Use Vercel CLI** - It's the fastest and cleanest method!

```bash
# Install once
npm install -g vercel

# Then whenever you want to deploy:
flutter build web --release
cd build/web
vercel --prod
```

That's it! 30 seconds to deploy. 🚀

---

## 📝 Summary

**Problem**: Vercel can't build Flutter automatically  
**Solution**: Deploy pre-built `build/web` folder  
**Best Method**: Vercel CLI  
**Time to Deploy**: ~30 seconds  

---

**Need help?** The Vercel CLI is the easiest. Just run:
```bash
npm install -g vercel
cd build/web
vercel --prod
```

Done! ✅
