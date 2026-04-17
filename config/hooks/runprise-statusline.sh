#!/bin/bash
# Runprise Statusline Wrapper
# Wraps Claude HUD and prepends an update indicator when available.
# Works in both expanded and compact mode.
#
# Flow: Claude Code -> stdin -> this script -> Claude HUD -> stdout + update prefix

CACHE="/tmp/runprise-config-update.json"

# Find Claude HUD installation
HUD_DIR=$(find "$HOME/.claude/plugins/cache/claude-hud/claude-hud" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)

# Read stdin (Claude Code sends JSON)
INPUT=$(cat)

# Run Claude HUD if available
HUD_OUTPUT=""
if [ -n "$HUD_DIR" ] && [ -f "$HUD_DIR/dist/index.js" ]; then
  HUD_OUTPUT=$(echo "$INPUT" | node "$HUD_DIR/dist/index.js" 2>/dev/null)
fi

# Prepend update indicator if update available
if [ -f "$CACHE" ]; then
  echo -e "\033[33m⬆ /runprise-update\033[0m"
fi

# Output Claude HUD lines
if [ -n "$HUD_OUTPUT" ]; then
  echo "$HUD_OUTPUT"
elif [ -z "$HUD_OUTPUT" ] && [ -z "$HUD_DIR" ]; then
  # Fallback: minimal statusline if Claude HUD is not installed
  echo "[Runprise]"
fi
