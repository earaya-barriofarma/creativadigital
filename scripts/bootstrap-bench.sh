#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# bootstrap-bench.sh — Guarded helper to bootstrap a disposable local Bench
#
# Usage:
#   ./scripts/bootstrap-bench.sh <client>
#
# Validates the target path is under benches/<client>-bench/, checks that
# `bench` is available, creates the directory, and delegates to `bench init`.
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Constants ───────────────────────────────────────────
REQUIRED_COMMANDS=(bench)
BENCHES_ROOT="benches"

# ── Functions ───────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $(basename "$0") <client>

Bootstrap a disposable local Bench under ${BENCHES_ROOT}/<client>-bench/.

Arguments:
  <client>  Client or product name (alphanumeric, hyphens allowed)

Examples:
  ./scripts/bootstrap-bench.sh client-x
  ./scripts/bootstrap-bench.sh internal-tools

Requires: bench (Frappe CLI) installed and on PATH.
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

# ── Guard: argument validation ─────────────────────────────────
if [[ $# -ne 1 ]]; then
    usage
fi

CLIENT="$1"
BENCH_DIR="${BENCHES_ROOT}/${CLIENT}-bench"

# Validate client name (alphanumeric + hyphens, no path traversal)
if [[ ! "$CLIENT" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
    die "Invalid client name '${CLIENT}'. Use alphanumeric characters and hyphens only."
fi

# ── Guard: target path safety ─────────────────────────────────
RESOLVED_DIR="$(cd "$(dirname "$0")/.." && pwd)/${BENCH_DIR}"
EXPECTED_PREFIX="$(cd "$(dirname "$0")/.." && pwd)/${BENCHES_ROOT}/"

if [[ "$RESOLVED_DIR" != "$EXPECTED_PREFIX"* ]]; then
    die "Resolved path '${RESOLVED_DIR}' is outside ${EXPECTED_PREFIX}. Refusing to bootstrap."
fi

if [[ -d "$BENCH_DIR" ]]; then
    die "Target '${BENCH_DIR}' already exists. Use scripts/remove-bench.sh to remove it first."
fi

# ── Guard: prerequisites ────────────────────────────────
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        die "Required command '${cmd}' not found on PATH. Install Frappe Bench first."
    fi
done

# ── Guard: Docker infrastructure ────────────────────────
if ! command -v docker &>/dev/null; then
    die "Docker not found. Install Docker Desktop and run 'docker compose up -d' from the repo root first."
fi

if ! docker compose ps --services --filter "status=running" 2>/dev/null | grep -q "mariadb"; then
    cat <<EOF
[WARN] MariaDB container is not running.
       Start infrastructure from the repo root:
         docker compose up -d
EOF
    # Don't die — the user might have a non-Docker database server running
fi

# ── Bootstrap ─────────────────────────────────────────
info "Creating Bench directory: ${BENCH_DIR}/"
mkdir -p "$BENCH_DIR"

info "Initializing Bench via: bench init ${BENCH_DIR}/"
bench init "${BENCH_DIR}/"

# ── Post-init guidance ───────────────────────────
cat <<EOF

[OK] Bench bootstrapped at ${BENCH_DIR}/

Next steps:
  1. cd ${BENCH_DIR}/
  2. bench get-app <app-repo-url>  # install a custom app from its independent repo
  3. bench new-site <site-name> --db-type mariadb  # create a development site
  4. bench --site <site-name> install-app <app-name>  # always use --site

Reminders:
  - Infrastructure (MariaDB, Redis) must be running: docker compose up -d
  - This directory is gitignored. Your work here is local-only.
  - Never create DocType folders manually — let Frappe migrations create them.
  - Use bare \`bench\` and always pass \`--site <site>\` for site-scoped commands.
  - When done: ./scripts/remove-bench.sh ${CLIENT}
EOF
