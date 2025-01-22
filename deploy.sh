#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Step 1: Build the project
echo "Installing dependencies..."
npm install
echo "Building the project..."
npm run build

echo "Git in progress"
git add .
git commit -m "New Build"
git push origin master
echo "Git work done"

# Step 2: Switch to gh-pages branch (create it if it doesn't exist locally)
echo "Switching to gh-pages branch..."
git fetch origin gh-pages:gh-pages
git checkout gh-pages 

echo "Pulling changes from master"
git pull origin master --no-ff
# Step 3: Remove old files in gh-pages (only the ones tracked in the branch)
echo "Cleaning old files in gh-pages..."
# git rm -rf .

# Step 4: Copy new dist content to the root of gh-pages
echo "Copying new build to gh-pages..."
rm -R node_modules
rm package-lock.json
cp -r ./dist/* .

# Step 5: Add and commit changes
echo "Committing new build..."
git add .
git commit -m "Deploy new build: $(date)"

# Step 6: Push changes to gh-pages
echo "Pushing to gh-pages branch..."
git push -u origin gh-pages

# Step 7: Switch back to main branch
echo "Switching back to main branch..."
git checkout master
npm install

echo "Deleting dist folder"
rm -rf dist

echo "Git in progress"
git add .
git commit -m "New Build"
git push origin master
echo "Git work done"

echo "Deployment complete!"