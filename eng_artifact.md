Artifact Tracking System
This document outlines a system that allows tracking artifacts from multiple repositories in a central location, even when those artifacts are excluded from version control in their source repositories.
System Overview
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Downstream    │  │ Downstream    │  │ More          │
│ Repo 1        │  │ Repo 2        │  │ Repos...      │
│ (artifacts/)  │  │ (artifacts/)  │  │ (artifacts/)  │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        │                  │                  │
        ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Master Artifacts Repository                       │
│                                                     │
│   ├── projects/                                     │
│   │   ├── downstream-1/                             │
│   │   ├── downstream-2/                             │
│   │   └── ...                                       │
│   │                                                 │
│   ├── scripts/                                      │
│   │   ├── sync-artifacts.sh                         │
│   │   ├── monitor-artifacts.sh                      │
│   │   └── artifact-manager.sh                       │
│   │                                                 │
│   └── .github/workflows/                            │
│       └── sync-artifacts.yml                        │
│                                                     │
└─────────────────────────────────────────────────────┘
Components

Master Repository: Central location that tracks all artifacts
Downstream Repositories: Projects where artifacts are generated but not tracked
Sync Scripts: Tools to copy artifacts between repositories
Git Hooks: Automation that syncs on commit
GitHub Actions: Periodic syncing via CI/CD
Management Tools: CLI interfaces for monitoring and management

Setup Instructions
1. Initial Setup
bash# Create workspace
mkdir -p ~/Dev/artifacts-tracking
cd ~/Dev/artifacts-tracking

# Clone repositories
git clone https://github.com/username/master-artifacts.git
git clone https://github.com/username/downstream-repo-1.git
git clone https://github.com/username/downstream-repo-2.git

# Create structure in master repo
cd master-artifacts
git checkout -b tracking-branch
mkdir -p projects/downstream-1
mkdir -p projects/downstream-2
2. Set Up Downstream Repos
In each downstream repo:
bash# Add artifacts to gitignore
echo "artifacts/" > .gitignore

# Create artifacts directory
mkdir -p artifacts

# Add basic project files
echo "# Project Name" > README.md
3. Create Sync Script in Master Repo
bashmkdir -p scripts
cat > scripts/sync-artifacts.sh << 'EOF'
#!/bin/bash

# Path to repositories
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO1="$HOME/Dev/artifacts-tracking/downstream-repo-1"
REPO2="$HOME/Dev/artifacts-tracking/downstream-repo-2"

# Copy artifacts from downstream repos to master repo
mkdir -p "$MASTER_REPO/projects/downstream-1"
mkdir -p "$MASTER_REPO/projects/downstream-2"

cp -r "$REPO1/artifacts/"* "$MASTER_REPO/projects/downstream-1/" 2>/dev/null
cp -r "$REPO2/artifacts/"* "$MASTER_REPO/projects/downstream-2/" 2>/dev/null

# Commit changes if there are any
cd "$MASTER_REPO"
CURRENT_BRANCH=$(git branch --show-current)
git add projects/
if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "Sync artifacts from downstream repos"
  git push origin $CURRENT_BRANCH
fi
EOF

chmod +x scripts/sync-artifacts.sh
4. Create Push Scripts in Each Downstream Repo
In each downstream repo, create:
bashmkdir -p scripts
cat > scripts/push-artifacts.sh << 'EOF'
#!/bin/bash

# Path to repos
DOWNSTREAM_REPO="$(pwd)"
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO_NAME=$(basename "$DOWNSTREAM_REPO")

# Copy artifacts to master repo
mkdir -p "$MASTER_REPO/projects/$REPO_NAME"
cp -r "$DOWNSTREAM_REPO/artifacts/"* "$MASTER_REPO/projects/$REPO_NAME/" 2>/dev/null

# Commit and push changes to master repo
cd "$MASTER_REPO"
BRANCH=$(git branch --show-current)
git add "projects/$REPO_NAME/"
git diff --staged --quiet || (git commit -m "Sync artifacts from $REPO_NAME" && git push origin $BRANCH)
EOF

chmod +x scripts/push-artifacts.sh
5. Set Up Git Hooks For Auto-Sync
In each downstream repo:
bashmkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Check if any artifacts files were modified
if git diff --cached --name-only | grep -q "^artifacts/"; then
  echo "Artifacts changed, will sync to master repo after commit"
  echo "SYNC_ARTIFACTS=true" > .git/SYNC_ARTIFACTS
fi
exit 0
EOF

cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash

if [ -f .git/SYNC_ARTIFACTS ]; then
  source .git/SYNC_ARTIFACTS
  if [ "$SYNC_ARTIFACTS" = "true" ]; then
    echo "Syncing artifacts to master repo..."
    ./scripts/push-artifacts.sh
    rm .git/SYNC_ARTIFACTS
  fi
fi
EOF

chmod +x .git/hooks/pre-commit .git/hooks/post-commit
6. Set Up GitHub Actions Workflow (Optional)
In the master repo:
bashmkdir -p .github/workflows
cat > .github/workflows/sync-artifacts.yml << 'EOF'
name: Sync Artifacts

on:
  workflow_dispatch:
  schedule:
    # Run every hour
    - cron: '0 * * * *'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: tracking-branch
          
      - name: Clone downstream repos
        run: |
          git clone https://github.com/username/downstream-repo-1.git repo1
          git clone https://github.com/username/downstream-repo-2.git repo2
          
      - name: Sync artifacts
        run: |
          # Create directories
          mkdir -p projects/downstream-1
          mkdir -p projects/downstream-2
          
          # Copy artifacts
          cp -r repo1/artifacts/* projects/downstream-1/ 2>/dev/null || true
          cp -r repo2/artifacts/* projects/downstream-2/ 2>/dev/null || true
          
      - name: Commit changes
        run: |
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git add projects/
          git diff --staged --quiet || git commit -m "Auto-sync artifacts from downstream repos"
          git push
EOF
7. Create Monitoring Script for Real-Time Updates
bashcat > scripts/monitor-artifacts.sh << 'EOF'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO1="$HOME/Dev/artifacts-tracking/downstream-repo-1"
REPO2="$HOME/Dev/artifacts-tracking/downstream-repo-2"

# Function to draw header
draw_header() {
  clear
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}     ARTIFACT TRACKING MONITOR${NC}"
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo ""
}

# Function to check repo status
check_repo_status() {
  local repo_path=$1
  local repo_name=$2
  
  cd "$repo_path"
  local branch=$(git branch --show-current)
  local last_commit=$(git log -1 --pretty=format:"%h - %s (%cr)")
  local artifact_count=$(find artifacts -type f 2>/dev/null | wc -l)
  
  echo -e "${YELLOW}$repo_name ${CYAN}[$branch]${NC}"
  echo -e "  ${GREEN}Last commit:${NC} $last_commit"
  echo -e "  ${GREEN}Artifacts:${NC} $artifact_count files"
  
  # Check for untracked artifacts
  local untracked=$(find artifacts -type f -newer "$(git rev-parse --git-dir)/index" 2>/dev/null | wc -l)
  if [ "$untracked" -gt 0 ]; then
    echo -e "  ${RED}Unsynced artifacts:${NC} $untracked files"
  fi
  echo ""
}

# Function to monitor changes
monitor_changes() {
  while true; do
    draw_header
    
    echo -e "${PURPLE}DOWNSTREAM REPOSITORIES${NC}"
    check_repo_status "$REPO1" "Repo 1"
    check_repo_status "$REPO2" "Repo 2"
    
    echo -e "${PURPLE}MASTER REPOSITORY${NC}"
    cd "$MASTER_REPO"
    local branch=$(git branch --show-current)
    local last_commit=$(git log -1 --pretty=format:"%h - %s (%cr)")
    echo -e "${YELLOW}Master Artifacts ${CYAN}[$branch]${NC}"
    echo -e "  ${GREEN}Last commit:${NC} $last_commit"
    echo -e "  ${GREEN}Downstream-1 artifacts:${NC} $(find projects/downstream-1 -type f 2>/dev/null | wc -l) files"
    echo -e "  ${GREEN}Downstream-2 artifacts:${NC} $(find projects/downstream-2 -type f 2>/dev/null | wc -l) files"
    
    echo ""
    echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
    echo -e "Press ${RED}Ctrl+C${NC} to exit monitoring"
    sleep 5
  done
}

# Main execution
draw_header
echo -e "${CYAN}Starting artifact monitoring...${NC}"
sleep 1
monitor_changes
EOF

chmod +x scripts/monitor-artifacts.sh
8. Create Enhanced Artifact Manager with Project Management
bashcat > scripts/artifact-manager.sh << 'EOF'
#!/bin/bash

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
  source "$CONFIG_FILE"
else
  echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
  echo "REPOS=(" >> "$CONFIG_FILE"
  echo "  \"downstream-repo-1\"" >> "$CONFIG_FILE"
  echo "  \"downstream-repo-2\"" >> "$CONFIG_FILE"
  echo ")" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
fi

# Draw menu
draw_menu() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║            ARTIFACT MANAGER v1.0               ║${NC}"
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
  
  # Dynamically generate sync script
  TMP_SCRIPT=$(mktemp)
  cat > "$TMP_SCRIPT" << INNEREOF
#!/bin/bash

# Path to repositories
MASTER_REPO="$MASTER_REPO"

INNEREOF

  # Add each repo path
  for repo in "${REPOS[@]}"; do
    echo "REPO_$(echo $repo | tr '-' '_')=\"$WORKSPACE/$repo\"" >> "$TMP_SCRIPT"
  done
  
  echo "" >> "$TMP_SCRIPT"
  
  # Add copy commands
  for repo in "${REPOS[@]}"; do
    repo_var="REPO_$(echo $repo | tr '-' '_')"
    echo "mkdir -p \"\$MASTER_REPO/projects/$repo\"" >> "$TMP_SCRIPT"
    echo "cp -r \"\${$repo_var}/artifacts/\"* \"\$MASTER_REPO/projects/$repo/\" 2>/dev/null" >> "$TMP_SCRIPT"
  done
  
  # Add commit logic
  cat >> "$TMP_SCRIPT" << INNEREOF
  
# Commit changes if there are any
cd "\$MASTER_REPO"
CURRENT_BRANCH=\$(git branch --show-current)
git add projects/
if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "Sync artifacts from all repos"
  git push origin \$CURRENT_BRANCH
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
    echo -e "${YELLOW}$repo:${NC} $(find $WORKSPACE/$repo/artifacts -type f 2>/dev/null | wc -l) files"
    echo -e "${YELLOW}Master ($repo):${NC} $(find $MASTER_REPO/projects/$repo -type f 2>/dev/null | wc -l) files"
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
  
  if [[ "$repo_choice" =~ ^[0-9]+$ ]] && [ "$repo_choice" -ge 1 ] && [ "$repo_choice" -le "${#REPOS[@]}" ]; then
    selected_repo="${REPOS[$((repo_choice-1))]}"
    cd "$WORKSPACE/$selected_repo"
    echo "Test data $(date)" > artifacts/test-$(date +%s).txt
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
    cd "$MASTER_REPO"
    git add .
    git commit -m "Update artifacts $(date)"
    BRANCH=$(git branch --show-current)
    git push origin $BRANCH
    echo -e "${GREEN}Pushed Master Repo changes${NC}"
  elif [[ "$push_choice" == "a" ]]; then
    # Push all repos
    for repo in "${REPOS[@]}"; do
      cd "$WORKSPACE/$repo"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      echo -e "${GREEN}Pushed $repo changes${NC}"
    done
    
    cd "$MASTER_REPO"
    git add .
    git commit -m "Update artifacts $(date)"
    BRANCH=$(git branch --show-current)
    git push origin $BRANCH
    echo -e "${GREEN}Pushed Master Repo changes${NC}"
  elif [[ "$push_choice" =~ ^[0-9]+$ ]] && [ "$push_choice" -ge 1 ] && [ "$push_choice" -le "${#REPOS[@]}" ]; then
    selected_repo="${REPOS[$((push_choice-1))]}"
    cd "$WORKSPACE/$selected_repo"
    git add .
    git commit -m "Update artifacts $(date)"
    git push origin main
    echo -e "${GREEN}Pushed $selected_repo changes${NC}"
  else
    echo -e "${RED}Invalid selection${NC}"
  fi
  
  read -p "Press Enter to continue..."
}

# Manage projects
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
        echo -n -e "${CYAN}Enter new project repository name: ${NC}"
        read -r new_repo
        
        # Check if already exists
        for repo in "${REPOS[@]}"; do
          if [ "$repo" == "$new_repo" ]; then
            echo -e "${RED}Repository already exists in the tracking system${NC}"
            read -p "Press Enter to continue..."
            continue 2
          fi
        done
        
        # Add to config
        REPOS+=("$new_repo")
        echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
        echo "REPOS=(" >> "$CONFIG_FILE"
        for repo in "${REPOS[@]}"; do
          echo "  \"$repo\"" >> "$CONFIG_FILE"
        done
        echo ")" >> "$CONFIG_FILE"
        
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
              cd "$WORKSPACE"
              git clone "$github_url" "$new_repo"
              ;;
            2)
              mkdir -p "$WORKSPACE/$new_repo"
              cd "$WORKSPACE/$new_repo"
              git init
              ;;
            *)
              ;;
          esac
        fi
        
        # Create artifacts directory
        mkdir -p "$WORKSPACE/$new_repo/artifacts"
        
        # Create .gitignore
        if [ ! -f "$WORKSPACE/$new_repo/.gitignore" ]; then
          echo "artifacts/" > "$WORKSPACE/$new_repo/.gitignore"
        else
          if ! grep -q "artifacts/" "$WORKSPACE/$new_repo/.gitignore"; then
            echo "artifacts/" >> "$WORKSPACE/$new_repo/.gitignore"
          fi
        fi
        
        # Create push script
        mkdir -p "$WORKSPACE/$new_repo/scripts"
        cat > "$WORKSPACE/$new_repo/scripts/push-artifacts.sh" << 'PUSHEOF'
#!/bin/bash

# Path to repos
DOWNSTREAM_REPO="$(pwd)"
MASTER_REPO="$HOME/Dev/artifacts-tracking/master-artifacts"
REPO_NAME=$(basename "$DOWNSTREAM_REPO")

# Copy artifacts to master repo
mkdir -p "$MASTER_REPO/projects/$REPO_NAME"
cp -r "$DOWNSTREAM_REPO/artifacts/"* "$MASTER_REPO/projects/$REPO_NAME/" 2>/dev/null

# Commit and push changes to master repo
cd "$MASTER_REPO"
BRANCH=$(git branch --show-current)
git add "projects/$REPO_NAME/"
git diff --staged --quiet || (git commit -m "Sync artifacts from $REPO_NAME" && git push origin $BRANCH)
PUSHEOF
        chmod +x "$WORKSPACE/$new_repo/scripts/push-artifacts.sh"
        
        # Create Git hooks
        mkdir -p "$WORKSPACE/$new_repo/.git/hooks"
        cat > "$WORKSPACE/$new_repo/.git/hooks/pre-commit" << 'PRECOMMITEOF'
#!/bin/bash

# Check if any artifacts files were modified
if git diff --cached --name-only | grep -q "^artifacts/"; then
  echo "Artifacts changed, will sync to master repo after commit"
  echo "SYNC_ARTIFACTS=true" > .git/SYNC_ARTIFACTS
fi
exit 0
PRECOMMITEOF
        
        cat > "$WORKSPACE/$new_repo/.git/hooks/post-commit" << 'POSTCOMMITEOF'
#!/bin/bash

if [ -f .git/SYNC_ARTIFACTS ]; then
  source .git/SYNC_ARTIFACTS
  if [ "$SYNC_ARTIFACTS" = "true" ]; then
    echo "Syncing artifacts to master repo..."
    ./scripts/push-artifacts.sh
    rm .git/SYNC_ARTIFACTS
  fi
fi
POSTCOMMITEOF
        
        chmod +x "$WORKSPACE/$new_repo/.git/hooks/pre-commit" "$WORKSPACE/$new_repo/.git/hooks/post-commit"
        
        # Create directory in master repo
        mkdir -p "$MASTER_REPO/projects/$new_repo"
        
        echo -e "${GREEN}Project $new_repo added successfully${NC}"
        read -p "Press Enter to continue..."
        ;;
      
      r)
        echo -n -e "${CYAN}Enter number of project to remove: ${NC}"
        read -r remove_idx
        
        if [[ "$remove_idx" =~ ^[0-9]+$ ]] && [ "$remove_idx" -ge 1 ] && [ "$remove_idx" -le "${#REPOS[@]}" ]; then
          removed_repo="${REPOS[$((remove_idx-1))]}"
          
          # Remove from config
          REPOS=("${REPOS[@]:0:$((remove_idx-1))}" "${REPOS[@]:$remove_idx}")
          echo "# Artifact Tracking Configuration" > "$CONFIG_FILE"
          echo "REPOS=(" >> "$CONFIG_FILE"
          for repo in "${REPOS[@]}"; do
            echo "  \"$repo\"" >> "$CONFIG_FILE"
          done
          echo ")" >> "$CONFIG_FILE"
          
          echo -e "${YELLOW}Do you want to remove the project directory from master repo?${NC}"
          echo -e "${CYAN}[y]${NC} Yes"
          echo -e "${CYAN}[n]${NC} No"
          echo -n -e "${CYAN}Select option: ${NC}"
          read -r remove_option
          
          if [[ "$remove_option" == "y" ]]; then
            rm -rf "$MASTER_REPO/projects/$removed_repo"
            cd "$MASTER_REPO"
            git add projects/
            git commit -m "Remove $removed_repo from tracking"
            BRANCH=$(git branch --show-current)
            git push origin $BRANCH
          fi
          
          echo -e "${GREEN}Project $removed_repo removed from tracking${NC}"
        else
          echo -e "${RED}Invalid selection${NC}"
        fi
        
        read -p "Press Enter to continue..."
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
      cd "$MASTER_REPO"
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
EOF

chmod +x scripts/artifact-manager.sh
Usage Instructions
Basic Usage

Set up master and downstream repos as shown in the setup instructions
Run the artifact manager for an interactive interface:
bashcd ~/Dev/artifacts-tracking/master-artifacts
./scripts/artifact-manager.sh

Add a new project repository:

Select "Manage projects" from the menu
Choose "Add new project"
Follow the prompts to connect a new repository


Monitor artifacts in real-time:
bash./scripts/monitor-artifacts.sh

Manually sync all artifacts:
bash./scripts/sync-artifacts.sh


Recommended Workflow

Create artifacts in your project repos as normal
Commit changes in downstream repos (hooks will auto-sync artifacts)
Use the monitor to verify artifacts are properly synced
Use the artifact manager for maintenance tasks

How It Works

Git Hooks: Pre-commit and post-commit hooks in downstream repos detect when artifacts change and run the push script.
Push Scripts: Each downstream repo has a script that copies artifacts to the master repo and commits them.
Sync Script: The master repo has a script that syncs all artifacts from all downstream repos.
Monitor: Shows real-time status of all artifacts across repos.
Manager: An interactive interface for managing the entire system.

Extending the System
To add support for additional repositories:

Use the Project Management interface in the artifact manager, or
Manually create the structure following the setup instructions

The configuration file .artifact-config in the master repo tracks all repositories in the system.
