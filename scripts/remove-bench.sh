#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# remove-bench.sh — Guarded teardown helper for a disposable local Bench
#
# Usage:
#   ./scripts/remove-bench.sh <client>
#
# Requires explicit target and confirmation. Refuses to operate on paths
# outside benches/.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
BENCHES_ROOT="benches"
CONFIRM_PROMPT="yes"

# ── Functions ────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $(basename "$0") <client>

Remove a disposable local Bench at ${BENCHES_ROOT}/<client>-bench/.

Arguments:
  <client>  Client or product name (must match the directory used during
            bootstrap, e.g. 'client-x' removes benches/client-x-bench/)

Examples:
  ./scripts/remove-bench.sh client-x
  ./scripts/remove-bench.sh internal-tools

WARNING: This permanently deletes the Bench directory and all its contents
(sites, databases, apps, virtual environments). This operation is NOT
reversible.
EOF
    exit 1
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

info() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*"
}

# ── Guard: argument validation ───────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
    usage
fi

CLIENT="$1"
BENCH_DIR="${BENCHES_ROOT}/${CLIENT}-bench"

# Validate client name (alphanumeric + hyphens, no path traversal)
if [[ ! "$CLIENT" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
    die "Invalid client name '${CLIENT}'. Use alphanumeric characters and hyphens only."
fi

# ── Guard: target path safety ────────────────────────────────────────────────
RESOLVED_DIR="$(cd "$(dirname "$0")/.." && pwd)/${BENCH_DIR}"
EXPECTED_PREFIX="$(cd "$(dirname "$0")/.." && pwd)/${BENCHES_ROOT}/"

if [[ "$RESOLVED_DIR" != "$EXPECTED_PREFIX"* ]]; then
    die "Resolved path '${RESOLVED_DIR}' is outside ${EXPECTED_PREFIX}. Refusing to remove."
fi

if [[ ! -d "$BENCH_DIR" ]]; then
    die "Target '${BENCH_DIR}' does not exist. Nothing to remove."
fi

# Check that it looks like a Bench directory (has expected structure)
if [[ ! -f "${BENCH_DIR}/Procfile" ]] && [[ ! -d "${BENCH_DIR}/apps" ]] && [[ ! -d "${BENCH_DIR}/sites" ]]; then
    warn "Directory '${BENCH_DIR}' does not look like a Bench (missing Procfile, apps/, sites/)."
    warn "Proceeding with removal anyway — you may be removing a non-Bench directory."
fi

# ── Confirmation guard ───────────────────────────────────────────────────────
info "You are about to permanently remove: ${BENCH_DIR}"
du -sh "$BENCH_DIR" 2>/dev/null || true
echo ""
read -r -p "Type '${CONFIRM_PROMPT}' to confirm: " CONFIRMATION
if [[ "$CONFIRMATION" != "$CONFIRM_PROMPT" ]]; then
    info "Confirmation failed. Aborting."
    exit 0
fi

# ── Remove ───────────────────────────────────────────────────────────────────
info "Removing ${BENCH_DIR} ..."
rm -rf "$BENCH_DIR"
info "Removed: ${BENCH_DIR}"
echo ""
echo "[OK] Bench directory deleted. Any related processes (bench start, etc.) must be stopped manually."
