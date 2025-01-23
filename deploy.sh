#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
MASTER_BRANCH="master"
DEPLOY_BRANCH="gh-pages"
BUILD_DIR="./dist"

# Step 1: Build the project in the master branch
echo "Switching to $MASTER_BRANCH branch..."
git checkout $MASTER_BRANCH

echo "Installing dependencies..."
npm install

echo "Building the project..."
npm run build

# Step 2: Commit and push the build to the master branch
echo "Adding and committing build in $MASTER_BRANCH..."
git add .
git commit -m "Prepare new build for deployment: $(date)" || echo "No changes to commit in $MASTER_BRANCH."
git push origin $MASTER_BRANCH

# Step 3: Switch to the gh-pages branch
echo "Switching to $DEPLOY_BRANCH branch..."
if git show-ref --verify --quiet refs/heads/$DEPLOY_BRANCH; then
  git checkout $DEPLOY_BRANCH
else
  git checkout -b $DEPLOY_BRANCH
fi

# Step 4: Sync with remote deployment branch
echo "Pulling latest changes from $DEPLOY_BRANCH..."
git pull origin $DEPLOY_BRANCH --rebase || echo "No changes to pull."

# Step 5: Back up .gitignore before cleaning old files
echo "Backing up .gitignore..."
if [ -f .gitignore ]; then
  cp .gitignore /tmp/.gitignore_backup
fi

# Step 6: Clean old deployment files
echo "Cleaning up old deployment files..."
git rm -rf . || echo "No old files to remove."

# Step 7: Restore .gitignore
echo "Restoring .gitignore..."
if [ -f /tmp/.gitignore_backup ]; then
  mv /tmp/.gitignore_backup .gitignore
  git add .gitignore
fi

# Step 8: Copy the new dist folder from master branch
echo "Copying new build from $MASTER_BRANCH..."
git checkout $MASTER_BRANCH -- $BUILD_DIR
cp -r $BUILD_DIR/* .
git reset HEAD $BUILD_DIR

# Step 9: Commit and push the new build to gh-pages
echo "Committing new build to $DEPLOY_BRANCH..."
git add .
git commit -m "Deploy new build: $(date)" || echo "No changes to commit in $DEPLOY_BRANCH."

echo "Pushing to $DEPLOY_BRANCH branch..."
git push origin $DEPLOY_BRANCH

# Step 10: Switch back to the master branch
echo "Switching back to $MASTER_BRANCH branch..."
git checkout $MASTER_BRANCH

# Step 11 (Optional): Cleanup the dist folder in master
echo "Cleaning up local dist folder..."
rm -rf $BUILD_DIR

# Step 12: Commit and push the build to the master branch
echo "Adding and committing build in $MASTER_BRANCH..."
git add .
git commit -m "Removing dist folder $(date)" || echo "No changes to commit in $MASTER_BRANCH."
git push origin $MASTER_BRANCH

echo "Deployment completed successfully!"
