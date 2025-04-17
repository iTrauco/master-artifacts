# Artifact Tracking System

## Commands
- `./scripts/artifact-manager.sh` - Interactive command center
- `./scripts/monitor-artifacts.sh` - Real-time monitoring dashboard
- `./scripts/sync-artifacts.sh` - Manual sync from all repos

## Automation
- Git hooks automatically sync on commit
- GitHub Actions sync hourly
- Manual sync via manager interface

## Adding New Repositories
1. Create directory in master repo: `projects/new-repo-name`
2. Copy push-artifacts.sh to new repo
3. Set up Git hooks in new repo
