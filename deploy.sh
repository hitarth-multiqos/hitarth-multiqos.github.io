#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
MASTER_BRANCH="master"
DEPLOY_BRANCH="gh-pages"
BUILD_DIR="./dist"

# Step 1: Build the project
echo "Installing dependencies..."
npm install

echo "Building the project..."
npm run build

# Step 2: Push latest changes to master
echo "Adding and committing changes in master..."
git checkout $MASTER_BRANCH
git add .
git commit -m "Prepare new build for deployment: $(date)" || echo "No changes to commit in master."
git push origin $MASTER_BRANCH

# Step 3: Switch to the deployment branch
echo "Switching to $DEPLOY_BRANCH branch..."
if git show-ref --verify --quiet refs/heads/$DEPLOY_BRANCH; then
  git checkout $DEPLOY_BRANCH
else
  git checkout -b $DEPLOY_BRANCH
fi

# Step 4: Sync with remote deployment branch
echo "Pulling latest changes from $DEPLOY_BRANCH..."
git pull origin $DEPLOY_BRANCH --rebase || echo "No changes to pull."

# Step 5: Move the build directory temporarily
echo "Temporarily moving build directory..."
mv $BUILD_DIR /tmp/dist_backup

# Step 6: Clean old deployment files
echo "Cleaning up old deployment files..."
git rm -rf . || echo "No old files to remove."

# Step 7: Restore the build directory and copy contents
echo "Restoring build directory..."
mv /tmp/dist_backup $BUILD_DIR
cp -r $BUILD_DIR/* .

# Step 8: Commit and push the new build
echo "Committing the new build to $DEPLOY_BRANCH..."
git add .
git commit -m "Deploy new build: $(date)" || echo "No changes to commit in $DEPLOY_BRANCH."

echo "Pushing to $DEPLOY_BRANCH branch..."
git push origin $DEPLOY_BRANCH

# Step 9: Switch back to master branch
echo "Switching back to $MASTER_BRANCH branch..."
git checkout $MASTER_BRANCH

# Optional: Cleanup build directory
echo "Cleaning up local build directory..."
rm -rf $BUILD_DIR

echo "Deployment completed successfully!"
