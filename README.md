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

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/runprise/claude-setup/main/update.sh | bash
```

Das Update-Script:
- Erkennt welche Dateien im Repo geaendert wurden
- Aktualisiert nur Dateien die lokal **nicht** manuell angepasst wurden
- Zeigt lokal geaenderte Dateien als "beibehalten" an
- Erstellt automatisch ein Backup vor Aenderungen
- Neue Dateien (z.B. neue Skills) werden automatisch installiert

## Was wird installiert?

Das Script fuehrt dich interaktiv durch die Installation. Jeder Schritt kann uebersprungen werden.

### Voraussetzungen

| Tool | Version | Hinweis |
|------|---------|---------|
| Node.js | 22+ | Wird geprueft, nvm-Installation angeboten |
| Git | 2.x | Muss vorhanden sein |
| Python 3 | 3.12+ | Optional, fuer Python-Tools |

### Plugins

Werden nach der Basisinstallation ueber `~/.claude/install-plugins.sh` installiert.

#### Workflow & Qualitaet

| Plugin | Beschreibung |
|--------|-------------|
| **superpowers** | Kompletter Entwicklungs-Workflow: Brainstorming vor Features, TDD, strukturierte Plan-Erstellung und -Ausfuehrung, Code-Review mit Checklisten, systematisches Debugging |
| **code-review** | Automatisierte PR-Reviews: prueft Code auf Bugs, Security-Probleme, Code-Qualitaet und Einhaltung von Projekt-Konventionen |
| **feature-dev** | Gefuehrte Feature-Entwicklung: analysiert erst die bestehende Codebase, entwirft Architektur, dann schrittweise Implementierung |
| **code-simplifier** | Prueft kuerzlich geaenderten Code auf Wiederverwendbarkeit, Konsistenz und unnoetige Komplexitaet — und behebt gefundene Probleme |
| **security-guidance** | Sicherheitsberatung beim Entwickeln: erkennt OWASP-Risiken, unsichere Patterns und schlaegt sichere Alternativen vor |

#### Frontend & Design

| Plugin | Beschreibung |
|--------|-------------|
| **frontend-design** | Generiert produktionsreife, visuell hochwertige Frontend-Interfaces — vermeidet generisches "AI-Look" Design |

#### Integrationen

| Plugin | Beschreibung |
|--------|-------------|
| **n8n-mcp-skills** | Skills fuer n8n Workflow-Automatisierung: Node-Konfiguration, Expression-Syntax, Code-Nodes (JS/Python), Workflow-Patterns, Validierung |
| **agent-deck** | Terminal Session Manager: parallele Claude-Sessions, Sub-Agenten, Profil-Management, Session-Sharing zwischen Entwicklern |

> **Quelle:** Plugins kommen aus offiziellen und Community-Marketplaces (`anthropics/claude-plugins-official`, `anthropics/claude-code`, `czlonkowski/n8n-skills`, `asheshgoplani/agent-deck`)

### Skills (enthalten in `config/skills/`)

Skills sind Anleitungen die Claude bei bestimmten Aufgaben automatisch befolgt.

#### Framework-Skills

| Skill | Trigger | Beschreibung |
|-------|---------|-------------|
| **vue-shadcn** | Vue.js Projekte | Vue 3 Composition API, shadcn-vue Components, Pinia, vee-validate + Zod |
| **nextjs-app** | Next.js Projekte | App Router, Server Components, Server Actions, shadcn/ui, Tailwind v4 |
| **fastapi** | Python APIs | FastAPI mit uv, Pydantic v2, SQLAlchemy, Structlog, pytest |
| **flutter** | Mobile Apps | Feature-first Struktur, Riverpod, GoRouter, Dart null-safety |
| **postgresql** | DB-Optimierung | EXPLAIN ANALYZE, Index-Strategien, VACUUM, pg_stat_statements |

#### DevOps & Deployment

| Skill | Trigger | Beschreibung |
|-------|---------|-------------|
| **coolify** | Coolify Deployment | Docker Compose fuer Coolify anpassen, Magic Env Vars, Debugging |
| **deploy** | Docker Review | Dockerfile + docker-compose.yml auf Production-Readiness pruefen |
| **server-hardening** | Server-Sicherheit | SSH, Fail2Ban, UFW, unattended-upgrades, Docker/Coolify Status |

#### Workflow-Skills

| Skill | Trigger | Beschreibung |
|-------|---------|-------------|
| **git-clean-push** | `/git-clean-push` | Lint → Stage → Commit → Push mit Validierung in jedem Schritt |
| **project-setup** | Neues Projekt | Erkennt Sprache, richtet Linting, Testing, Git Hooks, CI/CD ein |
| **n8n-as-code** | n8n Workflows | n8n Workflows als TypeScript mit n8nac CLI erstellen und validieren |
| **roxy** | Lokale Domains | Roxy Dev-Proxy: `.roxy`-Domains mit Auto-HTTPS, Path-Routing, Wildcards |

### CLI Tools (optional)

| Tool | Installation | Beschreibung |
|------|-------------|-------------|
| claudekit | npm | Claude Code Dev Utilities |
| claude-code-tools | uv (Python) | env-safe, fix-session und weitere Helfer |
| claude-monitor | uv (Python) | Session-Monitoring und -Analyse |
| notebooklm-mcp-cli | uv (Python) | Google NotebookLM MCP Server |
| skill-seekers | pipx (Python) | Skill-Generierung aus Dokumentation |
| Lightpanda | Binary | Schneller Headless Browser fuer E2E Tests |
| terminal-notifier | brew (macOS) | Desktop-Benachrichtigungen bei Claude-Wartepausen |

## Plattformen

- macOS (ARM64 + x86_64)
- Linux (x86_64 + ARM64)

## Nach der Installation

1. Claude Code starten: `claude`
2. Beim ersten Start mit Anthropic Account einloggen
3. Plugins installieren: `~/.claude/install-plugins.sh`

## Wie das Update funktioniert

Das Setup nutzt ein **Manifest** (`~/.claude/.runprise-manifest`), das fuer jede installierte Datei den Checksum zum Zeitpunkt der Installation speichert.

Beim Update wird verglichen:

| Situation | Aktion |
|-----------|--------|
| Datei nur im Repo (neu) | Wird installiert |
| Repo geaendert, lokal unberuehrt | Wird aktualisiert |
| Repo geaendert, lokal auch geaendert | Wird uebersprungen (deine Version bleibt) |
| Keine Aenderung im Repo | Nichts passiert |

Um eine uebersprungene Datei trotzdem zu aktualisieren:
1. Datei sichern/loeschen
2. `update.sh` erneut ausfuehren

## Repo-Struktur

```
claude-setup/
├── install.sh               # Gefuehrte Erstinstallation
├── update.sh                # Intelligentes Update
├── lib/
│   └── common.sh            # Gemeinsame Funktionen
├── config/                   # Wird nach ~/.claude/ kopiert
│   ├── CLAUDE.md             # Globale Instruktionen
│   ├── settings.json         # Hooks, Permissions, Env-Variablen
│   ├── .mcp.json             # MCP-Server (Playwright)
│   ├── rules/                # Coding Standards, Workflow, Testing
│   ├── skills/               # 11 Framework-Skills
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
4. Nach Merge: Teammitglieder fuehren `update.sh` aus

## Detaillierte Dokumentation

Siehe [SETUP-OVERVIEW.md](./SETUP-OVERVIEW.md) fuer eine vollstaendige Auflistung aller Komponenten, Quellen und Konfigurationsdetails.
