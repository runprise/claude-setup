#!/bin/bash
# Runprise Team Config Update Check (SessionStart hook)
# Compares local installed version with repo version (async, non-blocking)

INSTALLED_VERSION_FILE="$HOME/.claude/runprise-config-version"
REPO_DIR_FILE="$HOME/.claude/runprise-config-repo-path"
CACHE_FILE="/tmp/runprise-config-update.json"

# Read installed version
if [ ! -f "$INSTALLED_VERSION_FILE" ]; then
  exit 0
fi
INSTALLED=$(cat "$INSTALLED_VERSION_FILE" 2>/dev/null || echo "0.0.0")

# Read repo path
if [ ! -f "$REPO_DIR_FILE" ]; then
  exit 0
fi
REPO_DIR=$(cat "$REPO_DIR_FILE" 2>/dev/null || echo "")

if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
  exit 0
fi

# Check repo VERSION
REPO_VERSION_FILE="$REPO_DIR/VERSION"
if [ ! -f "$REPO_VERSION_FILE" ]; then
  exit 0
fi
LATEST=$(cat "$REPO_VERSION_FILE" 2>/dev/null || echo "0.0.0")

# Compare versions
if [ "$INSTALLED" != "$LATEST" ]; then
  cat > "$CACHE_FILE" <<EOF
{
  "update_available": true,
  "installed": "$INSTALLED",
  "latest": "$LATEST",
  "repo_dir": "$REPO_DIR",
  "checked": $(date +%s)
}
EOF
else
  # No update needed, clean up old cache
  rm -f "$CACHE_FILE"
fi
