# Claude Code Setup — Komponentenuebersicht

Vollstaendige Dokumentation aller installierten Komponenten, deren Quellen und Zweck.

---

## 1. Claude Code

| Komponente | Details |
|------------|---------|
| Paket | `@anthropic-ai/claude-code` |
| Installation | `npm install -g @anthropic-ai/claude-code` |
| Binary | `~/.local/bin/claude` |
| Voraussetzung | Node.js 22+, Anthropic Account |

---

## 2. Konfigurations-Repository

Die gesamte Claude-Code-Konfiguration liegt in `~/.claude/` und wird als Git-Repo versioniert.

| Komponente | Details |
|------------|---------|
| Setup-Repo | `https://github.com/runprise/claude-setup.git` |
| Zielverzeichnis | `~/.claude/` |
| Inhalt | Rules, Skills, Commands, Hooks, Templates |

### Verzeichnisstruktur

```
~/.claude/
├── CLAUDE.md                    # Globale Instruktionen (geladen jede Session)
├── settings.json                # Hooks, Permissions, Env-Variablen, Plugins
├── .mcp.json                    # MCP-Server Konfiguration
├── rules/                       # Team-Regeln (4 Dateien)
│   ├── coding-standards.md      #   TypeScript, ES Modules, Sicherheit
│   ├── tech-stack.md            #   Vue, Next.js, Node, Docker/Coolify
│   ├── workflow.md              #   Lesen vor Aendern, Tests, Sprache
│   └── testing.md               #   Playwright, Lightpanda, .env.test
├── skills/                      # Framework-Skills (12 Skills)
│   ├── coolify/                 #   Coolify Deployment
│   ├── deploy/                  #   Docker Review fuer Coolify
│   ├── fastapi/                 #   FastAPI Backend (Python 3.12+)
│   ├── flutter/                 #   Flutter/Dart Apps
│   ├── git-clean-push/          #   Sauberer Git Commit + Push
│   ├── n8n-as-code/             #   n8n Workflows als TypeScript
│   ├── nextjs-app/              #   Next.js 15 App Router
│   ├── payload-cms/             #   Payload CMS 3.x
│   ├── postgresql/              #   PostgreSQL Optimierung
│   ├── project-setup/           #   Best Practices fuer neue Projekte
│   ├── server-hardening/        #   Server Security
│   └── vue-shadcn/              #   Vue 3 + shadcn-vue
├── agents/                      # Spezialisierte Agenten
│   ├── engineering/             #   Backend, Frontend, DevOps, Test
│   ├── design/                  #   Design-Agent
│   ├── testing/                 #   Test-Agent
│   └── gsd-*.md                 #   19 GSD-Agenten
├── commands/                    # Slash Commands
│   ├── gsd/                     #   40+ GSD Commands
│   ├── shopware/                #   14 Shopware Commands
│   └── lightpanda.md            #   Lightpanda Browser
├── hooks/                       # Session Hooks
│   ├── gsd-statusline.js        #   Status Line
│   ├── gsd-context-monitor.js   #   Kontext-Warnung
│   ├── gsd-check-update.cjs     #   GSD Update-Check
│   ├── lightpanda-start.sh      #   Lightpanda Auto-Start
│   └── serena-cleanup.sh        #   Prozess-Cleanup
├── templates/                   # Vorlagen
│   └── env.test.example         #   E2E Credential Template
├── get-shit-done/               # GSD Workflow Framework
├── shopware/                    # Shopware Framework
└── bin/                         # Helper Scripts
```

---

## 3. Plugins (via Claude Code Plugin-System)

Plugins werden ueber `claude /install` installiert. Jedes Plugin kommt aus einem "Marketplace" (Git-Repo).

### Registrierte Marketplaces

| Marketplace | Repository | Plugins |
|------------|------------|---------|
| claude-plugins-official | `anthropics/claude-plugins-official` | superpowers, code-review, feature-dev, code-simplifier, security-guidance |
| claude-code-plugins | `anthropics/claude-code` | frontend-design |
| n8n-mcp-skills | `czlonkowski/n8n-skills` | n8n-mcp-skills |
| agent-deck | `asheshgoplani/agent-deck` | agent-deck |

### Aktivierte Plugins

| Plugin | Marketplace | Zweck |
|--------|------------|-------|
| **superpowers** | claude-plugins-official | Brainstorming, TDD, Plan-Execution, Code-Review Workflows |
| **code-review** | claude-plugins-official | PR Code Reviews |
| **feature-dev** | claude-plugins-official | Gefuehrte Feature-Entwicklung |
| **code-simplifier** | claude-plugins-official | Code-Vereinfachung |
| **security-guidance** | claude-plugins-official | Sicherheitsberatung |
| **frontend-design** | claude-code-plugins | Frontend UI Design |
| **n8n-mcp-skills** | n8n-mcp-skills | n8n Workflow Skills |
| **agent-deck** | agent-deck | Session-Management, Sub-Agents |

---

## 4. MCP-Server

Konfiguriert in `~/.claude/.mcp.json`:

| Server | Typ | Zweck |
|--------|-----|-------|
| **playwright** | `npx @playwright/mcp@latest` | Chrome-basierte Browser-Automation |
| **playwright-light** | `npx @playwright/mcp@latest --cdp-endpoint ws://127.0.0.1:9222` | Lightpanda Headless Browser |

Weitere MCP-Server koennen projektspezifisch in `.mcp.json` im Projektroot konfiguriert werden.

---

## 5. Externe Tools

### Ueber npm global

| Paket | Befehl | Zweck |
|-------|--------|-------|
| `@anthropic-ai/claude-code` | `claude` | Claude Code CLI |
| `claudekit` | `claudekit` | Claude Code Dev Utilities |

### Ueber uv (Python)

| Paket | Befehle | Zweck |
|-------|---------|-------|
| `claude-code-tools` | `env-safe`, `fix-session`, u.a. | Utility-Tools |
| `claude-monitor` | `ccm`, `claude-monitor` | Session-Monitoring |
| `notebooklm-mcp-cli` | `nlm`, `notebooklm-mcp` | NotebookLM MCP Server |

### Ueber pipx (Python)

| Paket | Zweck |
|-------|-------|
| `skill-seekers` | Skill-Generierung aus Dokumentation |

### Binaries

| Tool | Pfad | Quelle |
|------|------|--------|
| **Lightpanda** | `~/.local/bin/lightpanda` | GitHub Release (plattformspezifisch) |
| **agent-deck** | `~/.local/bin/agent-deck` | Installiert durch agent-deck Plugin |

---

## 6. Settings (settings.json)

### Umgebungsvariablen

| Variable | Wert | Zweck |
|----------|------|-------|
| BASH_DEFAULT_TIMEOUT_MS | 300000 | Standard-Timeout 5 Min |
| BASH_MAX_OUTPUT_LENGTH | 500000 | Max Bash-Output |
| BASH_MAX_TIMEOUT_MS | 600000 | Max Timeout 10 Min |
| CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR | true | Absolute Pfade beibehalten |
| DISABLE_COST_WARNINGS | 1 | Keine Kostenwarnungen |
| MAX_THINKING_TOKENS | 20000 | Thinking-Budget |
| MCP_TIMEOUT | 60000 | MCP Timeout 60s |
| MCP_TOOL_TIMEOUT | 60000 | MCP Tool Timeout 60s |
| CLAUDE_AUTOCOMPACT_PCT_OVERRIDE | 80 | Autocompact bei 80% |
| CLAUDE_CODE_DISABLE_TERMINAL_TITLE | 1 | Kein Terminal-Title |

### Hooks

| Event | Aktion |
|-------|--------|
| SessionStart | GSD Update-Check, Lightpanda starten, agent-deck |
| SessionEnd | agent-deck, Cleanup, Lightpanda stoppen |
| PostToolUse | GSD Context Monitor |
| Stop | Tracking Hook, agent-deck |
| Notification | agent-deck, terminal-notifier (nur macOS) |
| UserPromptSubmit | agent-deck |
| PermissionRequest | agent-deck |
| PreCompact | agent-deck |

### Weitere Settings

| Setting | Wert |
|---------|------|
| effortLevel | high |
| defaultMode | bypassPermissions |
| includeCoAuthoredBy | false |
| skipDangerousModePermissionPrompt | true |
| cleanupPeriodDays | 30 |

---

## 7. Voraussetzungen

| Tool | Mindestversion | Installation |
|------|---------------|-------------|
| Node.js | 22+ | `nvm install 22` |
| Python | 3.12+ | System oder `pyenv` |
| uv | latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| pipx | latest | `brew install pipx` / `apt install pipx` |
| Git | 2.x | System |
| terminal-notifier | latest | `brew install terminal-notifier` (nur macOS) |
