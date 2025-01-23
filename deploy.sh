#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
MASTER_BRANCH="master"
DEPLOY_BRANCH="gh-pages"
BUILD_DIR="./dist"
ENV_FILE=".env"
BASEURL_KEY="BASEURL"

# Step 1: Prompt for the new BASEURL
echo "🌐 Enter the new BASEURL (e.g., https://example.ngrok-free.app):"
read -r NEW_BASEURL

# Validate input
if [[ -z "$NEW_BASEURL" ]]; then
  echo "❌ Error: BASEURL cannot be empty."
  exit 1
fi

# Step 2: Update .env file with the new BASEURL
if [[ -f $ENV_FILE ]]; then
  echo "📝 Updating $BASEURL_KEY in $ENV_FILE..."
  if grep -q "^$BASEURL_KEY=" "$ENV_FILE"; then
    # Update the existing BASEURL key
    sed -i.bak "s|^$BASEURL_KEY=.*|$BASEURL_KEY=$NEW_BASEURL|" "$ENV_FILE" && rm "${ENV_FILE}.bak"
  else
    # Add the BASEURL key if it doesn't exist
    echo "$BASEURL_KEY=$NEW_BASEURL" >> "$ENV_FILE"
  fi
else
  echo "📄 $ENV_FILE not found. Creating it..."
  echo "$BASEURL_KEY=$NEW_BASEURL" > "$ENV_FILE"
fi

# Step 3: Build the project in the master branch
echo "🔄 Switching to $MASTER_BRANCH branch..."
git checkout $MASTER_BRANCH

echo "📦 Installing dependencies..."
npm install

echo "⚙️ Building the project..."
npm run build

# Step 4: Commit and push the build to the master branch
echo "📂 Adding and committing build in $MASTER_BRANCH..."
git add .
git commit -m "Prepare new build with updated BASEURL: $(date)" || echo "ℹ️ No changes to commit in $MASTER_BRANCH."
git push origin $MASTER_BRANCH

# Step 5: Switch to the gh-pages branch
echo "🔄 Switching to $DEPLOY_BRANCH branch..."
if git show-ref --verify --quiet refs/heads/$DEPLOY_BRANCH; then
  git checkout $DEPLOY_BRANCH
else
  git checkout -b $DEPLOY_BRANCH
fi

# Step 6: Sync with remote deployment branch
echo "⬇️ Pulling latest changes from $DEPLOY_BRANCH..."
git pull origin $DEPLOY_BRANCH --rebase || echo "ℹ️ No changes to pull."

# Step 7: Back up .gitignore before cleaning old files
echo "📂 Backing up .gitignore..."
if [[ -f .gitignore ]]; then
  cp .gitignore /tmp/.gitignore_backup
fi

# Step 8: Clean old deployment files
echo "🗑️ Cleaning up old deployment files..."
git rm -rf . || echo "ℹ️ No old files to remove."

# Step 9: Restore .gitignore
echo "♻️ Restoring .gitignore..."
if [[ -f /tmp/.gitignore_backup ]]; then
  mv /tmp/.gitignore_backup .gitignore
  git add .gitignore
fi

# Step 10: Copy the new dist folder from master branch
echo "📤 Copying new build from $MASTER_BRANCH..."
git checkout $MASTER_BRANCH -- $BUILD_DIR
cp -r $BUILD_DIR/* .
git reset HEAD $BUILD_DIR

# Step 11: Commit and push the new build to gh-pages
echo "📝 Committing new build to $DEPLOY_BRANCH..."
git add .
git commit -m "Deploy new build with updated BASEURL: $(date)" || echo "ℹ️ No changes to commit in $DEPLOY_BRANCH."

echo "🚀 Pushing to $DEPLOY_BRANCH branch..."
git push origin $DEPLOY_BRANCH

# Step 12: Switch back to the master branch
echo "🔄 Switching back to $MASTER_BRANCH branch..."
git checkout $MASTER_BRANCH

# Optional: Cleanup the dist folder in master
echo "🧹 Cleaning up local dist folder..."
rm -rf $BUILD_DIR

# Step 13: Commit and push the cleanup to the master branch
echo "📂 Adding and committing build cleanup in $MASTER_BRANCH..."
git add .
git commit -m "Cleaning up local dist folder: $(date)" || echo "ℹ️ No changes to commit in $MASTER_BRANCH."
git push origin $MASTER_BRANCH

# Completion message
echo "✅ Deployment completed successfully! 🎉"
