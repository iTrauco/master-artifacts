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
REPO1="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-1"
REPO2="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-2"

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
  echo -e "${YELLOW}[q]${NC} Quit"
  echo ""
  echo -n -e "${CYAN}Select an option: ${NC}"
}

# Function to sync artifacts
sync_artifacts() {
  echo -e "${GREEN}Syncing artifacts from all repos...${NC}"
  cd "$MASTER_REPO"
  ./scripts/sync-artifacts.sh
  echo -e "${GREEN}Sync complete!${NC}"
  read -p "Press Enter to continue..."
}

# Show stats
show_stats() {
  echo -e "${PURPLE}ARTIFACT STATISTICS${NC}"
  echo -e "${YELLOW}Repo 1:${NC} $(find $REPO1/artifacts -type f 2>/dev/null | wc -l) files"
  echo -e "${YELLOW}Repo 2:${NC} $(find $REPO2/artifacts -type f 2>/dev/null | wc -l) files"
  echo -e "${YELLOW}Master (downstream-1):${NC} $(find $MASTER_REPO/projects/downstream-1 -type f 2>/dev/null | wc -l) files"
  echo -e "${YELLOW}Master (downstream-2):${NC} $(find $MASTER_REPO/projects/downstream-2 -type f 2>/dev/null | wc -l) files"
  echo ""
  read -p "Press Enter to continue..."
}

# Create test artifacts
create_test() {
  echo -e "${PURPLE}Creating test artifacts...${NC}"
  echo -e "${YELLOW}[1]${NC} Create in Repo 1"
  echo -e "${YELLOW}[2]${NC} Create in Repo 2"
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  echo -n -e "${CYAN}Select repo: ${NC}"
  read -r repo_choice

  case $repo_choice in
    1)
      cd "$REPO1"
      echo "Test data $(date)" > artifacts/test-$(date +%s).txt
      echo -e "${GREEN}Test artifact created in Repo 1${NC}"
      ;;
    2)
      cd "$REPO2"
      echo "Test data $(date)" > artifacts/test-$(date +%s).txt
      echo -e "${GREEN}Test artifact created in Repo 2${NC}"
      ;;
    b|*)
      return
      ;;
  esac
  read -p "Press Enter to continue..."
}

# Push changes to GitHub
push_to_github() {
  echo -e "${PURPLE}Push changes to GitHub${NC}"
  echo -e "${YELLOW}[1]${NC} Push Repo 1"
  echo -e "${YELLOW}[2]${NC} Push Repo 2"
  echo -e "${YELLOW}[3]${NC} Push Master Repo"
  echo -e "${YELLOW}[4]${NC} Push All Repos"
  echo -e "${YELLOW}[b]${NC} Back to main menu"
  echo -n -e "${CYAN}Select option: ${NC}"
  read -r push_choice

  case $push_choice in
    1)
      cd "$REPO1"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      echo -e "${GREEN}Pushed Repo 1 changes${NC}"
      ;;
    2)
      cd "$REPO2"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      echo -e "${GREEN}Pushed Repo 2 changes${NC}"
      ;;
    3)
      cd "$MASTER_REPO"
      git add .
      git commit -m "Update artifacts $(date)" 
      git push origin test-new
      echo -e "${GREEN}Pushed Master Repo changes${NC}"
      ;;
    4)
      cd "$REPO1"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      
      cd "$REPO2"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin main
      
      cd "$MASTER_REPO"
      git add .
      git commit -m "Update artifacts $(date)"
      git push origin test-new
      echo -e "${GREEN}Pushed all repos${NC}"
      ;;
    b|*)
      return
      ;;
  esac
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
      "$MASTER_REPO/scripts/monitor-artifacts.sh"
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
