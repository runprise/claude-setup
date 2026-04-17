#!/usr/bin/env node
/**
 * merge-settings.js — Intelligent JSON merge for Claude settings
 *
 * Merges team settings into a user's existing settings file with
 * field-specific strategies:
 *
 *   env:                    deep merge, team values set, user values preserved
 *   hooks:                  append, deduplicate by command string
 *   enabledPlugins:         object merge, team plugins enabled, existing not disabled
 *   extraKnownMarketplaces: object merge
 *   permissions:            NEVER touch
 *   statusLine:             only set if empty/missing
 *   effortLevel:            only set if not configured
 *
 * Usage: node merge-settings.js <team-file> <user-file>
 *
 * Creates a backup of user-file before writing (.bak).
 */

const fs = require("fs");
const path = require("path");

// -------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------

function parseJSON(filePath) {
  const raw = fs.readFileSync(filePath, "utf-8");
  try {
    return JSON.parse(raw);
  } catch (err) {
    console.error(`Error: ${filePath} is not valid JSON.`);
    console.error(err.message);
    process.exit(1);
  }
}

/**
 * Deep merge two plain objects. Values from `source` are set only when the
 * key does not yet exist in `target`. Existing target values are preserved.
 */
function deepMergePreserve(target, source) {
  const result = { ...target };
  for (const [key, value] of Object.entries(source)) {
    if (!(key in result)) {
      result[key] = value;
    } else if (
      typeof result[key] === "object" &&
      result[key] !== null &&
      !Array.isArray(result[key]) &&
      typeof value === "object" &&
      value !== null &&
      !Array.isArray(value)
    ) {
      result[key] = deepMergePreserve(result[key], value);
    }
    // Otherwise: user value wins
  }
  return result;
}

/**
 * Extract all command strings from a hooks event array.
 * Claude Code hooks format: event -> [ { matcher?, hooks: [ {type, command} ] } ]
 */
function extractHookCommands(eventArray) {
  const commands = new Set();
  if (!Array.isArray(eventArray)) return commands;

  for (const group of eventArray) {
    if (group.hooks && Array.isArray(group.hooks)) {
      for (const hook of group.hooks) {
        if (hook.command) commands.add(hook.command);
      }
    }
  }
  return commands;
}

/**
 * Merge hooks for all events. Team hook groups are appended only if none
 * of their command strings already exist in the user's hooks.
 * Both team and user hooks use Claude Code's nested format:
 *   [ { matcher?, hooks: [ { type, command, async? } ] } ]
 */
function mergeHooks(userHooks, teamHooks) {
  if (!teamHooks) return userHooks;

  const result = { ...userHooks };

  for (const [event, teamGroups] of Object.entries(teamHooks)) {
    if (!Array.isArray(teamGroups)) continue;

    const userGroups = result[event] || [];
    const existingCommands = extractHookCommands(userGroups);

    const toAdd = [];
    for (const group of teamGroups) {
      if (!group.hooks || !Array.isArray(group.hooks)) continue;

      // Collect commands in this group
      const groupCommands = group.hooks
        .filter((h) => h.command)
        .map((h) => h.command);

      // Only add if none of the commands already exist
      const allNew = groupCommands.every((cmd) => !existingCommands.has(cmd));
      if (allNew && groupCommands.length > 0) {
        toAdd.push(group);
        groupCommands.forEach((cmd) => existingCommands.add(cmd));
      }
    }

    if (toAdd.length > 0) {
      result[event] = [...userGroups, ...toAdd];
    } else if (!result[event]) {
      result[event] = [];
    }
  }

  return result;
}

/**
 * Merge object fields (enabledPlugins, extraKnownMarketplaces).
 * Team values are added; existing user values are preserved.
 */
function mergeObjects(userObj, teamObj) {
  if (!teamObj) return userObj;
  const result = { ...(userObj || {}) };
  for (const [key, value] of Object.entries(teamObj)) {
    if (!(key in result)) {
      result[key] = value;
    }
    // For enabledPlugins: don't disable existing plugins
    // For marketplaces: don't overwrite existing definitions
  }
  return result;
}

// -------------------------------------------------------------------------
// Main merge logic
// -------------------------------------------------------------------------

function mergeSettings(team, user) {
  const merged = { ...user };

  // env — deep merge, team values set, user values preserved
  if (team.env) {
    merged.env = deepMergePreserve(merged.env || {}, team.env);
  }

  // hooks — append with deduplication
  if (team.hooks) {
    merged.hooks = mergeHooks(merged.hooks || {}, team.hooks);
  }

  // enabledPlugins — object merge (team plugins added, existing preserved)
  if (team.enabledPlugins) {
    merged.enabledPlugins = mergeObjects(
      merged.enabledPlugins,
      team.enabledPlugins
    );
  }

  // extraKnownMarketplaces — object merge
  if (team.extraKnownMarketplaces) {
    merged.extraKnownMarketplaces = mergeObjects(
      merged.extraKnownMarketplaces,
      team.extraKnownMarketplaces
    );
  }

  // permissions — NEVER touch

  // statusLine — only set if empty or missing
  if (team.statusLine && !merged.statusLine) {
    merged.statusLine = team.statusLine;
  }

  // effortLevel — only set if not configured
  if (team.effortLevel && !merged.effortLevel) {
    merged.effortLevel = team.effortLevel;
  }

  // includeCoAuthoredBy — only set if not configured
  if (
    "includeCoAuthoredBy" in team &&
    !("includeCoAuthoredBy" in merged)
  ) {
    merged.includeCoAuthoredBy = team.includeCoAuthoredBy;
  }

  // Copy any remaining team keys not handled above and not in user
  const handledKeys = new Set([
    "env",
    "hooks",
    "enabledPlugins",
    "extraKnownMarketplaces",
    "permissions",
    "statusLine",
    "effortLevel",
    "includeCoAuthoredBy",
  ]);

  for (const [key, value] of Object.entries(team)) {
    if (!handledKeys.has(key) && !(key in merged)) {
      merged[key] = value;
    }
  }

  return merged;
}

// -------------------------------------------------------------------------
// CLI entry point
// -------------------------------------------------------------------------

function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.error(
      "Usage: node merge-settings.js <team-file> <user-file>"
    );
    process.exit(1);
  }

  const teamPath = path.resolve(args[0]);
  const userPath = path.resolve(args[1]);

  if (!fs.existsSync(teamPath)) {
    console.error(`Error: Team file not found: ${teamPath}`);
    process.exit(1);
  }

  const team = parseJSON(teamPath);

  // If user file does not exist yet, start with empty object
  let user = {};
  if (fs.existsSync(userPath)) {
    user = parseJSON(userPath);

    // Create backup before modifying
    const backupPath = userPath + ".bak";
    fs.copyFileSync(userPath, backupPath);
  }

  const merged = mergeSettings(team, user);

  fs.writeFileSync(userPath, JSON.stringify(merged, null, 2) + "\n", "utf-8");
  console.log(`Settings merged: ${userPath}`);
}

main();
