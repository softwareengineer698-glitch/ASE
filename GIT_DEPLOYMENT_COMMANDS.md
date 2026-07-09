# Git Deployment Commands for FoodBridge

## 🚀 Quick Start - Deploy Everything

### Step 1: Commit All Changes to Main Branch

```bash
# Add all changes
git add .

# Commit with descriptive message
git commit -m "FoodBridge v1.2.0 - Complete implementation with all 18 requirements"

# Push to main branch
git push origin main
```

---

## 🌐 Deploy Web Build to GitHub Pages

### Method 1: Using Deploy Script (Easiest)

#### Windows:
```cmd
deploy-web.bat
```

#### Linux/Mac:
```bash
chmod +x deploy-web.sh
./deploy-web.sh
```

---

### Method 2: Manual Deployment

```bash
# Ensure you're on main branch
git checkout main

# Create/switch to gh-pages branch
git checkout -b gh-pages

# Remove all files except .git
git rm -rf .

# Copy web build
cp -r build/web/* .

# Stage all files
git add .

# Commit
git commit -m "Deploy FoodBridge v1.2.0 web build"

# Force push to gh-pages
git push origin gh-pages --force

# Switch back to main
git checkout main
```

#### Windows Version:
```cmd
REM Ensure you're on main branch
git checkout main

REM Create/switch to gh-pages branch
git checkout -b gh-pages

REM Remove all files except .git
git rm -rf .

REM Copy web build
xcopy build\web . /E /I /Q /Y

REM Stage all files
git add .

REM Commit
git commit -m "Deploy FoodBridge v1.2.0 web build"

REM Force push to gh-pages
git push origin gh-pages --force

REM Switch back to main
git checkout main
```

---

### Method 3: Using Git Subtree (Recommended for CI/CD)

```bash
# From main branch
git subtree push --prefix build/web origin gh-pages
```

---

## ⚙️ GitHub Pages Configuration

After pushing to gh-pages branch:

1. Go to your repository on GitHub
2. Click **Settings** → **Pages** (in the sidebar)
3. Under **Source**:
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. Click **Save**
5. Wait 2-3 minutes for deployment

Your site will be available at:
```
https://YOUR-USERNAME.github.io/ASE-main/
```

---

## 📱 APK Distribution (Optional)

### Option 1: GitHub Releases

```bash
# Create a new release tag
git tag -a v1.2.0 -m "FoodBridge v1.2.0 - Production Release"

# Push tag to GitHub
git push origin v1.2.0
```

Then on GitHub:
1. Go to **Releases** → **Create a new release**
2. Choose tag: `v1.2.0`
3. Upload APK: `Desktop\FoodBridge\FoodBridge.apk`
4. Add release notes (see below)
5. Click **Publish release**

### Option 2: Add APK to Repository (Not Recommended - Large File)

```bash
# Only do this if you really need the APK in the repo
# Better to use GitHub Releases or external hosting

# Add APK to a releases folder
mkdir releases
cp ~/Desktop/FoodBridge/FoodBridge.apk releases/

git add releases/FoodBridge.apk
git commit -m "Add FoodBridge v1.2.0 APK"
git push origin main
```

---

## 🔄 Update Workflow (For Future Changes)

### 1. Make Changes
```bash
# Create feature branch (optional)
git checkout -b feature/new-feature

# Make your changes
# ... edit files ...

# Commit changes
git add .
git commit -m "Add new feature"

# Push to GitHub
git push origin feature/new-feature
```

### 2. Merge to Main
```bash
git checkout main
git merge feature/new-feature
git push origin main
```

### 3. Rebuild and Deploy

#### Android:
```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

#### Web:
```bash
flutter clean
flutter pub get
flutter build web --release --base-href /ASE-main/

# Deploy using script
deploy-web.bat  # Windows
./deploy-web.sh # Linux/Mac
```

---

## 📝 Suggested Release Notes Template

```markdown
# FoodBridge v1.2.0 - Complete Feature Release

## 🎉 What's New

### All 18 Requirements Implemented
- ✅ Single registration flow with OTP verification
- ✅ Partial claiming support
- ✅ In-app chat system
- ✅ Camera + gallery + voice input
- ✅ Nearby food discovery
- ✅ Non-food items support
- ✅ Complete notification system (10 types)
- ✅ Food request feature
- ✅ Expiry management & auto re-listing
- ✅ Food tracking with analytics
- ✅ Forecasting module
- ✅ Removed unnecessary NGO verification

## 📱 Downloads

### Android APK
- **Size**: 60.1 MB
- **Min SDK**: Android 5.0 (API 21)
- **Target SDK**: Android 14 (API 34)

[Download FoodBridge.apk](link-to-apk)

### Web App
Access directly at: https://YOUR-USERNAME.github.io/ASE-main/

## 📚 Documentation
- [Requirements Implementation Status](REQUIREMENTS_IMPLEMENTATION_STATUS.md)
- [Forecasting Module Documentation](FORECASTING_MODULE_DOCUMENTATION.md)
- [Food Tracking Documentation](FOOD_TRACKING_DOCUMENTATION.md)
- [Web Deployment Guide](WEB_DEPLOYMENT_GUIDE.md)

## 🔧 Technical Details
- **Flutter Version**: 3.x
- **Dart Version**: 3.x
- **Platform**: Android, Web
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)

## 🐛 Bug Fixes
- Fixed compilation errors in notification and request models
- Fixed empty state widget parameters
- Removed duplicate service methods

## 📊 Build Statistics
- APK Size: 60.1 MB
- Web Build: ~5-10 MB
- Icon Optimization: 98%+ reduction

---

**Full Changelog**: https://github.com/YOUR-USERNAME/ASE-main/compare/v1.1.0...v1.2.0
```

---

## 🔐 Important Notes

### Before Pushing:

1. **Review Changes**: Always check what you're committing
```bash
git status
git diff
```

2. **Check for Sensitive Data**: Ensure no API keys or secrets
```bash
# Check for common secret files
git status | grep -E "\.env|secrets|credentials"
```

3. **Test Locally**: Make sure builds work
```bash
flutter test  # Run tests if you have them
flutter build apk --release  # Test Android build
flutter build web --release  # Test web build
```

---

## 🌿 Branch Strategy

### Current Setup:
- `main` - Main development branch (source code)
- `gh-pages` - GitHub Pages deployment (web build only)

### Recommended for Team Development:
```
main
├── develop (integration branch)
├── feature/* (new features)
├── bugfix/* (bug fixes)
└── release/* (release preparation)
```

---

## 🚨 Common Issues & Solutions

### Issue: Web build 404 error
**Solution**: Ensure base-href matches repository name
```bash
flutter build web --release --base-href /ASE-main/
```

### Issue: GitHub Pages not updating
**Solution**: 
- Clear browser cache
- Wait 5 minutes
- Check gh-pages branch has new commit
- Verify GitHub Pages settings

### Issue: APK won't install
**Solution**:
- Ensure APK is signed (check build.gradle.kts)
- Enable "Install from Unknown Sources" on device
- Check min SDK matches device Android version

### Issue: Git push rejected
**Solution**:
```bash
# Pull latest changes first
git pull origin main --rebase

# Then push
git push origin main
```

---

## 📞 Quick Commands Cheat Sheet

```bash
# Status
git status                          # Check status
git log --oneline -5               # Recent commits

# Commit
git add .                           # Stage all
git commit -m "message"            # Commit
git push origin main               # Push

# Deploy Web
deploy-web.bat                     # Windows
./deploy-web.sh                    # Linux/Mac

# Branches
git branch                         # List branches
git checkout -b new-branch         # Create & switch
git checkout main                  # Switch to main

# Undo (careful!)
git reset --soft HEAD~1            # Undo last commit (keep changes)
git reset --hard HEAD~1            # Undo last commit (discard changes)
git checkout -- file.txt           # Discard file changes

# Remote
git remote -v                      # Show remotes
git remote add origin URL          # Add remote
```

---

## ✅ Deployment Checklist

Before deploying:
- [ ] All changes committed
- [ ] Code tested locally
- [ ] APK built successfully
- [ ] Web built successfully
- [ ] Documentation updated
- [ ] Version numbers updated
- [ ] No sensitive data in commits

For web deployment:
- [ ] Correct base-href set
- [ ] .nojekyll file present
- [ ] gh-pages branch created
- [ ] GitHub Pages enabled in settings
- [ ] Domain configured (if custom domain)

---

**Ready to Deploy!** 🚀

Choose your method above and follow the steps. The deploy scripts automate most of the process!
