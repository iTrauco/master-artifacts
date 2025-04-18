#!/bin/sh
# Add to master-artifacts/scripts/branch-artifact-manager.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
WORKSPACE="$HOME/Dev/artifacts-tracking"
CONFIG_FILE="$MASTER_REPO/.artifact-config"

# Load or create config
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
  echo "REPOS=\"downstream-artifacts-repo-1 downstream-artifacts-repo-2\"" >> "$CONFIG_FILE"
  . "$CONFIG_FILE"
fi

# Function to sync artifacts with branch awareness
sync_artifacts() {
  echo -e "${GREEN}Syncing artifacts from all repos with branch tracking...${NC}"
  
  for repo in $REPOS; do
    echo -e "${CYAN}Syncing $repo...${NC}"
    cd "$WORKSPACE/$repo" || continue
    
    # Get all branches
    BRANCHES=$(git branch | sed 's/^[ *]*//')
    
    # For each branch
    for branch in $BRANCHES; do
      echo -e "${YELLOW}Processing branch: $branch${NC}"
      
      # Create branch directory in master repo
      mkdir -p "$MASTER_REPO/projects/$repo/$branch"
      
      # Checkout branch temporarily
      git checkout "$branch" >/dev/null 2>&1
      
      # Copy artifacts
      cp -r "$WORKSPACE/$repo/artifacts/"* "$MASTER_REPO/projects/$repo/$branch/" 2>/dev/null || true
      
      # Add a branch identifier file
      echo "Branch: $branch" > "$MASTER_REPO/projects/$repo/$branch/.branch-info"
      echo "Last updated: $(date)" >> "$MASTER_REPO/projects/$repo/$branch/.branch-info"
      echo "Repo: $repo" >> "$MASTER_REPO/projects/$repo/$branch/.branch-info"
    done
    
    # Return to original branch
    git checkout - >/dev/null 2>&1
  done
  
  # Commit changes
  cd "$MASTER_REPO" || exit
  BRANCH=$(git branch --show-current)
  git add projects/
  if ! git diff --staged --quiet; then
    git commit -m "Sync artifacts from all repos with branch tracking"
    git push origin "$BRANCH"
    echo -e "${GREEN}Changes committed and pushed${NC}"
  else
    echo -e "${YELLOW}No changes to commit${NC}"
  fi
  
  echo -e "${GREEN}Branch-aware sync complete!${NC}"
  read -p "Press Enter to continue..."
}

# Update Git hooks for branch awareness
update_hooks() {
  for repo in $REPOS; do
    echo -e "${CYAN}Updating hooks for $repo...${NC}"
    
    # Update push-artifacts script
    mkdir -p "$WORKSPACE/$repo/scripts"
    cat > "$WORKSPACE/$repo/scripts/push-artifacts.sh" << EOF
#!/bin/sh
# Path to repos
DOWNSTREAM_REPO="\$(pwd)"
MASTER_REPO="$MASTER_REPO"
REPO_NAME=\$(basename "\$DOWNSTREAM_REPO")
BRANCH=\$(git branch --show-current)

# Create branch directory
mkdir -p "\$MASTER_REPO/projects/\$REPO_NAME/\$BRANCH"

# Copy artifacts to master repo
cp -r "\$DOWNSTREAM_REPO/artifacts/"* "\$MASTER_REPO/projects/\$REPO_NAME/\$BRANCH/" 2>/dev/null || true

# Add branch info
echo "Branch: \$BRANCH" > "\$MASTER_REPO/projects/\$REPO_NAME/\$BRANCH/.branch-info"
echo "Last updated: \$(date)" >> "\$MASTER_REPO/projects/\$REPO_NAME/\$BRANCH/.branch-info"
echo "Repo: \$REPO_NAME" >> "\$MASTER_REPO/projects/\$REPO_NAME/\$BRANCH/.branch-info"

# Commit and push changes to master repo
cd "\$MASTER_REPO" || exit
MASTER_BRANCH=\$(git branch --show-current)
git add "projects/\$REPO_NAME/\$BRANCH/"
git diff --staged --quiet || (git commit -m "Sync artifacts from \$REPO_NAME (\$BRANCH branch)" && git push origin "\$MASTER_BRANCH")
EOF
    chmod +x "$WORKSPACE/$repo/scripts/push-artifacts.sh"
    
    # Update existing hooks
    mkdir -p "$WORKSPACE/$repo/.git/hooks"
    cat > "$WORKSPACE/$repo/.git/hooks/post-commit" << EOF
#!/bin/sh
if [ -f .git/SYNC_ARTIFACTS ]; then
  SYNC_ARTIFACTS=\$(grep -o "true" .git/SYNC_ARTIFACTS || echo "")
  if [ "\$SYNC_ARTIFACTS" = "true" ]; then
    echo "Syncing artifacts to master repo (branch-aware)..."
    ./scripts/push-artifacts.sh
    rm .git/SYNC_ARTIFACTS
  fi
fi
EOF
    chmod +x "$WORKSPACE/$repo/.git/hooks/post-commit"
  done
  
  echo -e "${GREEN}Hooks updated for branch awareness!${NC}"
  read -p "Press Enter to continue..."
}

# Show branch-specific stats
show_branch_stats() {
  echo -e "${PURPLE}BRANCH-SPECIFIC ARTIFACT STATISTICS${NC}"
  
  for repo in $REPOS; do
    echo -e "${YELLOW}$repo:${NC}"
    
    cd "$WORKSPACE/$repo" 2>/dev/null || continue
    BRANCHES=$(git branch | sed 's/^[ *]*//')
    
    for branch in $BRANCHES; do
      local_count=$(find "$WORKSPACE/$repo/artifacts" -type f 2>/dev/null | wc -l | tr -d ' ')
      master_count=$(find "$MASTER_REPO/projects/$repo/$branch" -type f -not -name ".branch-info" 2>/dev/null | wc -l | tr -d ' ')
      
      echo -e "  ${CYAN}Branch $branch:${NC} $master_count files in master repo"
    done
    
    echo ""
  done
  
  read -p "Press Enter to continue..."
}

# Main menu function
show_menu() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║      BRANCH-AWARE ARTIFACT MANAGER v1.0        ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}[1]${NC} Sync artifacts across all branches"
  echo -e "${YELLOW}[2]${NC} Update Git hooks for branch awareness"
  echo -e "${YELLOW}[3]${NC} Show branch-specific artifact stats"
  echo -e "${YELLOW}[4]${NC} Return to main artifact manager"
  echo -e "${YELLOW}[q]${NC} Quit"
  echo ""
  echo -n -e "${CYAN}Select an option: ${NC}"
}

# Main loop
while true; do
  show_menu
  read -r choice
  
  case $choice in
    1)
      sync_artifacts
      ;;
    2)
      update_hooks
      ;;
    3)
      show_branch_stats
      ;;
    4)
      ./artifact-manager.sh
      exit 0
      ;;
    q)
      clear
      echo -e "${GREEN}Exiting Branch-Aware Artifact Manager.${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option${NC}"
      sleep 1
      ;;
  esac
done
