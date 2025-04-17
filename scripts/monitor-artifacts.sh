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
REPO1="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-1"
REPO2="$HOME/Dev/artifacts-tracking/downstream-artifacts-repo-2"

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
