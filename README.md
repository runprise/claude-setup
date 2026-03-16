# Runprise Claude Code Setup

Standardisiertes Claude Code Setup fuer das Runprise Team — Rules, Skills, Plugins, Hooks und Tools in einem Schritt.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/runprise/claude-setup/main/install.sh | bash
```

Oder manuell:

```bash
git clone https://github.com/runprise/claude-setup.git
cd claude-setup
./install.sh
```

## Was wird installiert?

Das Script fuehrt dich interaktiv durch die Installation. Jeder Schritt kann uebersprungen werden.

### Uebersicht

| Komponente | Beschreibung |
|------------|-------------|
| **Claude Code** | `@anthropic-ai/claude-code` CLI Tool |
| **Config-Repo** | Rules, Skills, Agents, Commands, Hooks → `~/.claude/` |
| **9 Plugins** | superpowers, atlassian, code-review, feature-dev, frontend-design, u.a. |
| **MCP-Server** | Playwright (Chrome + Lightpanda Headless) |
| **CLI Tools** | claude-code-tools, claude-monitor, skill-seekers, Lightpanda |

### Voraussetzungen

| Tool | Version | Hinweis |
|------|---------|---------|
| Node.js | 22+ | Wird geprueft, nvm-Installation angeboten |
| Git | 2.x | Muss vorhanden sein |
| Python 3 | 3.12+ | Optional, fuer Python-Tools |

### Plugins

Werden nach der Basisinstallation ueber ein separates Script installiert:

| Plugin | Quelle | Zweck |
|--------|--------|-------|
| superpowers | anthropics/claude-plugins-official | Brainstorming, TDD, Plan-Execution, Code-Review |
| atlassian | anthropics/claude-plugins-official | Jira + Confluence Integration |
| code-review | anthropics/claude-plugins-official | PR Code Reviews |
| feature-dev | anthropics/claude-plugins-official | Gefuehrte Feature-Entwicklung |
| code-simplifier | anthropics/claude-plugins-official | Code-Vereinfachung |
| security-guidance | anthropics/claude-plugins-official | Sicherheitsberatung |
| frontend-design | anthropics/claude-code | Frontend UI Design |
| n8n-mcp-skills | czlonkowski/n8n-skills | n8n Workflow Skills |
| agent-deck | asheshgoplani/agent-deck | Session-Management |

## Plattformen

- macOS (ARM64 + x86_64)
- Linux (x86_64 + ARM64)

## Nach der Installation

1. Claude Code starten: `claude`
2. Beim ersten Start mit Anthropic Account einloggen
3. Plugins installieren: `~/.claude/install-plugins.sh`

## Detaillierte Dokumentation

Siehe [SETUP-OVERVIEW.md](./SETUP-OVERVIEW.md) fuer eine vollstaendige Auflistung aller Komponenten, Quellen und Konfigurationsdetails.

## Anpassen

Die Konfiguration in `~/.claude/` ist ein Git-Repo. Eigene Rules, Skills oder Commands koennen dort ergaenzt und per Pull Request zurueck ins Team-Repo gebracht werden.

Wichtige Dateien:
- `~/.claude/rules/` — Coding Standards, Workflow-Regeln
- `~/.claude/skills/` — Framework-spezifische Skills
- `~/.claude/settings.json` — Hooks, Permissions, Env-Variablen
