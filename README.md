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
| **Konfiguration** | Rules, 13 Skills, Hooks, Commands, Templates → `~/.claude/` |
| **8 Plugins** | superpowers, code-review, feature-dev, frontend-design, n8n, u.a. |
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
| code-review | anthropics/claude-plugins-official | PR Code Reviews |
| feature-dev | anthropics/claude-plugins-official | Gefuehrte Feature-Entwicklung |
| code-simplifier | anthropics/claude-plugins-official | Code-Vereinfachung |
| security-guidance | anthropics/claude-plugins-official | Sicherheitsberatung |
| frontend-design | anthropics/claude-code | Frontend UI Design |
| n8n-mcp-skills | czlonkowski/n8n-skills | n8n Workflow Skills |
| agent-deck | asheshgoplani/agent-deck | Session-Management |

### Skills (enthalten in `config/skills/`)

| Skill | Beschreibung |
|-------|-------------|
| vue-shadcn | Vue 3 + shadcn-vue Patterns |
| nextjs-app | Next.js 15 App Router |
| fastapi | FastAPI Backend (Python 3.12+) |
| payload-cms | Payload CMS 3.x |
| flutter | Flutter/Dart Apps |
| postgresql | PostgreSQL Optimierung |
| coolify | Coolify Deployment |
| deploy | Docker Production Review |
| server-hardening | Server Security |
| git-clean-push | Sauberer Git Commit + Push |
| project-setup | Best Practices fuer neue Projekte |
| n8n-as-code | n8n Workflows als TypeScript |
| reflagged-ci | Corporate Identity Design |

## Plattformen

- macOS (ARM64 + x86_64)
- Linux (x86_64 + ARM64)

## Nach der Installation

1. Claude Code starten: `claude`
2. Beim ersten Start mit Anthropic Account einloggen
3. Plugins installieren: `~/.claude/install-plugins.sh`

## Detaillierte Dokumentation

Siehe [SETUP-OVERVIEW.md](./SETUP-OVERVIEW.md) fuer eine vollstaendige Auflistung aller Komponenten, Quellen und Konfigurationsdetails.

## Repo-Struktur

```
runprise-claude/
├── install.sh               # Gefuehrtes Installationsscript
├── config/                   # Wird nach ~/.claude/ kopiert
│   ├── CLAUDE.md             # Globale Instruktionen
│   ├── settings.json         # Hooks, Permissions, Env-Variablen
│   ├── .mcp.json             # MCP-Server (Playwright)
│   ├── rules/                # Coding Standards, Workflow, Testing
│   ├── skills/               # 13 Framework-Skills
│   ├── hooks/                # Session-Hooks (Lightpanda, Cleanup)
│   ├── templates/            # Vorlagen (.env.test)
│   └── commands/             # Slash Commands (Lightpanda)
├── README.md
└── SETUP-OVERVIEW.md         # Detaillierte Komponentendoku
```

## Anpassen

Aenderungen an der Team-Konfiguration gehoeren in dieses Repo:

1. Repo klonen: `git clone https://github.com/runprise/claude-setup.git`
2. Dateien in `config/` anpassen
3. Pull Request erstellen
4. Nach Merge: Teammitglieder fuehren `install.sh` erneut aus (nur Aenderungen werden aktualisiert)
