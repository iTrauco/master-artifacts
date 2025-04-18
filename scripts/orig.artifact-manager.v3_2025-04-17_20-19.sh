# Original file: artifact-manager.sh 
# Version date: Thu Apr 17 08:19:39 PM EDT 2025 
# Git branch: test-new 
# Last commit: debug: zsh shell syntax nuances breaking again 

# NEW VERSION - Original backed up to: orig.artifact-manager.v2_2025-04-17_20-08.sh 
# Version date: Thu Apr 17 08:08:21 PM EDT 2025 
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
  echo "REPOS=(downstream-artifacts-repo-1 downstream-artifacts-repo-2)" >> "$CONFIG_FILE"
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

# Update config file - compatible with both shells
update_config() {
  echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
  echo -n "REPOS=(" > "$CONFIG_FILE"
  for repo in "${REPOS[@]}"; do
    echo -n "$repo " >> "$CONFIG_FILE"
  done
  echo ")" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
}

# Setup gitignore
setup_gitignore() {
  local repo=$1
  if [[ ! -f "$WORKSPACE/$repo/.gitignore" ]]; then
    echo "artifacts/" > "$WORKSPACE/$repo/.gitignore"
  else
    if ! grep -q "artifacts/" "$WORKSPACE/$repo/.gitignore"; then
      echo "artifacts/" >> "$WORKSPACE/$repo/.gitignore"
    fi
  fi
}

# Setup push script
setup_push_script() {
  local repo=$1
  mkdir -p "$WORKSPACE/$repo/scripts"
  cat > "$WORKSPACE/$repo/scripts/push-artifacts.sh" << 'PUSHEOF'
#!/bin/bash

# Path to repos
DOWNSTREAM_REPO="$(pwd)"
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO_NAME=$(basename "$DOWNSTREAM_REPO")

# Copy artifacts to master repo
mkdir -p "$MASTER_REPO/projects/$REPO_NAME"
cp -r "$DOWNSTREAM_REPO/artifacts/"* "$MASTER_REPO/projects/$REPO_NAME/" 2>/dev/null || true

# Commit and push changes to master repo
cd "$MASTER_REPO" || return
BRANCH=$(git branch --show-current)
git add "projects/$REPO_NAME/"
git diff --staged --quiet || (git commit -m "Sync artifacts from $REPO_NAME" && git push origin "$BRANCH")
PUSHEOF
  chmod +x "$WORKSPACE/$repo/scripts/push-artifacts.sh"
}

# Replace this entire function
setup_git_hooks() {
  local repo=$1
  mkdir -p "$WORKSPACE/$repo/.git/hooks"
  
  # Create pre-commit hook with echo commands instead of heredoc
  echo '#!/bin/sh' > "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo '# Check if any artifacts files were modified' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo 'if git diff --cached --name-only | grep -q "^artifacts/"; then' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo '  echo "Artifacts changed, will sync to master repo after commit"' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo '  echo "SYNC_ARTIFACTS=true" > .git/SYNC_ARTIFACTS' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo 'fi' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  echo 'exit 0' >> "$WORKSPACE/$repo/.git/hooks/pre-commit"
  
  # Create post-commit hook with echo commands
  echo '#!/bin/sh' > "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo 'if [ -f .git/SYNC_ARTIFACTS ]; then' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '  SYNC_ARTIFACTS=$(grep -o "true" .git/SYNC_ARTIFACTS || echo "")' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '  if [ "$SYNC_ARTIFACTS" = "true" ]; then' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '    echo "Syncing artifacts to master repo..."' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '    ./scripts/push-artifacts.sh' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '    rm .git/SYNC_ARTIFACTS' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo '  fi' >> "$WORKSPACE/$repo/.git/hooks/post-commit"
  echo 'fi' >> "$WORKSPACE/$repo/.git/hooks/post-commit"

  chmod +x "$WORKSPACE/$repo/.git/hooks/pre-commit" "$WORKSPACE/$repo/.git/hooks/post-commit"
}

# Add new project function
add_new_project() {
  echo -n -e "${CYAN}Enter new project repository name: ${NC}"
  read -r new_repo
  
  # Check if already exists
  for repo in "${REPOS[@]}"; do
    if [[ "$repo" == "$new_repo" ]]; then
      echo -e "${RED}Repository already exists in the tracking system${NC}"
      read -p "Press Enter to continue..."
      return
    fi
  done
  
  # Add to config - compatible with both shells
  REPOS+=("$new_repo")
  update_config
  
  # Check if repo exists locally
  if [[ ! -d "$WORKSPACE/$new_repo" ]]; then
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
  setup_gitignore "$new_repo"
  
  # Create push script
  setup_push_script "$new_repo"
  
  # Create Git hooks
  setup_git_hooks "$new_repo"
  
  # Create directory in master repo
  mkdir -p "$MASTER_REPO/projects/$new_repo"
  
  echo -e "${GREEN}Project $new_repo added successfully${NC}"
  read -p "Press Enter to continue..."
}

# Remove project function
remove_project() {
  echo -n -e "${CYAN}Enter number of project to remove: ${NC}"
  read -r remove_idx
  
  if [[ "$remove_idx" =~ ^[0-9]+$ ]] && [[ "$remove_idx" -ge 1 ]] && [[ "$remove_idx" -le "${#REPOS[@]}" ]]; then
    removed_repo="${REPOS[$((remove_idx-1))]}"
    
    # Remove from config - compatible with both shells
    new_repos=()
    for i in "${!REPOS[@]}"; do
      if [[ "$i" -ne "$((remove_idx-1))" ]]; then
        new_repos+=("${REPOS[$i]}")
      fi
    done
    REPOS=("${new_repos[@]}")
    update_config
    
    echo -e "${YELLOW}Do you want to remove the project directory from master repo?${NC}"
    echo -e "${CYAN}[y]${NC} Yes"
    echo -e "${CYAN}[n]${NC} No"
    echo -n -e "${CYAN}Select option: ${NC}"
    read -r remove_option
    
    if [[ "$remove_option" == "y" ]]; then
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
    for i in "${!REPOS[@]}"; do
      echo -e "${CYAN}[$((i+1))]${NC} ${REPOS[$i]}"
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

# Function to sync artifacts
sync_artifacts() {
  echo -e "${GREEN}Syncing artifacts from all repos...${NC}"
  
  # Dynamically generate sync script
  TMP_SCRIPT=$(mktemp)
  cat > "$TMP_SCRIPT" << EOF
#!/bin/bash

# Path to repositories
MASTER_REPO="$MASTER_REPO"

EOF

  # Add copy commands for each repo
  for repo in "${REPOS[@]}"; do
    echo "# Sync $repo" >> "$TMP_SCRIPT"
    echo "mkdir -p \"\$MASTER_REPO/projects/$repo\"" >> "$TMP_SCRIPT"
    echo "cp -r \"$WORKSPACE/$repo/artifacts/\"* \"\$MASTER_REPO/projects/$repo/\" 2>/dev/null || true" >> "$TMP_SCRIPT"
  done
  
  # Add commit logic
  cat >> "$TMP_SCRIPT" << 'INNEREOF'
  
# Commit changes if there are any
cd "$MASTER_REPO" || exit
CURRENT_BRANCH=$(git branch --show-current)
git add projects/
if ! git diff --staged --quiet; then
  git commit -m "Sync artifacts from all repos"
  git push origin "$CURRENT_BRANCH"
fi
INNEREOF

  # Execute script
  bash "$TMP_SCRIPT"
  rm "$TMP_SCRIPT"
  
  echo -e "${GREEN}Sync complete!${NC}"
  read -p "Press Enter to continue..."
}

# Show stats
show_stats() {
  echo -e "${PURPLE}ARTIFACT STATISTICS${NC}"
  
  for repo in "${REPOS[@]}"; do
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
  for i in "${!REPOS[@]}"; do
    echo -e "${YELLOW}[$((i+1))]${NC} ${REPOS[$i]}"
  done
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  
  echo -n -e "${CYAN}Select repo: ${NC}"
  read -r repo_choice
  
  if [[ "$repo_choice" == "b" ]]; then
    return
  fi
  
  if [[ "$repo_choice" =~ ^[0-9]+$ ]] && [[ "$repo_choice" -ge 1 ]] && [[ "$repo_choice" -le "${#REPOS[@]}" ]]; then
    selected_repo="${REPOS[$((repo_choice-1))]}"
    cd "$WORKSPACE/$selected_repo" || return
    echo "Test data $(date)" > "artifacts/test-$(date +%s).txt"
    echo -e "${GREEN}Test artifact created in $selected_repo${NC}"
  else
    echo -e "${RED}Invalid selection${NC}"
  fi
  
# Function to sync artifacts
sync_artifacts() {
  echo -e "${GREEN}Syncing artifacts from all repos...${NC}"
  
  # Generate sync script for space-separated list
  TMP_SCRIPT=$(mktemp)
  cat > "$TMP_SCRIPT" << EOF
#!/bin/sh

# Path to repositories
MASTER_REPO="$MASTER_REPO"

EOF

  for repo in $REPOS; do
    echo "mkdir -p \"\$MASTER_REPO/projects/$repo\"" >> "$TMP_SCRIPT"
    echo "cp -r \"$WORKSPACE/$repo/artifacts/\"* \"\$MASTER_REPO/projects/$repo/\" 2>/dev/null || true" >> "$TMP_SCRIPT"
  done
  
  cat >> "$TMP_SCRIPT" << 'INNEREOF'
cd "$MASTER_REPO" || exit
BRANCH=$(git branch --show-current)
git add projects/
git diff --staged --quiet || (git commit -m "Sync artifacts" && git push origin "$BRANCH")
INNEREOF

  sh "$TMP_SCRIPT"
  rm "$TMP_SCRIPT"
  
  echo -e "${GREEN}Sync complete!${NC}"
  read -p "Press Enter to continue..."
}

# Push changes to GitHub
push_to_github() {
  echo -e "${PURPLE}Push changes to GitHub${NC}"
  
  echo -e "${YELLOW}Select repository:${NC}"
  echo -e "${YELLOW}[0]${NC} Master Repository"
  for i in "${!REPOS[@]}"; do
    echo -e "${YELLOW}[$((i+1))]${NC} ${REPOS[$i]}"
  done
  echo -e "${YELLOW}[a]${NC} All Repositories"
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  
  echo -n -e "${CYAN}Select option: ${NC}"
  read -r push_choice
  
  if [[ "$push_choice" == "b" ]]; then
    return
  fi
  
  if [[ "$push_choice" == "0" ]]; then
    cd "$MASTER_REPO" || return
    git add .
    git commit -m "Update artifacts $(date)"
    BRANCH=$(git branch --show-current)
    git push origin "$BRANCH"
    echo -e "${GREEN}Pushed Master Repo changes${NC}"
  elif [[ "$push_choice" == "a" ]]; then
    # Push all repos
    for repo in "${REPOS[@]}"; do
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
  elif [[ "$push_choice" =~ ^[0-9]+$ ]] && [[ "$push_choice" -ge 1 ]] && [[ "$push_choice" -le "${#REPOS[@]}" ]]; then
    selected_repo="${REPOS[$((push_choice-1))]}"
    cd "$WORKSPACE/$selected_repo" || return
    git add .
    git commit -m "Update artifacts $(date)"
    git push origin main
    echo -e "${GREEN}Pushed $selected_repo changes${NC}"
  else
    echo -e "${RED}Invalid selection${NC}"
  fi
  
  read -p "Press Enter to continue..."
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
