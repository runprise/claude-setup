#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Runprise Claude Code Setup — Intelligentes Update
# Aktualisiert Team-Konfiguration ohne lokale Aenderungen zu ueberschreiben
# =============================================================================

# --- Library laden ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo "")"
_REMOTE_TMP=""

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    _REMOTE_TMP="$(mktemp -d)"
    trap "rm -rf '$_REMOTE_TMP'" EXIT
    git clone --depth 1 --quiet "https://github.com/runprise/claude-setup.git" "$_REMOTE_TMP" 2>/dev/null \
        || { echo "[ERROR] Konnte Setup-Repo nicht laden."; exit 1; }
    SCRIPT_DIR="$_REMOTE_TMP"
    source "$SCRIPT_DIR/lib/common.sh"
fi

# --- Cleanup ---

cleanup() {
    release_lock
    if [[ -n "${_REMOTE_TMP:-}" ]] && [[ -d "${_REMOTE_TMP:-}" ]]; then
        rm -rf "$_REMOTE_TMP"
    fi
}
trap cleanup EXIT INT TERM

# =============================================================================
header "Runprise Claude Code — Update"
# =============================================================================

OS=$(detect_os)

# Pruefen ob Installation vorhanden
if [[ ! -d "$CLAUDE_DIR" ]]; then
    error "$CLAUDE_DIR existiert nicht. Bitte zuerst install.sh ausfuehren."
    exit 1
fi

# Lock erwerben
if ! acquire_lock; then
    exit 1
fi

CONFIG_SRC="$SCRIPT_DIR/config"

if [[ ! -d "$CONFIG_SRC" ]]; then
    error "config/ Verzeichnis nicht gefunden"
    exit 1
fi

# =============================================================================
header "Aenderungen pruefen"
# =============================================================================

# Pruefen ob Manifest existiert
if [[ ! -f "$MANIFEST_FILE" ]]; then
    warn "Kein Manifest gefunden ($MANIFEST_FILE)."
    warn "Das passiert wenn die Installation vor der Manifest-Funktion stattfand."
    echo ""
    if ask_yes_no "Manifest aus aktuellem Zustand erstellen? (Vorhandene Dateien als Baseline)"; then
        info "Erstelle Manifest aus vorhandenen Dateien..."
        # Alle bekannten Config-Pfade durchgehen und Checksummen speichern
        while IFS= read -r -d '' src_file; do
            rel_path="${src_file#$CONFIG_SRC/}"
            dest="$CLAUDE_DIR/$rel_path"
            if [[ -f "$dest" ]]; then
                manifest_write "$rel_path" "$(file_checksum "$dest")"
            fi
        done < <(find "$CONFIG_SRC" -type f -print0)
        success "Manifest erstellt mit $(wc -l < "$MANIFEST_FILE" | tr -d ' ') Eintraegen"
    else
        warn "Ohne Manifest kann nicht festgestellt werden welche Dateien lokal geaendert wurden."
        warn "Alle vorhandenen Dateien werden als 'lokal geaendert' behandelt."
    fi
fi

# --- Dateien vergleichen und kategorisieren ---

declare -a FILES_NEW=()       # Neu im Repo, lokal nicht vorhanden
declare -a FILES_UPDATE=()    # Repo hat Aenderung, lokal nicht modifiziert
declare -a FILES_CONFLICT=()  # Repo hat Aenderung, aber lokal auch modifiziert
declare -a FILES_UNCHANGED=() # Keine Aenderung im Repo

info "Vergleiche Dateien..."

while IFS= read -r -d '' src_file; do
    rel_path="${src_file#$CONFIG_SRC/}"
    dest="$CLAUDE_DIR/$rel_path"
    src_checksum="$(file_checksum "$src_file")"

    if [[ ! -f "$dest" ]]; then
        # Datei existiert lokal nicht → neu
        FILES_NEW+=("$rel_path")
    else
        local_checksum="$(file_checksum "$dest")"
        manifest_checksum="$(manifest_read "$rel_path")"

        if [[ "$src_checksum" == "$local_checksum" ]]; then
            # Repo und lokal identisch → nichts zu tun
            FILES_UNCHANGED+=("$rel_path")
        elif [[ -z "$manifest_checksum" ]]; then
            # Kein Manifest-Eintrag → als Konflikt behandeln (sicher)
            FILES_CONFLICT+=("$rel_path")
        elif [[ "$manifest_checksum" == "$local_checksum" ]]; then
            # Lokal nicht geaendert seit letztem Deploy → sicher aktualisieren
            FILES_UPDATE+=("$rel_path")
        else
            # Sowohl Repo als auch lokal geaendert → Konflikt
            FILES_CONFLICT+=("$rel_path")
        fi
    fi
done < <(find "$CONFIG_SRC" -type f -print0)

# --- Zusammenfassung anzeigen ---

echo ""

if [[ ${#FILES_NEW[@]} -eq 0 ]] && [[ ${#FILES_UPDATE[@]} -eq 0 ]] && [[ ${#FILES_CONFLICT[@]} -eq 0 ]]; then
    success "Alles aktuell — keine Aenderungen noetig."
    release_lock
    exit 0
fi

if [[ ${#FILES_NEW[@]} -gt 0 ]]; then
    echo -e "${GREEN}Neue Dateien (${#FILES_NEW[@]}):${NC}"
    for f in "${FILES_NEW[@]}"; do echo -e "  ${GREEN}+${NC} $f"; done
    echo ""
fi

if [[ ${#FILES_UPDATE[@]} -gt 0 ]]; then
    echo -e "${CYAN}Aktualisierbar (${#FILES_UPDATE[@]}):${NC}"
    for f in "${FILES_UPDATE[@]}"; do echo -e "  ${CYAN}~${NC} $f"; done
    echo ""
fi

if [[ ${#FILES_CONFLICT[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Lokal geaendert — werden uebersprungen (${#FILES_CONFLICT[@]}):${NC}"
    for f in "${FILES_CONFLICT[@]}"; do echo -e "  ${YELLOW}*${NC} $f"; done
    echo ""
fi

echo -e "Unveraendert: ${#FILES_UNCHANGED[@]} Dateien"
echo ""

# =============================================================================
header "Update ausfuehren"
# =============================================================================

if ! ask_yes_no "Fortfahren?"; then
    info "Update abgebrochen."
    exit 0
fi

# --- Backup erstellen ---

BACKUP_DIR="$CLAUDE_DIR/.runprise-backup-$(date +%Y%m%d%H%M%S)"
NEED_BACKUP=false

if [[ ${#FILES_UPDATE[@]} -gt 0 ]]; then
    NEED_BACKUP=true
fi

if $NEED_BACKUP; then
    mkdir -p "$BACKUP_DIR"
    for rel_path in "${FILES_UPDATE[@]}"; do
        dest="$CLAUDE_DIR/$rel_path"
        if [[ -f "$dest" ]]; then
            backup_dest="$BACKUP_DIR/$rel_path"
            mkdir -p "$(dirname "$backup_dest")"
            cp "$dest" "$backup_dest"
        fi
    done
    info "Backup erstellt: $BACKUP_DIR"
fi

# --- Neue Dateien installieren ---

for rel_path in "${FILES_NEW[@]}"; do
    src="$CONFIG_SRC/$rel_path"
    dest="$CLAUDE_DIR/$rel_path"
    if deploy_file "$src" "$dest" "$rel_path"; then
        # Platzhalter ersetzen in neuen Dateien
        if replace_placeholders "$dest"; then
            manifest_write "$rel_path" "$(file_checksum "$dest")"
        fi
        # Hooks ausfuehrbar machen
        if [[ "$rel_path" == hooks/* ]]; then
            chmod +x "$dest" 2>/dev/null || true
        fi
        success "  + $rel_path"
        track_installed "$rel_path"
    else
        warn "  ! $rel_path fehlgeschlagen"
        track_failed "$rel_path"
    fi
done

# --- Bestehende Dateien aktualisieren ---

for rel_path in "${FILES_UPDATE[@]}"; do
    src="$CONFIG_SRC/$rel_path"
    dest="$CLAUDE_DIR/$rel_path"
    if deploy_file "$src" "$dest" "$rel_path"; then
        # Platzhalter ersetzen
        if replace_placeholders "$dest"; then
            manifest_write "$rel_path" "$(file_checksum "$dest")"
        fi
        if [[ "$rel_path" == hooks/* ]]; then
            chmod +x "$dest" 2>/dev/null || true
        fi
        success "  ~ $rel_path"
        track_updated "$rel_path"
    else
        warn "  ! $rel_path fehlgeschlagen"
        track_failed "$rel_path"
        # Backup wiederherstellen
        if [[ -f "$BACKUP_DIR/$rel_path" ]]; then
            cp "$BACKUP_DIR/$rel_path" "$dest"
            warn "    Backup wiederhergestellt"
        fi
    fi
done

# --- Konflikte dokumentieren ---

for rel_path in "${FILES_CONFLICT[@]}"; do
    track_preserved "$rel_path"
done

# --- Linux: macOS-Hooks entfernen (falls settings.json aktualisiert wurde) ---

settings_updated=false
for rel_path in "${FILES_UPDATE[@]}" "${FILES_NEW[@]}"; do
    [[ "$rel_path" == "settings.json" ]] && settings_updated=true
done

if $settings_updated && [[ "$OS" != "macos" ]] && command_exists python3; then
    info "Linux: Entferne macOS-spezifische Hooks aus neuer settings.json..."
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
        success "macOS-Hooks entfernt"
    } || true
fi

# --- Backup aufraemen wenn alles gut ging ---

if $NEED_BACKUP && [[ ${#_FAILED[@]} -eq 0 ]]; then
    rm -rf "$BACKUP_DIR"
    info "Backup entfernt (alles erfolgreich)"
elif $NEED_BACKUP; then
    warn "Backup beibehalten wegen Fehlern: $BACKUP_DIR"
fi

# --- Alte Backups aufraemen (aelter als 7 Tage) ---

find "$CLAUDE_DIR" -maxdepth 1 -name ".runprise-backup-*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

# =============================================================================

print_summary

if [[ ${#FILES_CONFLICT[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Hinweis:${NC} Lokal geaenderte Dateien wurden nicht ueberschrieben."
    echo "  Um eine Datei manuell zu aktualisieren:"
    echo "  1. Deine Version sichern"
    echo "  2. Datei loeschen"
    echo "  3. Update erneut ausfuehren"
    echo ""
fi

success "Update abgeschlossen!"
