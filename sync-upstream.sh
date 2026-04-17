#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Runprise Claude Setup — Upstream Sync
# =============================================================================
# Synchronisiert erlaubte Artefakte aus upstream/flagbit/ nach config/_vendored/.
#
# Usage:
#   ./sync-upstream.sh              # Sync auf aktuell in FLAGBIT_PIN gepinnten Tag
#   ./sync-upstream.sh --bump vX.Y.Z  # Aktualisiert FLAGBIT_PIN, dann Sync
#   ./sync-upstream.sh --help
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_DIR="$SCRIPT_DIR/upstream/flagbit"
VENDOR_DIR="$SCRIPT_DIR/config/_vendored"
ALLOWLIST="$SCRIPT_DIR/upstream/allowlist.conf"
PIN_FILE="$SCRIPT_DIR/FLAGBIT_PIN"
CHECKSUMS_FILE="$VENDOR_DIR/.last-sync-checksums"

# Farben
if [[ -t 1 ]]; then
    RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m' CYAN=$'\033[0;36m' BOLD=$'\033[1m' NC=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

info()    { echo "${BLUE}[INFO]${NC} $*"; }
success() { echo "${GREEN}[OK]${NC} $*"; }
warn()    { echo "${YELLOW}[WARN]${NC} $*"; }
error()   { echo "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo; echo "${BOLD}${CYAN}=== $* ===${NC}"; echo; }

# --- Argumente parsen ---

BUMP_TO=""
for arg in "$@"; do
    case "$arg" in
        --bump)
            error "--bump braucht einen Tag, z.B. --bump=v1.3.0 oder '--bump v1.3.0'"
            exit 1
            ;;
        --bump=*)
            BUMP_TO="${arg#--bump=}"
            ;;
        --help|-h)
            sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            if [[ -n "${_BUMP_NEXT:-}" ]]; then
                BUMP_TO="$arg"
                _BUMP_NEXT=""
            else
                error "Unbekannte Option: $arg"
                exit 1
            fi
            ;;
    esac
done

# Space-getrennte Form: --bump v1.3.0
if [[ -z "$BUMP_TO" ]]; then
    for ((i=1; i<=$#; i++)); do
        if [[ "${!i}" == "--bump" ]] && (( i+1 <= $# )); then
            j=$((i+1))
            BUMP_TO="${!j}"
        fi
    done
fi

# --- Checks ---

if [[ ! -d "$UPSTREAM_DIR/.git" ]] && [[ ! -f "$UPSTREAM_DIR/.git" ]]; then
    error "Submodule upstream/flagbit nicht initialisiert."
    echo "  Fix: git submodule update --init --recursive"
    exit 1
fi

if [[ ! -f "$ALLOWLIST" ]]; then
    error "Allowlist fehlt: $ALLOWLIST"
    exit 1
fi

if [[ ! -f "$PIN_FILE" ]]; then
    error "FLAGBIT_PIN fehlt: $PIN_FILE"
    exit 1
fi

# --- Bump: FLAGBIT_PIN aktualisieren ---

if [[ -n "$BUMP_TO" ]]; then
    info "Bump FLAGBIT_PIN → $BUMP_TO"
    echo "$BUMP_TO" > "$PIN_FILE"
fi

PIN="$(cat "$PIN_FILE")"

# --- Submodule auf Pin-Tag ziehen ---

header "Hole Flagbit-Upstream ($PIN)"

(
    cd "$UPSTREAM_DIR"
    git fetch --tags --quiet 2>&1 || { error "git fetch fehlgeschlagen"; exit 1; }
    if ! git rev-parse --verify "$PIN" >/dev/null 2>&1; then
        error "Tag '$PIN' existiert nicht in upstream/flagbit."
        echo "  Verfuegbare Tags (letzte 10):"
        git tag --sort=-version:refname | head -10 | sed 's/^/    /'
        exit 1
    fi
    git checkout --quiet "$PIN" 2>&1 || { error "git checkout $PIN fehlgeschlagen"; exit 1; }
)

ACTUAL_SHA="$(cd "$UPSTREAM_DIR" && git rev-parse --short HEAD)"
success "Upstream auf $PIN ($ACTUAL_SHA)"

# --- Alte Checksums laden (fuer Diff-Report) ---

declare -A OLD_CHECKSUMS=()
if [[ -f "$CHECKSUMS_FILE" ]]; then
    while IFS=$'\t' read -r sum path; do
        [[ -z "$sum" || -z "$path" ]] && continue
        OLD_CHECKSUMS["$path"]="$sum"
    done < "$CHECKSUMS_FILE"
fi

# --- Vendor-Dir neu anlegen ---

rm -rf "$VENDOR_DIR"
mkdir -p "$VENDOR_DIR/skills" "$VENDOR_DIR/rules"

# --- Allowlist laden ---

# shellcheck disable=SC1090
source "$ALLOWLIST"

# --- Helper: Checksum ---

file_checksum() {
    local f="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | cut -d' ' -f1
    else
        shasum -a 256 "$f" | cut -d' ' -f1
    fi
}

declare -a MISSING=()
declare -a CHANGED=()
declare -a NEW=()
declare -a UNCHANGED=()
declare -A NEW_CHECKSUMS=()

# --- Helper: Vendor-Datei kopieren + Checksum tracken ---

vendor_copy_file() {
    local src="$1" dest_rel="$2"
    local dest="$VENDOR_DIR/$dest_rel"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    local sum
    sum="$(file_checksum "$dest")"
    NEW_CHECKSUMS["$dest_rel"]="$sum"

    local old="${OLD_CHECKSUMS[$dest_rel]:-}"
    if [[ -z "$old" ]]; then
        NEW+=("$dest_rel")
    elif [[ "$old" != "$sum" ]]; then
        CHANGED+=("$dest_rel")
    else
        UNCHANGED+=("$dest_rel")
    fi
}

# --- Skills syncen ---

header "Synchronisiere Skills (${#FLAGBIT_SKILLS[@]})"

for skill in "${FLAGBIT_SKILLS[@]:-}"; do
    [[ -z "$skill" ]] && continue
    skill_dir="$UPSTREAM_DIR/skills/$skill"
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        MISSING+=("skills/$skill")
        error "MISSING: skills/$skill — removed or renamed upstream."
        continue
    fi

    vendor_copy_file "$skill_dir/SKILL.md" "skills/$skill/SKILL.md"

    # Bundled Subdirs mitnehmen (Flagbit-Konvention)
    for subdir in agents scripts eval-viewer assets references; do
        if [[ -d "$skill_dir/$subdir" ]]; then
            while IFS= read -r -d '' sub_file; do
                # Python-Caches und sonstige Build-Artefakte ueberspringen
                case "$sub_file" in
                    *__pycache__*|*.pyc|*.pyo|*/.DS_Store) continue ;;
                esac
                rel="${sub_file#$skill_dir/}"
                vendor_copy_file "$sub_file" "skills/$skill/$rel"
            done < <(find "$skill_dir/$subdir" -type f -print0)
        fi
    done
    echo "  ${GREEN}+${NC} skills/$skill"
done

# --- Rules syncen ---

header "Synchronisiere Rules (${#FLAGBIT_RULES[@]})"

for rule in "${FLAGBIT_RULES[@]:-}"; do
    [[ -z "$rule" ]] && continue
    rule_src="$UPSTREAM_DIR/rules/$rule"
    if [[ ! -f "$rule_src" ]]; then
        MISSING+=("rules/$rule")
        error "MISSING: rules/$rule — removed or renamed upstream."
        continue
    fi
    vendor_copy_file "$rule_src" "rules/$rule"
    echo "  ${GREEN}+${NC} rules/$rule"
done

# --- Libs: Diff-Report, kein Auto-Copy (Runprise-owned) ---

if [[ ${#FLAGBIT_LIBS[@]} -gt 0 ]]; then
    header "Libs (nur Diff-Report — Runprise-owned)"
    for lib in "${FLAGBIT_LIBS[@]:-}"; do
        [[ -z "$lib" ]] && continue
        upstream_lib="$UPSTREAM_DIR/lib/$lib"
        runprise_lib="$SCRIPT_DIR/lib/$lib"
        if [[ ! -f "$upstream_lib" ]]; then
            warn "  Upstream lib fehlt: lib/$lib"
            continue
        fi
        if [[ ! -f "$runprise_lib" ]]; then
            warn "  lib/$lib fehlt lokal — kopiere initial"
            cp "$upstream_lib" "$runprise_lib"
            echo "  ${GREEN}+${NC} lib/$lib (initial copy)"
        else
            up_sum="$(file_checksum "$upstream_lib")"
            rp_sum="$(file_checksum "$runprise_lib")"
            if [[ "$up_sum" == "$rp_sum" ]]; then
                echo "  ${NC}=${NC} lib/$lib (identisch)"
            else
                echo "  ${YELLOW}~${NC} lib/$lib (upstream hat Updates — manueller Diff empfohlen)"
                echo "      diff $runprise_lib $upstream_lib"
            fi
        fi
    done
fi

# --- Checksums persistieren ---

{
    for path in "${!NEW_CHECKSUMS[@]}"; do
        printf '%s\t%s\n' "${NEW_CHECKSUMS[$path]}" "$path"
    done
} > "$CHECKSUMS_FILE"

# --- Zusammenfassung ---

header "Zusammenfassung"

echo "Pin:       $PIN ($ACTUAL_SHA)"
echo "Skills:    ${#FLAGBIT_SKILLS[@]} (allowed)"
echo "Rules:     ${#FLAGBIT_RULES[@]} (allowed)"
echo "Neu:       ${#NEW[@]}"
echo "Geaendert: ${#CHANGED[@]}"
echo "Identisch: ${#UNCHANGED[@]}"
echo "Fehlend:   ${#MISSING[@]}"
echo

if [[ ${#NEW[@]} -gt 0 ]]; then
    echo "${GREEN}Neu in diesem Sync:${NC}"
    printf '  + %s\n' "${NEW[@]}"
    echo
fi

if [[ ${#CHANGED[@]} -gt 0 ]]; then
    echo "${CYAN}Aktualisiert seit letztem Sync:${NC}"
    printf '  ~ %s\n' "${CHANGED[@]}"
    echo
fi

# --- Exit: Fehler wenn MISSING ---

if [[ ${#MISSING[@]} -gt 0 ]]; then
    error "Sync unvollstaendig — ${#MISSING[@]} Eintraege fehlen upstream."
    echo "  Fix-Optionen:"
    echo "    1) Eintraege aus upstream/allowlist.conf entfernen"
    echo "    2) FLAGBIT_PIN auf aeltere Version zurueckdrehen"
    echo "    3) FLAGBIT_PIN hochbumpen falls Namen geaendert wurden"
    exit 1
fi

success "Sync abgeschlossen."
