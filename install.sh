#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Runprise Claude Code Setup — Gefuehrte Erstinstallation
# Funktioniert auf macOS und Linux
# =============================================================================

# --- Library laden ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"

# Bei curl | bash: Library aus dem geklonten Repo laden
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Temp-Verzeichnis fuer Remote-Ausfuehrung
    _REMOTE_TMP="$(mktemp -d)"
    trap "rm -rf '$_REMOTE_TMP'" EXIT
    git clone --depth 1 --quiet "https://github.com/runprise/claude-setup.git" "$_REMOTE_TMP" 2>/dev/null \
        || { echo "[ERROR] Konnte Setup-Repo nicht laden."; exit 1; }
    SCRIPT_DIR="$_REMOTE_TMP"
    source "$SCRIPT_DIR/lib/common.sh"
fi

# --- Cleanup bei Abbruch ---

cleanup() {
    release_lock
    # Temp-Verzeichnis aufraemen (falls Remote)
    if [[ -n "${_REMOTE_TMP:-}" ]] && [[ -d "${_REMOTE_TMP:-}" ]]; then
        rm -rf "$_REMOTE_TMP"
    fi
}
trap cleanup EXIT INT TERM

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

# Lock erwerben
mkdir -p "$CLAUDE_DIR"
if ! acquire_lock; then
    exit 1
fi

CONFIG_SRC="$SCRIPT_DIR/config"
VENDOR_SRC="$SCRIPT_DIR/config/_vendored"

if [[ ! -d "$CONFIG_SRC" ]]; then
    error "config/ Verzeichnis nicht gefunden in $SCRIPT_DIR"
    exit 1
fi

# --- Upstream-Sync (wenn lokales Repo mit Submodule) ---
# Bei Remote-Install (curl | bash mit temp-clone) existiert submodule moeglicherweise nicht.
# In dem Fall ueberspringen — VENDOR_SRC bleibt leer, nur Runprise-eigen config wird deployed.

if [[ -f "$SCRIPT_DIR/sync-upstream.sh" ]] && [[ -d "$SCRIPT_DIR/upstream/flagbit/.git" || -f "$SCRIPT_DIR/upstream/flagbit/.git" ]]; then
    info "Synchronisiere Flagbit-Upstream..."
    if "$SCRIPT_DIR/sync-upstream.sh" >/dev/null 2>&1; then
        success "Upstream-Sync abgeschlossen"
    else
        warn "Upstream-Sync fehlgeschlagen — fahre ohne Flagbit-Skills fort"
        VENDOR_SRC=""
    fi
else
    info "Kein Submodule vorhanden — ueberspringe Upstream-Sync"
    VENDOR_SRC=""
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
    if npm install -g @anthropic-ai/claude-code; then
        success "Claude Code installiert"
        track_installed "Claude Code"
    else
        error "Claude Code Installation fehlgeschlagen"
        track_failed "Claude Code"
    fi
fi

# =============================================================================
header "Schritt 3: Konfiguration deployen"
# =============================================================================

info "Kopiere Runprise-Konfiguration nach $CLAUDE_DIR..."

# Hilfsfunktion: Datei installieren mit Manifest-Tracking
install_config_file() {
    local src="$1"
    local rel_path="$2"
    local dest="$CLAUDE_DIR/$rel_path"

    if [[ -f "$dest" ]]; then
        if ask_yes_no "  $rel_path existiert bereits. Ueberschreiben?" "n"; then
            deploy_file "$src" "$dest" "$rel_path" \
                && success "  $rel_path aktualisiert" \
                || { warn "  Fehler bei $rel_path"; track_failed "$rel_path"; return; }
        else
            track_skipped "$rel_path (beibehalten)"
            return
        fi
    else
        mkdir -p "$(dirname "$dest")"
        deploy_file "$src" "$dest" "$rel_path" \
            && success "  $rel_path erstellt" \
            || { warn "  Fehler bei $rel_path"; track_failed "$rel_path"; return; }
    fi
}

# Hilfsfunktion: Vendored-Datei ohne Prompt deployen (Runprise-config kann spaeter ueberschreiben)
install_vendored_file() {
    local src="$1"
    local rel_path="$2"
    local dest="$CLAUDE_DIR/$rel_path"
    mkdir -p "$(dirname "$dest")"
    if deploy_file "$src" "$dest" "$rel_path"; then
        if [[ "$rel_path" == hooks/* ]] || [[ "$rel_path" == *.sh ]]; then
            chmod +x "$dest" 2>/dev/null || true
        fi
        return 0
    fi
    return 1
}

# --- Pass 1: Vendored Flagbit-Artefakte (werden ggf. durch Runprise-config ueberschrieben) ---

if [[ -n "$VENDOR_SRC" ]] && [[ -d "$VENDOR_SRC" ]]; then
    info "Flagbit-Vendored Artefakte..."
    vendored_count=0
    while IFS= read -r -d '' vfile; do
        # Checksums-Datei ueberspringen
        [[ "$(basename "$vfile")" == ".last-sync-checksums" ]] && continue
        rel_path="${vfile#$VENDOR_SRC/}"
        install_vendored_file "$vfile" "$rel_path" && ((vendored_count++)) || true
    done < <(find "$VENDOR_SRC" -type f -print0)
    success "  $vendored_count Flagbit-Artefakte deployed"
    track_installed "Flagbit-Vendored ($vendored_count Dateien)"
fi

# --- Pass 2: Runprise-eigene config/ (ueberschreibt Vendored bei Namensgleichheit) ---

# Hauptdateien
install_config_file "$CONFIG_SRC/CLAUDE.md" "CLAUDE.md"
install_config_file "$CONFIG_SRC/settings.json" "settings.json"
install_config_file "$CONFIG_SRC/.mcp.json" ".mcp.json"

# Rules
info "Rules..."
for rule in "$CONFIG_SRC"/rules/*.md; do
    [[ -f "$rule" ]] || continue
    install_config_file "$rule" "rules/$(basename "$rule")"
done

# Skills
info "Skills..."
for skill_dir in "$CONFIG_SRC"/skills/*/; do
    [[ -d "$skill_dir" ]] || continue
    local_name="$(basename "$skill_dir")"
    install_config_file "$skill_dir/SKILL.md" "skills/$local_name/SKILL.md"
done

# Hooks
info "Hooks..."
for hook in "$CONFIG_SRC"/hooks/*; do
    [[ -f "$hook" ]] || continue
    local_name="$(basename "$hook")"
    install_config_file "$hook" "hooks/$local_name"
    chmod +x "$CLAUDE_DIR/hooks/$local_name" 2>/dev/null || true
done

# Templates
info "Templates..."
for tmpl in "$CONFIG_SRC"/templates/*; do
    [[ -f "$tmpl" ]] || continue
    install_config_file "$tmpl" "templates/$(basename "$tmpl")"
done

# Commands
info "Commands..."
for cmd in "$CONFIG_SRC"/commands/*; do
    [[ -f "$cmd" ]] || continue
    install_config_file "$cmd" "commands/$(basename "$cmd")"
done

track_installed "Konfiguration (Rules, Skills, Hooks, Templates, Commands)"

# Version und Repo-Pfad speichern (fuer Update-Check)
cp "$SCRIPT_DIR/VERSION" "$CLAUDE_DIR/runprise-config-version"
echo "$SCRIPT_DIR" > "$CLAUDE_DIR/runprise-config-repo-path"
success "Version und Repo-Pfad gespeichert (fuer automatischen Update-Check)"

# =============================================================================
header "Schritt 4: Pfade personalisieren"
# =============================================================================

info "Passe Pfade in Konfigurationsdateien an dein System an..."

for target_file in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/.mcp.json"; do
    if replace_placeholders "$target_file"; then
        # Manifest mit dem finalen Checksum aktualisieren
        local_rel="${target_file#$CLAUDE_DIR/}"
        manifest_write "$local_rel" "$(file_checksum "$target_file")"
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
" 2>/dev/null && {
        manifest_write "settings.json" "$(file_checksum "$CLAUDE_DIR/settings.json")"
        success "macOS-spezifische Hooks entfernt"
    } || warn "Konnte macOS-Hooks nicht automatisch entfernen — bitte manuell pruefen"
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

echo -e "${BOLD}npm Global Packages:${NC}"

NPM_PACKAGES=("claudekit")

for pkg in "${NPM_PACKAGES[@]}"; do
    if npm list -g "$pkg" &>/dev/null; then
        success "$pkg bereits installiert"
        track_skipped "$pkg (bereits installiert)"
    else
        if ask_yes_no "  $pkg installieren?"; then
            npm install -g "$pkg" && { success "$pkg installiert"; track_installed "$pkg"; } \
                || { warn "Fehler bei $pkg"; track_failed "$pkg"; }
        else
            track_skipped "$pkg"
        fi
    fi
done

if $HAVE_UV; then
    echo ""
    echo -e "${BOLD}Python Tools (uv):${NC}"
    UV_TOOLS=("claude-code-tools" "claude-monitor" "notebooklm-mcp-cli")
    for tool in "${UV_TOOLS[@]}"; do
        if uv tool list 2>/dev/null | grep -q "$tool"; then
            success "$tool bereits installiert"
            track_skipped "$tool (bereits installiert)"
        else
            if ask_yes_no "  $tool installieren?"; then
                uv tool install "$tool" && { success "$tool installiert"; track_installed "$tool (uv)"; } \
                    || { warn "Fehler bei $tool"; track_failed "$tool"; }
            else
                track_skipped "$tool"
            fi
        fi
    done
fi

if $HAVE_PIPX; then
    echo ""
    echo -e "${BOLD}Python Tools (pipx):${NC}"
    PIPX_TOOLS=("skill-seekers")
    for tool in "${PIPX_TOOLS[@]}"; do
        if pipx list --short 2>/dev/null | grep -q "$tool"; then
            success "$tool bereits installiert"
            track_skipped "$tool (bereits installiert)"
        else
            if ask_yes_no "  $tool installieren?"; then
                pipx install "$tool" && { success "$tool installiert"; track_installed "$tool (pipx)"; } \
                    || { warn "Fehler bei $tool"; track_failed "$tool"; }
            else
                track_skipped "$tool"
            fi
        fi
    done
fi

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
            if curl -fsSL -o "$LOCAL_BIN/lightpanda" "$LIGHTPANDA_URL"; then
                chmod +x "$LOCAL_BIN/lightpanda"
                success "Lightpanda installiert"
                track_installed "Lightpanda"
            else
                rm -f "$LOCAL_BIN/lightpanda"
                warn "Lightpanda Download fehlgeschlagen"
                track_failed "Lightpanda"
            fi
        else
            warn "Keine passende Lightpanda-Version fuer $OS/$ARCH"
            track_failed "Lightpanda"
        fi
    else
        track_skipped "Lightpanda"
    fi
fi

if [[ "$OS" == "macos" ]]; then
    echo ""
    echo -e "${BOLD}macOS Tools:${NC}"
    if command_exists terminal-notifier; then
        success "terminal-notifier bereits installiert"
        track_skipped "terminal-notifier (bereits installiert)"
    else
        if command_exists brew && ask_yes_no "  terminal-notifier installieren? (Desktop-Benachrichtigungen)"; then
            brew install terminal-notifier \
                && { success "terminal-notifier installiert"; track_installed "terminal-notifier"; } \
                || track_failed "terminal-notifier"
        else
            track_skipped "terminal-notifier"
        fi
    fi
fi

# =============================================================================
header "Schritt 7: PATH pruefen"
# =============================================================================

if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    warn "$LOCAL_BIN fehlt in PATH"
    SHELL_RC=""
    [[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
    [[ -z "$SHELL_RC" ]] && [[ -f "$HOME/.bashrc" ]] && SHELL_RC="$HOME/.bashrc"

    if [[ -n "$SHELL_RC" ]] && ask_yes_no "PATH in $SHELL_RC ergaenzen?"; then
        if ! grep -q "export PATH=\"$LOCAL_BIN" "$SHELL_RC" 2>/dev/null; then
            echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$SHELL_RC"
        fi
        success "PATH in $SHELL_RC ergaenzt — neues Terminal oeffnen oder: source $SHELL_RC"
    else
        warn "Bitte manuell ergaenzen: export PATH=\"$LOCAL_BIN:\$PATH\""
    fi
else
    success "PATH ist korrekt konfiguriert"
fi

# =============================================================================
header "Naechste Schritte"
# =============================================================================

echo "  1. Claude Code starten:"
echo -e "     ${CYAN}claude${NC}"
echo ""
echo "  2. Beim ersten Start mit Anthropic Account einloggen"
echo ""
echo "  3. Plugins installieren:"
echo -e "     ${CYAN}~/.claude/install-plugins.sh${NC}"
echo ""
echo "  4. Spaeter aktualisieren:"
echo -e "     ${CYAN}curl -fsSL https://raw.githubusercontent.com/runprise/claude-setup/main/update.sh | bash${NC}"
echo ""

print_summary
success "Setup abgeschlossen!"
