# Master Artifacts Repository

This repository centrally tracks artifacts from multiple downstream repositories:
- [downstream-artifacts-repo-1](https://github.com/iTrauco/downstream-artifacts-repo-1)
- [downstream-artifacts-repo-2](https://github.com/iTrauco/downstream-artifacts-repo-2)

## How It Works

1. Artifacts in downstream repos are in `.gitignore` (not tracked by their repos)
2. Git hooks automatically copy artifacts to this central repository
3. GitHub Actions workflow syncs artifacts hourly
4. Manual sync via `scripts/sync-artifacts.sh`

## Setup Instructions

1. Clone this repo and downstream repos
2. Each downstream repo has `scripts/push-artifacts.sh` for manual syncing
3. Git hooks handle automatic syncing on commit
