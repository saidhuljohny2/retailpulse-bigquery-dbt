#!/usr/bin/env bash
# Create GitHub repo and push RetailPulse code.
# Run from project root: bash scripts/push_to_github.sh

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
REPO_NAME="retailpulse-bigquery-dbt"
DESCRIPTION="Production-style e-commerce analytics platform using Google BigQuery and dbt Core"

cd "$(dirname "$0")/.."

# Ensure gh is available
if ! command -v gh &>/dev/null; then
  echo "Installing gh to ~/.local/bin..."
  mkdir -p ~/.local/bin
  ARCH=$(uname -m)
  [[ "$ARCH" == "arm64" ]] && GH_ARCH="macOS_arm64" || GH_ARCH="macOS_amd64"
  curl -sL "https://github.com/cli/cli/releases/download/v2.69.0/gh_2.69.0_${GH_ARCH}.zip" -o /tmp/gh.zip
  unzip -qo /tmp/gh.zip -d /tmp
  cp "/tmp/gh_2.69.0_${GH_ARCH}/bin/gh" ~/.local/bin/gh
  chmod +x ~/.local/bin/gh
fi

# Authenticate if needed
if ! gh auth status &>/dev/null; then
  echo ""
  echo "=== GitHub CLI login required ==="
  echo "A browser window will open. Approve access for gh."
  echo ""
  gh auth login --hostname github.com --git-protocol https --web
fi

# Fix git dir if using workaround gitdir
if [[ -f .git && ! -d .git ]]; then
  GITDIR=$(grep gitdir .git | awk '{print $2}')
  export GIT_DIR="$GITDIR"
  export GIT_WORK_TREE="$(pwd)"
fi

# Init git if needed
if ! git rev-parse --git-dir &>/dev/null; then
  git init -b main
  git add -A
  git commit -m "Initial commit: RetailPulse BigQuery + dbt analytics platform"
elif ! git rev-parse HEAD &>/dev/null; then
  git add -A
  git commit -m "Initial commit: RetailPulse BigQuery + dbt analytics platform"
fi

# Create repo and push
echo "Creating GitHub repo: $REPO_NAME"
gh repo create "$REPO_NAME" \
  --public \
  --description "$DESCRIPTION" \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "Done! Repo URL:"
gh repo view --web --json url -q .url
