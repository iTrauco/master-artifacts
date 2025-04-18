# NEW VERSION - Original backed up to: orig.artifact-manager.v3_2025-04-17_20-19.sh 
# Version date: Thu Apr 17 08:19:39 PM EDT 2025 
# Git branch: test-new 
# Last commit: debug: zsh shell syntax nuances breaking again 
#!/bin/sh
# Artifact manager - works in both Bash and Zsh

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

# Draw main menu
draw_menu() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║        ENHANCED ARTIFACT MANAGER v1.0          ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}[1]${NC} Sync all artifacts now"
  echo -e "${YELLOW}[2]${NC} Monitor artifacts in real-time"
  echo -e "${YELLOW}[3]${NC} Show artifact stats"
  echo -e "${YELLOW}[4]${NC} Create test artifacts"
  echo -e "${YELLOW}[5]${NC} Push to GitHub"
  echo -e "${YELLOW}[6]${NC} Manage projects"
  echo -e "${YELLOW}[q]${NC} Quit"
  echo ""
  echo -n -e "${CYAN}Select an option: ${NC}"
}

# Function to sync artifacts
sync_artifacts() {
  echo -e "${GREEN}Syncing artifacts from all repos...${NC}"
  
  for repo in $REPOS; do
    echo -e "${CYAN}Syncing $repo...${NC}"
    mkdir -p "$MASTER_REPO/projects/$repo"
    cp -r "$WORKSPACE/$repo/artifacts/"* "$MASTER_REPO/projects/$repo/" 2>/dev/null || true
  done
  
  cd "$MASTER_REPO" || exit
  BRANCH=$(git branch --show-current)
  git add projects/
  if ! git diff --staged --quiet; then
    git commit -m "Sync artifacts from all repos"
    git push origin "$BRANCH"
    echo -e "${GREEN}Changes committed and pushed${NC}"
  else
    echo -e "${YELLOW}No changes to commit${NC}"
  fi
  
  echo -e "${GREEN}Sync complete!${NC}"
  read -p "Press Enter to continue..."
}

# Show stats
show_stats() {
  echo -e "${PURPLE}ARTIFACT STATISTICS${NC}"
  
  for repo in $REPOS; do
    repo_count=$(find "$WORKSPACE/$repo/artifacts" -type f 2>/dev/null | wc -l | tr -d ' ')
    master_count=$(find "$MASTER_REPO/projects/$repo" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${YELLOW}$repo:${NC} $repo_count files"
    echo -e "${YELLOW}Master ($repo):${NC} $master_count files"
  done
  
  echo ""
  read -p "Press Enter to continue..."
}

# Create test artifacts
create_test() {
  echo -e "${PURPLE}Creating test artifacts...${NC}"
  
  echo -e "${YELLOW}Select repository:${NC}"
  i=1
  for repo in $REPOS; do
    echo -e "${YELLOW}[$i]${NC} $repo"
    i=$((i+1))
  done
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  
  echo -n -e "${CYAN}Select repo: ${NC}"
  read -r repo_choice
  
  if [ "$repo_choice" = "b" ]; then
    return
  fi
  
  # Get repo by index
  i=1
  for repo in $REPOS; do
    if [ "$i" = "$repo_choice" ]; then
      selected_repo=$repo
      break
    fi
    i=$((i+1))
  done
  
  if [ -n "$selected_repo" ]; then
    cd "$WORKSPACE/$selected_repo" || return
    echo "Test data $(date)" > "artifacts/test-$(date +%s).txt"
    echo -e "${GREEN}Test artifact created in $selected_repo${NC}"
  else
    echo -e "${RED}Invalid selection${NC}"
  fi
  
  read -p "Press Enter to continue..."
}

# Push changes to GitHub
push_to_github() {
  echo -e "${PURPLE}Push changes to GitHub${NC}"
  
  echo -e "${YELLOW}Select repository:${NC}"
  echo -e "${YELLOW}[0]${NC} Master Repository"
  
  i=1
  for repo in $REPOS; do
    echo -e "${YELLOW}[$i]${NC} $repo"
    i=$((i+1))
  done
  
  echo -e "${YELLOW}[a]${NC} All Repositories"
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  
  echo -n -e "${CYAN}Select option: ${NC}"
  read -r push_choice
  
  if [ "$push_choice" = "b" ]; then
    return
  fi
  
  if [ "$push_choice" = "0" ]; then
    cd "$MASTER_REPO" || return
    git add .
    git commit -m "Update artifacts $(date)"
    BRANCH=$(git branch --show-current)
    git push origin "$BRANCH"
    echo -e "${GREEN}Pushed Master Repo changes${NC}"
  elif [ "$push_choice" = "a" ]; then
    # Push all repos
    for repo in $REPOS; do
      cd "$WORKSPACE/$repo" || continue
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      echo -e "${GREEN}Pushed $repo changes${NC}"
    done
    
    cd "$MASTER_REPO" || return
    git add .
    git commit -m "Update artifacts $(date)"
    BRANCH=$(git branch --show-current)
    git push origin "$BRANCH"
    echo -e "${GREEN}Pushed all repos${NC}"
  else
    # Get repo by index
    i=1
    for repo in $REPOS; do
      if [ "$i" = "$push_choice" ]; then
        selected_repo=$repo
        break
      fi
      i=$((i+1))
    done
    
    if [ -n "$selected_repo" ]; then
      cd "$WORKSPACE/$selected_repo" || return
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      echo -e "${GREEN}Pushed $selected_repo changes${NC}"
    else
      echo -e "${RED}Invalid selection${NC}"
    fi
  fi
  
  read -p "Press Enter to continue..."
}

# Add new project
add_new_project() {
  echo -n -e "${CYAN}Enter new project repository name: ${NC}"
  read -r new_repo
  
  # Check if already exists
  for repo in $REPOS; do
    if [ "$repo" = "$new_repo" ]; then
      echo -e "${RED}Repository already exists in the tracking system${NC}"
      read -p "Press Enter to continue..."
      return
    fi
  done
  
  # Add to config
  REPOS="$REPOS $new_repo"
  echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
  echo "REPOS=\"$REPOS\"" >> "$CONFIG_FILE"
  . "$CONFIG_FILE"
  
  # Check if repo exists locally
  if [ ! -d "$WORKSPACE/$new_repo" ]; then
    echo -e "${YELLOW}Repository doesn't exist locally. Do you want to:${NC}"
    echo -e "${CYAN}[1]${NC} Clone from GitHub"
    echo -e "${CYAN}[2]${NC} Create locally"
    echo -e "${CYAN}[3]${NC} Skip this step"
    echo -n -e "${CYAN}Select option: ${NC}"
    read -r repo_option
    
    case $repo_option in
      1)
        echo -n -e "${CYAN}Enter GitHub URL: ${NC}"
        read -r github_url
        cd "$WORKSPACE" || return
        git clone "$github_url" "$new_repo"
        ;;
      2)
        mkdir -p "$WORKSPACE/$new_repo"
        cd "$WORKSPACE/$new_repo" || return
        git init
        ;;
      *)
        ;;
    esac
  fi
  
  # Set up artifacts directory and gitignore
  mkdir -p "$WORKSPACE/$new_repo/artifacts"
  
  # Setup gitignore
  if [ ! -f "$WORKSPACE/$new_repo/.gitignore" ]; then
    echo "artifacts/" > "$WORKSPACE/$new_repo/.gitignore"
  else
    if ! grep -q "artifacts/" "$WORKSPACE/$new_repo/.gitignore"; then
      echo "artifacts/" >> "$WORKSPACE/$new_repo/.gitignore"
    fi
  fi
  
  # Setup push script
  mkdir -p "$WORKSPACE/$new_repo/scripts"
  cat > "$WORKSPACE/$new_repo/scripts/push-artifacts.sh" << EOF
#!/bin/sh
# Path to repos
DOWNSTREAM_REPO="\$(pwd)"
MASTER_REPO="$MASTER_REPO"
REPO_NAME=\$(basename "\$DOWNSTREAM_REPO")

# Copy artifacts to master repo
mkdir -p "\$MASTER_REPO/projects/\$REPO_NAME"
cp -r "\$DOWNSTREAM_REPO/artifacts/"* "\$MASTER_REPO/projects/\$REPO_NAME/" 2>/dev/null || true

# Commit and push changes to master repo
cd "\$MASTER_REPO" || exit
BRANCH=\$(git branch --show-current)
git add "projects/\$REPO_NAME/"
git diff --staged --quiet || (git commit -m "Sync artifacts from \$REPO_NAME" && git push origin "\$BRANCH")
EOF
  chmod +x "$WORKSPACE/$new_repo/scripts/push-artifacts.sh"
  
  # Create Git hooks
  mkdir -p "$WORKSPACE/$new_repo/.git/hooks"
  
  # Create pre-commit hook
  cat > "$WORKSPACE/$new_repo/.git/hooks/pre-commit" << EOF
#!/bin/sh
# Check if any artifacts files were modified
if git diff --cached --name-only | grep -q "^artifacts/"; then
  echo "Artifacts changed, will sync to master repo after commit"
  echo "SYNC_ARTIFACTS=true" > .git/SYNC_ARTIFACTS
fi
exit 0
EOF
  
  # Create post-commit hook
  cat > "$WORKSPACE/$new_repo/.git/hooks/post-commit" << EOF
#!/bin/sh
if [ -f .git/SYNC_ARTIFACTS ]; then
  SYNC_ARTIFACTS=\$(grep -o "true" .git/SYNC_ARTIFACTS || echo "")
  if [ "\$SYNC_ARTIFACTS" = "true" ]; then
    echo "Syncing artifacts to master repo..."
    ./scripts/push-artifacts.sh
    rm .git/SYNC_ARTIFACTS
  fi
fi
EOF
  
  chmod +x "$WORKSPACE/$new_repo/.git/hooks/pre-commit" "$WORKSPACE/$new_repo/.git/hooks/post-commit"
  
  # Create directory in master repo
  mkdir -p "$MASTER_REPO/projects/$new_repo"
  
  echo -e "${GREEN}Project $new_repo added successfully${NC}"
  read -p "Press Enter to continue..."
}

# Remove project
remove_project() {
  echo -n -e "${CYAN}Enter number of project to remove: ${NC}"
  read -r remove_idx
  
  # Get repo by index
  i=1
  for repo in $REPOS; do
    if [ "$i" = "$remove_idx" ]; then
      removed_repo=$repo
      break
    fi
    i=$((i+1))
  done
  
  if [ -n "$removed_repo" ]; then
    # Remove from REPOS
    NEW_REPOS=""
    for repo in $REPOS; do
      if [ "$repo" != "$removed_repo" ]; then
        NEW_REPOS="$NEW_REPOS $repo"
      fi
    done
    REPOS=$(echo "$NEW_REPOS" | xargs)
    
    # Update config file
    echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
    echo "REPOS=\"$REPOS\"" >> "$CONFIG_FILE"
    . "$CONFIG_FILE"
    
    echo -e "${YELLOW}Do you want to remove the project directory from master repo?${NC}"
    echo -e "${CYAN}[y]${NC} Yes"
    echo -e "${CYAN}[n]${NC} No"
    echo -n -e "${CYAN}Select option: ${NC}"
    read -r remove_option
    
    if [ "$remove_option" = "y" ]; then
      rm -rf "$MASTER_REPO/projects/$removed_repo"
      cd "$MASTER_REPO" || return
      git add projects/
      git commit -m "Remove $removed_repo from tracking"
      BRANCH=$(git branch --show-current)
      git push origin "$BRANCH"
    fi
    
    echo -e "${GREEN}Project $removed_repo removed from tracking${NC}"
  else
    echo -e "${RED}Invalid selection${NC}"
  fi
  
  read -p "Press Enter to continue..."
}

# Manage projects menu
manage_projects() {
  while true; do
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            PROJECT MANAGEMENT                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Current Projects:${NC}"
    
    i=1
    for repo in $REPOS; do
      echo -e "${CYAN}[$i]${NC} $repo"
      i=$((i+1))
    done
    
    echo ""
    echo -e "${YELLOW}[a]${NC} Add new project"
    echo -e "${YELLOW}[r]${NC} Remove project"
    echo -e "${YELLOW}[b]${NC} Back to main menu"
    echo ""
    echo -n -e "${CYAN}Select an option: ${NC}"
    read -r choice
    
    case $choice in
      a)
        add_new_project
        ;;
      r)
        remove_project
        ;;
      b)
        return
        ;;
      *)
        echo -e "${RED}Invalid option${NC}"
        sleep 1
        ;;
    esac
  done
}

# Main loop
while true; do
  draw_menu
  read -r choice
  
  case $choice in
    1)
      sync_artifacts
      ;;
    2)
      cd "$MASTER_REPO" || exit
      ./scripts/monitor-artifacts.sh
      ;;
    3)
      show_stats
      ;;
    4)
      create_test
      ;;
    5)
      push_to_github
      ;;
    6)
      manage_projects
      ;;
    q)
      clear
      echo -e "${GREEN}Exiting Artifact Manager.${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option${NC}"
      sleep 1
      ;;
  esac
done