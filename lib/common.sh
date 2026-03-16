#!/usr/bin/env bash
# =============================================================================
# Gemeinsame Funktionen fuer install.sh und update.sh
# Wird per source eingebunden — nicht direkt ausfuehren
# =============================================================================

# --- Konstanten ---

SETUP_REPO="https://github.com/runprise/claude-setup.git"
CLAUDE_DIR="$HOME/.claude"
LOCAL_BIN="$HOME/.local/bin"
NODE_MIN_VERSION=22
MANIFEST_FILE="$CLAUDE_DIR/.runprise-manifest"
LOCK_FILE="$CLAUDE_DIR/.runprise-setup.lock"
PLACEHOLDER="__HOME__"

# --- Farben (deaktiviert wenn kein Terminal) ---

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# --- Logging ---

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

# --- Interaktive Eingabe (funktioniert auch bei curl | bash) ---

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local yn

    # Wenn kein Terminal: Default verwenden
    if [[ ! -t 0 ]] && [[ ! -t 2 ]]; then
        [[ "$default" == "y" ]]
        return
    fi

    # Eingabe von /dev/tty lesen (funktioniert bei curl | bash)
    if [[ "$default" == "y" ]]; then
        echo -en "${YELLOW}$prompt [Y/n]:${NC} " >&2
        read -r yn < /dev/tty 2>/dev/null || yn="$default"
        yn="${yn:-y}"
    else
        echo -en "${YELLOW}$prompt [y/N]:${NC} " >&2
        read -r yn < /dev/tty 2>/dev/null || yn="$default"
        yn="${yn:-n}"
    fi
    [[ "$yn" =~ ^[Yy] ]]
}

# --- Hilfsfunktionen ---

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

# --- Checksummen (plattformunabhaengig) ---

file_checksum() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    if command_exists sha256sum; then
        sha256sum "$file" | cut -d' ' -f1
    elif command_exists shasum; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        # Fallback: md5
        if command_exists md5sum; then
            md5sum "$file" | cut -d' ' -f1
        else
            md5 -q "$file" 2>/dev/null || echo "unknown"
        fi
    fi
}

# --- Lock-Management ---

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            error "Ein anderer Setup-Prozess laeuft bereits (PID $lock_pid)."
            error "Falls nicht, loesche: $LOCK_FILE"
            return 1
        fi
        warn "Veraltete Lock-Datei gefunden — wird entfernt"
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# --- Manifest-Verwaltung ---
# Format: CHECKSUM<TAB>RELATIVE_PATH (relativ zu $CLAUDE_DIR)

manifest_read() {
    # Gibt den gespeicherten Checksum fuer einen relativen Pfad zurueck
    local rel_path="$1"
    if [[ -f "$MANIFEST_FILE" ]]; then
        grep -F "$rel_path" "$MANIFEST_FILE" 2>/dev/null | head -1 | cut -f1
    fi
}

manifest_write() {
    # Setzt den Checksum fuer einen relativen Pfad
    local rel_path="$1"
    local checksum="$2"
    mkdir -p "$(dirname "$MANIFEST_FILE")"
    # Alten Eintrag entfernen (falls vorhanden)
    if [[ -f "$MANIFEST_FILE" ]]; then
        grep -vF "$rel_path" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" 2>/dev/null || true
        mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
    fi
    # Neuen Eintrag hinzufuegen
    printf '%s\t%s\n' "$checksum" "$rel_path" >> "$MANIFEST_FILE"
}

manifest_remove() {
    local rel_path="$1"
    if [[ -f "$MANIFEST_FILE" ]]; then
        grep -vF "$rel_path" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" 2>/dev/null || true
        mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
    fi
}

# --- Sichere Dateioperationen ---

safe_copy() {
    # Kopiert Datei atomar: erst nach .tmp, dann mv
    local src="$1"
    local dest="$2"
    local dest_dir
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    cp "$src" "$dest.tmp" || { error "Kopieren fehlgeschlagen: $src -> $dest"; return 1; }
    mv "$dest.tmp" "$dest" || { error "Verschieben fehlgeschlagen: $dest.tmp -> $dest"; rm -f "$dest.tmp"; return 1; }
}

# Kopiert eine Config-Datei und registriert sie im Manifest
deploy_file() {
    local src="$1"           # Quelldatei (aus config/)
    local dest="$2"          # Zieldatei (in ~/.claude/)
    local rel_path="$3"      # Relativer Pfad fuer Manifest

    safe_copy "$src" "$dest" || return 1
    local checksum
    checksum="$(file_checksum "$dest")"
    manifest_write "$rel_path" "$checksum"
}

# --- Platzhalter-Ersetzung ---

replace_placeholders() {
    local file="$1"
    if [[ -f "$file" ]] && grep -q "$PLACEHOLDER" "$file" 2>/dev/null; then
        local tmp="${file}.placeholder-tmp"
        sed "s|$PLACEHOLDER|$HOME|g" "$file" > "$tmp" && mv "$tmp" "$file"
        return 0
    fi
    return 1
}

# --- Setup-Repo holen ---

fetch_setup_repo() {
    local script_dir="${1:-}"

    # Fall 1: Lokale Ausfuehrung — config/ liegt neben dem Script
    if [[ -n "$script_dir" ]] && [[ -f "$script_dir/config/CLAUDE.md" ]]; then
        echo "$script_dir"
        return 0
    fi

    # Fall 2: Remote (curl | bash) — temporaer klonen
    local tmp_dir
    tmp_dir="$(mktemp -d)" || { error "Konnte temp-Verzeichnis nicht erstellen"; return 1; }
    info "Lade Setup-Repo herunter..."
    if ! git clone --depth 1 --quiet "$SETUP_REPO" "$tmp_dir" 2>/dev/null; then
        rm -rf "$tmp_dir"
        error "Git clone fehlgeschlagen. Pruefen: Netzwerk, Git installiert, Repo-Zugang"
        return 1
    fi
    echo "$tmp_dir"
}

# --- Tracking (fuer Zusammenfassung) ---

declare -a _INSTALLED=()
declare -a _SKIPPED=()
declare -a _FAILED=()
declare -a _UPDATED=()
declare -a _PRESERVED=()

track_installed()  { _INSTALLED+=("$1"); }
track_skipped()    { _SKIPPED+=("$1"); }
track_failed()     { _FAILED+=("$1"); }
track_updated()    { _UPDATED+=("$1"); }
track_preserved()  { _PRESERVED+=("$1"); }

print_summary() {
    header "Zusammenfassung"

    if [[ ${#_INSTALLED[@]} -gt 0 ]]; then
        echo -e "${GREEN}Installiert:${NC}"
        for c in "${_INSTALLED[@]}"; do echo -e "  ${GREEN}+${NC} $c"; done
    fi
    if [[ ${#_UPDATED[@]} -gt 0 ]]; then
        echo ""
        echo -e "${CYAN}Aktualisiert:${NC}"
        for c in "${_UPDATED[@]}"; do echo -e "  ${CYAN}~${NC} $c"; done
    fi
    if [[ ${#_PRESERVED[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Lokal geaendert (beibehalten):${NC}"
        for c in "${_PRESERVED[@]}"; do echo -e "  ${YELLOW}*${NC} $c"; done
    fi
    if [[ ${#_SKIPPED[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Uebersprungen:${NC}"
        for c in "${_SKIPPED[@]}"; do echo -e "  ${YELLOW}-${NC} $c"; done
    fi
    if [[ ${#_FAILED[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Fehlgeschlagen:${NC}"
        for c in "${_FAILED[@]}"; do echo -e "  ${RED}!${NC} $c"; done
    fi
    echo ""
}
