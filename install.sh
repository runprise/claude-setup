#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Runprise Claude Code Setup — Gefuehrte Installation
# Funktioniert auf macOS und Linux
# =============================================================================

SETUP_REPO="https://github.com/runprise/claude-setup.git"
CLAUDE_DIR="$HOME/.claude"
LOCAL_BIN="$HOME/.local/bin"
NODE_MIN_VERSION=22

# --- Farben und Hilfsfunktionen ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
header()  { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local yn
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "${YELLOW}$prompt [Y/n]:${NC} ")" yn
        yn="${yn:-y}"
    else
        read -rp "$(echo -e "${YELLOW}$prompt [y/N]:${NC} ")" yn
        yn="${yn:-n}"
    fi
    [[ "$yn" =~ ^[Yy] ]]
}

command_exists() {
    command -v "$1" &>/dev/null
}

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        arm64|aarch64) echo "arm64" ;;
        x86_64|amd64)  echo "x86_64" ;;
        *)             echo "unknown" ;;
    esac
}

# --- Tracking ---

declare -a INSTALLED_COMPONENTS=()
declare -a SKIPPED_COMPONENTS=()
declare -a FAILED_COMPONENTS=()

track_installed() { INSTALLED_COMPONENTS+=("$1"); }
track_skipped()   { SKIPPED_COMPONENTS+=("$1"); }
track_failed()    { FAILED_COMPONENTS+=("$1"); }

# =============================================================================
header "Runprise Claude Code Setup"
# =============================================================================

OS=$(detect_os)
ARCH=$(detect_arch)

info "System: $OS ($ARCH)"
info "Home:   $HOME"

if [[ "$OS" == "unknown" ]]; then
    error "Nicht unterstuetztes Betriebssystem. Nur macOS und Linux werden unterstuetzt."
    exit 1
fi

# --- Setup-Repo holen (fuer config/ Verzeichnis) ---

SETUP_DIR=""
if [[ -f "$(dirname "$0")/config/CLAUDE.md" ]]; then
    # Lokale Ausfuehrung — config/ liegt neben dem Script
    SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"
    info "Lokale Installation aus $SETUP_DIR"
else
    # Remote-Ausfuehrung (curl | bash) — temporaer klonen
    SETUP_DIR="$(mktemp -d)"
    info "Lade Setup-Repo herunter..."
    git clone --depth 1 "$SETUP_REPO" "$SETUP_DIR" 2>/dev/null
    trap "rm -rf '$SETUP_DIR'" EXIT
    info "Setup-Repo geladen"
fi

CONFIG_SRC="$SETUP_DIR/config"

if [[ ! -d "$CONFIG_SRC" ]]; then
    error "config/ Verzeichnis nicht gefunden in $SETUP_DIR"
    exit 1
fi

# =============================================================================
header "Schritt 1: Voraussetzungen pruefen"
# =============================================================================

# --- Node.js ---

if command_exists node; then
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if (( NODE_VERSION >= NODE_MIN_VERSION )); then
        success "Node.js v$(node -v | sed 's/v//') gefunden"
    else
        error "Node.js $NODE_MIN_VERSION+ wird benoetigt, gefunden: v$(node -v | sed 's/v//')"
        if ask_yes_no "Node.js ueber nvm installieren?"; then
            if command_exists nvm; then
                nvm install "$NODE_MIN_VERSION"
                nvm use "$NODE_MIN_VERSION"
            else
                warn "nvm nicht gefunden. Bitte Node.js $NODE_MIN_VERSION+ manuell installieren:"
                warn "  https://nodejs.org/"
                warn "  oder: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
                exit 1
            fi
        else
            exit 1
        fi
    fi
else
    error "Node.js ist nicht installiert."
    warn "Bitte installiere Node.js $NODE_MIN_VERSION+:"
    warn "  https://nodejs.org/"
    warn "  oder: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
    exit 1
fi

# --- Git ---

if command_exists git; then
    success "Git $(git --version | awk '{print $3}') gefunden"
else
    error "Git ist nicht installiert."
    exit 1
fi

# --- Python / uv / pipx ---

HAVE_PYTHON=false
if command_exists python3; then
    success "Python $(python3 --version | awk '{print $2}') gefunden"
    HAVE_PYTHON=true
else
    warn "Python 3 nicht gefunden — einige optionale Tools werden uebersprungen"
fi

HAVE_UV=false
if command_exists uv; then
    success "uv $(uv --version 2>/dev/null | awk '{print $2}') gefunden"
    HAVE_UV=true
else
    if ask_yes_no "uv (Python Package Manager) ist nicht installiert. Installieren?"; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$LOCAL_BIN:$PATH"
        success "uv installiert"
        track_installed "uv"
        HAVE_UV=true
    else
        warn "uv wird uebersprungen — einige Python-Tools nicht verfuegbar"
        track_skipped "uv"
    fi
fi

HAVE_PIPX=false
if command_exists pipx; then
    success "pipx gefunden"
    HAVE_PIPX=true
else
    if ask_yes_no "pipx ist nicht installiert. Installieren?"; then
        if [[ "$OS" == "macos" ]] && command_exists brew; then
            brew install pipx
            pipx ensurepath
        elif $HAVE_PYTHON; then
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        else
            warn "Weder brew noch python3 verfuegbar — pipx kann nicht installiert werden"
            track_failed "pipx"
        fi
        if command_exists pipx; then
            success "pipx installiert"
            track_installed "pipx"
            HAVE_PIPX=true
        fi
    else
        warn "pipx wird uebersprungen"
        track_skipped "pipx"
    fi
fi

# --- macOS: Homebrew ---

if [[ "$OS" == "macos" ]]; then
    if command_exists brew; then
        success "Homebrew gefunden"
    else
        warn "Homebrew nicht gefunden — einige macOS-Tools werden uebersprungen"
    fi
fi

# =============================================================================
header "Schritt 2: Claude Code installieren"
# =============================================================================

if command_exists claude; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unbekannt")
    success "Claude Code bereits installiert: $CLAUDE_VERSION"
    track_skipped "Claude Code (bereits installiert)"
else
    info "Installiere Claude Code..."
    npm install -g @anthropic-ai/claude-code
    success "Claude Code installiert"
    track_installed "Claude Code"
fi

# =============================================================================
header "Schritt 3: Konfiguration deployen"
# =============================================================================

info "Kopiere Runprise-Konfiguration nach $CLAUDE_DIR..."

# Sicherstellen dass ~/.claude existiert
mkdir -p "$CLAUDE_DIR"

# Backup persoenlicher Dateien falls vorhanden
for f in .claude.json .credentials.json; do
    if [[ -f "$CLAUDE_DIR/$f" ]]; then
        cp "$CLAUDE_DIR/$f" "$CLAUDE_DIR/$f.bak" 2>/dev/null || true
    fi
done

# Konfigurationsdateien kopieren (nur fehlende oder explizit gewuenschte)
copy_if_missing() {
    local src="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        if ask_yes_no "  $(basename "$dest") existiert bereits. Ueberschreiben?" "n"; then
            cp "$src" "$dest"
            success "  $(basename "$dest") aktualisiert"
        else
            track_skipped "$(basename "$dest") (beibehalten)"
        fi
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        success "  $(basename "$dest") erstellt"
    fi
}

# Hauptdateien
copy_if_missing "$CONFIG_SRC/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
copy_if_missing "$CONFIG_SRC/settings.json" "$CLAUDE_DIR/settings.json"
copy_if_missing "$CONFIG_SRC/.mcp.json" "$CLAUDE_DIR/.mcp.json"

# Rules
info "Rules..."
mkdir -p "$CLAUDE_DIR/rules"
for rule in "$CONFIG_SRC"/rules/*.md; do
    name="$(basename "$rule")"
    copy_if_missing "$rule" "$CLAUDE_DIR/rules/$name"
done

# Skills
info "Skills..."
for skill_dir in "$CONFIG_SRC"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    copy_if_missing "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
done

# Hooks
info "Hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
for hook in "$CONFIG_SRC"/hooks/*; do
    name="$(basename "$hook")"
    copy_if_missing "$hook" "$CLAUDE_DIR/hooks/$name"
    chmod +x "$CLAUDE_DIR/hooks/$name" 2>/dev/null || true
done

# Templates
info "Templates..."
mkdir -p "$CLAUDE_DIR/templates"
for tmpl in "$CONFIG_SRC"/templates/*; do
    name="$(basename "$tmpl")"
    copy_if_missing "$tmpl" "$CLAUDE_DIR/templates/$name"
done

# Commands
info "Commands..."
mkdir -p "$CLAUDE_DIR/commands"
for cmd in "$CONFIG_SRC"/commands/*; do
    name="$(basename "$cmd")"
    copy_if_missing "$cmd" "$CLAUDE_DIR/commands/$name"
done

track_installed "Konfiguration (Rules, Skills, Hooks, Templates, Commands)"

# Persoenliche Dateien wiederherstellen
for f in .claude.json .credentials.json; do
    if [[ -f "$CLAUDE_DIR/$f.bak" ]]; then
        mv "$CLAUDE_DIR/$f.bak" "$CLAUDE_DIR/$f"
    fi
done

# =============================================================================
header "Schritt 4: Pfade personalisieren"
# =============================================================================

info "Passe Pfade in Konfigurationsdateien an dein System an..."

PLACEHOLDER="__HOME__"
for target_file in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/.mcp.json"; do
    if [[ -f "$target_file" ]] && grep -q "$PLACEHOLDER" "$target_file" 2>/dev/null; then
        sed -i.bak "s|$PLACEHOLDER|$HOME|g" "$target_file"
        rm -f "$target_file.bak"
        success "Pfade in $(basename "$target_file") angepasst"
    fi
done

# Linux: macOS-spezifische Hooks entfernen
if [[ "$OS" != "macos" ]] && [[ -f "$CLAUDE_DIR/settings.json" ]] && $HAVE_PYTHON; then
    info "Linux erkannt — entferne macOS-spezifische Hooks (terminal-notifier)..."
    python3 -c "
import json
settings_path = '$CLAUDE_DIR/settings.json'
with open(settings_path) as f:
    cfg = json.load(f)
hooks = cfg.get('hooks', {})
for event in list(hooks.keys()):
    hooks[event] = [
        entry for entry in hooks[event]
        if not any(
            'terminal-notifier' in h.get('command', '')
            for h in entry.get('hooks', [])
        )
    ]
cfg['hooks'] = hooks
with open(settings_path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" 2>/dev/null && success "macOS-spezifische Hooks entfernt" || warn "Konnte macOS-Hooks nicht automatisch entfernen — bitte manuell pruefen"
fi

# =============================================================================
header "Schritt 5: Plugins vorbereiten"
# =============================================================================

info "Plugins werden ueber Claude Code installiert."
info "Das Script erstellt ein Hilfsscript, das du nach dem ersten Claude-Start ausfuehren kannst."
echo ""

cat > "$CLAUDE_DIR/install-plugins.sh" << 'PLUGINEOF'
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}=== Runprise Claude Code — Plugin-Installation ===${NC}\n"

echo -e "${BOLD}Registriere Marketplaces...${NC}"
MARKETPLACES=(
    "anthropics/claude-plugins-official"
    "anthropics/claude-code"
    "czlonkowski/n8n-skills"
    "asheshgoplani/agent-deck"
)

for mp in "${MARKETPLACES[@]}"; do
    echo -n "  $mp ... "
    claude /install-marketplace "$mp" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo "(bereits registriert oder Fehler)"
done

echo ""
echo -e "${BOLD}Installiere Plugins...${NC}"
PLUGINS=(
    "superpowers@claude-plugins-official"
    "code-review@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "code-simplifier@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "frontend-design@claude-code-plugins"
    "n8n-mcp-skills@n8n-mcp-skills"
    "agent-deck@agent-deck"
)

for plugin in "${PLUGINS[@]}"; do
    echo -n "  $plugin ... "
    claude /install "$plugin" 2>/dev/null && echo -e "${GREEN}OK${NC}" || echo "(Fehler)"
done

echo ""
echo -e "${GREEN}Fertig!${NC} Starte Claude Code neu, damit alle Plugins geladen werden."
PLUGINEOF
chmod +x "$CLAUDE_DIR/install-plugins.sh"
success "Plugin-Script erstellt: $CLAUDE_DIR/install-plugins.sh"
track_installed "Plugin-Installationsscript"

# =============================================================================
header "Schritt 6: Externe Tools"
# =============================================================================

# --- npm global ---

echo -e "${BOLD}npm Global Packages:${NC}"

NPM_PACKAGES=(
    "claudekit"
)

for pkg in "${NPM_PACKAGES[@]}"; do
    if npm list -g "$pkg" &>/dev/null; then
        success "$pkg bereits installiert"
        track_skipped "$pkg (bereits installiert)"
    else
        if ask_yes_no "  $pkg installieren?"; then
            npm install -g "$pkg" && { success "$pkg installiert"; track_installed "$pkg"; } || { warn "Fehler bei $pkg"; track_failed "$pkg"; }
        else
            track_skipped "$pkg"
        fi
    fi
done

# --- uv tools ---

if $HAVE_UV; then
    echo ""
    echo -e "${BOLD}Python Tools (uv):${NC}"

    UV_TOOLS=(
        "claude-code-tools"
        "claude-monitor"
        "notebooklm-mcp-cli"
    )

    for tool in "${UV_TOOLS[@]}"; do
        if uv tool list 2>/dev/null | grep -q "$tool"; then
            success "$tool bereits installiert"
            track_skipped "$tool (bereits installiert)"
        else
            if ask_yes_no "  $tool installieren?"; then
                uv tool install "$tool" && { success "$tool installiert"; track_installed "$tool (uv)"; } || { warn "Fehler bei $tool"; track_failed "$tool"; }
            else
                track_skipped "$tool"
            fi
        fi
    done
fi

# --- pipx tools ---

if $HAVE_PIPX; then
    echo ""
    echo -e "${BOLD}Python Tools (pipx):${NC}"

    PIPX_TOOLS=(
        "skill-seekers"
    )

    for tool in "${PIPX_TOOLS[@]}"; do
        if pipx list --short 2>/dev/null | grep -q "$tool"; then
            success "$tool bereits installiert"
            track_skipped "$tool (bereits installiert)"
        else
            if ask_yes_no "  $tool installieren?"; then
                pipx install "$tool" && { success "$tool installiert"; track_installed "$tool (pipx)"; } || { warn "Fehler bei $tool"; track_failed "$tool"; }
            else
                track_skipped "$tool"
            fi
        fi
    done
fi

# --- Lightpanda ---

echo ""
echo -e "${BOLD}Lightpanda (Headless Browser):${NC}"

if [[ -f "$LOCAL_BIN/lightpanda" ]]; then
    success "Lightpanda bereits installiert"
    track_skipped "Lightpanda (bereits installiert)"
else
    if ask_yes_no "Lightpanda installieren? (Schneller Headless Browser fuer E2E Tests)"; then
        mkdir -p "$LOCAL_BIN"

        LIGHTPANDA_URL=""
        if [[ "$OS" == "macos" && "$ARCH" == "arm64" ]]; then
            LIGHTPANDA_URL="https://github.com/nicholasgasior/lightpanda-releases/releases/latest/download/lightpanda-aarch64-macos"
        elif [[ "$OS" == "macos" && "$ARCH" == "x86_64" ]]; then
            LIGHTPANDA_URL="https://github.com/nicholasgasior/lightpanda-releases/releases/latest/download/lightpanda-x86_64-macos"
        elif [[ "$OS" == "linux" && "$ARCH" == "x86_64" ]]; then
            LIGHTPANDA_URL="https://github.com/nicholasgasior/lightpanda-releases/releases/latest/download/lightpanda-x86_64-linux"
        elif [[ "$OS" == "linux" && "$ARCH" == "arm64" ]]; then
            LIGHTPANDA_URL="https://github.com/nicholasgasior/lightpanda-releases/releases/latest/download/lightpanda-aarch64-linux"
        fi

        if [[ -n "$LIGHTPANDA_URL" ]]; then
            info "Lade Lightpanda herunter..."
            curl -fsSL -o "$LOCAL_BIN/lightpanda" "$LIGHTPANDA_URL" && chmod +x "$LOCAL_BIN/lightpanda"
            success "Lightpanda installiert nach $LOCAL_BIN/lightpanda"
            track_installed "Lightpanda"
        else
            warn "Keine passende Lightpanda-Version fuer $OS/$ARCH gefunden"
            track_failed "Lightpanda"
        fi
    else
        track_skipped "Lightpanda"
    fi
fi

# --- macOS: terminal-notifier ---

if [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}macOS Tools:${NC}"

    if command_exists terminal-notifier; then
        success "terminal-notifier bereits installiert"
        track_skipped "terminal-notifier (bereits installiert)"
    else
        if command_exists brew && ask_yes_no "  terminal-notifier installieren? (Desktop-Benachrichtigungen)"; then
            brew install terminal-notifier && { success "terminal-notifier installiert"; track_installed "terminal-notifier"; } || track_failed "terminal-notifier"
        else
            track_skipped "terminal-notifier"
        fi
    fi
fi

# =============================================================================
header "Schritt 7: PATH pruefen"
# =============================================================================

PATH_ADDITIONS=()

if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    PATH_ADDITIONS+=("$LOCAL_BIN")
fi

if [[ ${#PATH_ADDITIONS[@]} -gt 0 ]]; then
    warn "Folgende Pfade fehlen in deinem PATH:"
    for p in "${PATH_ADDITIONS[@]}"; do
        echo "  $p"
    done

    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]] && ask_yes_no "PATH in $SHELL_RC ergaenzen?"; then
        for p in "${PATH_ADDITIONS[@]}"; do
            if ! grep -q "export PATH=\"$p" "$SHELL_RC" 2>/dev/null; then
                echo "export PATH=\"$p:\$PATH\"" >> "$SHELL_RC"
            fi
        done
        success "PATH in $SHELL_RC ergaenzt — neues Terminal oeffnen oder: source $SHELL_RC"
    else
        warn "Bitte manuell ergaenzen: export PATH=\"$LOCAL_BIN:\$PATH\""
    fi
else
    success "PATH ist korrekt konfiguriert"
fi

# =============================================================================
header "Schritt 8: Naechste Schritte"
# =============================================================================

echo "  1. Claude Code starten:"
echo -e "     ${CYAN}claude${NC}"
echo ""
echo "  2. Beim ersten Start mit Anthropic Account einloggen"
echo ""
echo "  3. Plugins installieren:"
echo -e "     ${CYAN}~/.claude/install-plugins.sh${NC}"
echo ""
echo "  Danach ist Claude Code mit dem Runprise Team-Setup einsatzbereit."

# =============================================================================
header "Zusammenfassung"
# =============================================================================

if [[ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]]; then
    echo -e "${GREEN}Installiert:${NC}"
    for c in "${INSTALLED_COMPONENTS[@]}"; do
        echo -e "  ${GREEN}+${NC} $c"
    done
fi

if [[ ${#SKIPPED_COMPONENTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Uebersprungen:${NC}"
    for c in "${SKIPPED_COMPONENTS[@]}"; do
        echo -e "  ${YELLOW}-${NC} $c"
    done
fi

if [[ ${#FAILED_COMPONENTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Fehlgeschlagen:${NC}"
    for c in "${FAILED_COMPONENTS[@]}"; do
        echo -e "  ${RED}!${NC} $c"
    done
fi

echo ""
success "Setup abgeschlossen!"
