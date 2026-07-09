#!/bin/bash
# FoodBridge Web Deployment Script for GitHub Pages

echo "🚀 FoodBridge Web Deployment Script"
echo "===================================="
echo ""

# Check if build/web exists
if [ ! -d "build/web" ]; then
    echo "❌ Error: build/web directory not found!"
    echo "Please run: flutter build web --release --base-href /ASE-main/"
    exit 1
fi

echo "📦 Found web build directory"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"
echo ""

# Confirm deployment
read -p "Deploy to GitHub Pages? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

echo "🔄 Starting deployment..."
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "📁 Created temp directory: $TEMP_DIR"

# Copy build files
cp -r build/web/* "$TEMP_DIR/"
echo "✅ Copied build files"

# Switch to gh-pages branch
git checkout gh-pages 2>/dev/null || git checkout -b gh-pages
echo "✅ Switched to gh-pages branch"

# Remove old files (except .git)
git rm -rf . 2>/dev/null
echo "✅ Cleaned old files"

# Copy new build
cp -r "$TEMP_DIR"/* .
echo "✅ Copied new build"

# Clean up temp directory
rm -rf "$TEMP_DIR"
echo "✅ Cleaned temp directory"

# Add all files
git add .
echo "✅ Staged files"

# Commit
COMMIT_MSG="Deploy FoodBridge v1.2.0 - $(date +'%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"
echo "✅ Created commit"

# Push
git push origin gh-pages --force
echo "✅ Pushed to GitHub Pages"

# Switch back to original branch
git checkout "$CURRENT_BRANCH"
echo "✅ Switched back to $CURRENT_BRANCH"

echo ""
echo "🎉 Deployment complete!"
echo "📍 Your app will be available at:"
echo "   https://YOUR-USERNAME.github.io/ASE-main/"
echo ""
echo "⏱️  GitHub Pages may take 2-3 minutes to update"
