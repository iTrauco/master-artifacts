#!/bin/bash

# Path to repositories
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO1="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-1"
REPO2="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-2"

# Copy artifacts from downstream repos to master repo
mkdir -p "$MASTER_REPO/projects/downstream-1"
mkdir -p "$MASTER_REPO/projects/downstream-2"

cp -r "$REPO1/artifacts/"* "$MASTER_REPO/projects/downstream-1/" 2>/dev/null
cp -r "$REPO2/artifacts/"* "$MASTER_REPO/projects/downstream-2/" 2>/dev/null

# Commit changes if there are any
cd "$MASTER_REPO"
git add projects/
if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "Sync artifacts from downstream repos"
  git push
fi



# Add this near the bottom of the file:
CURRENT_BRANCH=$(git branch --show-current)
git commit -m "Sync artifacts from downstream repos"
git push origin $CURRENT_BRANCH
