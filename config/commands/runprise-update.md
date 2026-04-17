Update the Runprise Claude Code Team Configuration to the latest version.

## Steps

1. Read the repo path from `~/.claude/runprise-config-repo-path`. If missing, use `~/Development/runprise-claude-setup`.
2. If the repo directory does not exist, inform the user and show the install one-liner:
   ```
   curl -fsSL https://raw.githubusercontent.com/runprise/claude-setup/main/install.sh | bash
   ```
3. Read the currently installed version:
   ```bash
   cat ~/.claude/runprise-config-version
   ```
4. Fetch latest:
   ```bash
   git -C <repo_dir> fetch --all --tags --quiet
   git -C <repo_dir> reset --hard origin/main --quiet
   ```
5. Get the new version from VERSION file:
   ```bash
   cat <repo_dir>/VERSION
   ```
6. Show the changelog between old and new version:
   ```bash
   git -C <repo_dir> log --pretty=format:"- %s" v<old_version>..HEAD -- ':!VERSION'
   ```
   Format as a readable changelog grouped by type if possible (feat, fix, docs, chore).
7. Run the update script (re-syncs Flagbit-Upstream, non-interactive):
   ```bash
   <repo_dir>/update.sh
   ```
8. Clean up the update cache:
   ```bash
   rm -f /tmp/runprise-config-update.json
   ```
9. Show the user a summary:
   - Version change (e.g. 1.1.0 -> 1.2.0)
   - The changelog from step 6
   - "Please restart Claude Code to load the new configuration."
