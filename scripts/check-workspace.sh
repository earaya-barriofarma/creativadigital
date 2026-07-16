#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# check-workspace.sh — Dependency-light governance checks for the control plane
#
# Runs locally during development and intended to be wired into CI once a
# provider is chosen. Checks:
#   1. Formatting — Markdown files are well-formed (basic lint)
#   2. Link / reference validation — internal cross-refs resolve
#   3. Forbidden tracked paths — nothing that belongs in runtime/secrets
#
# Depends only on: bash, grep, find, head, sort, uniq, printf
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXIT_CODE=0

# Files and directories that MUST NOT be tracked
FORBIDDEN_PATTERNS=(
    "^benches/"
    "^.env$"
    "^.env\..*"
    "^venv/"
    "^node_modules/"
)

# ── Colors (disabled if not a terminal) ──────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# ── Functions ────────────────────────────────────────────────────────────────

pass() { echo -e "  ${GREEN}[PASS]${NC} $*"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $*"; EXIT_CODE=1; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $*"; }
header() { echo ""; echo "─── $* ───"; }

# ── Check 1: Forbidden tracked paths ─────────────────────────────────────────
header "Forbidden Tracked Paths"

while IFS= read -r -d '' FILE; do
    REL_PATH="${FILE#${ROOT_DIR}/}"
    for PATTERN in "${FORBIDDEN_PATTERNS[@]}"; do
        if [[ "$REL_PATH" =~ $PATTERN ]]; then
            fail "Forbidden tracked path: ${REL_PATH} (matches '${PATTERN}')"
        fi
    done
done < <(find "$ROOT_DIR" -not -path '*/.git/*' -not -name '.git' -type f -print0 2>/dev/null)

if [[ $EXIT_CODE -eq 0 ]]; then
    pass "No forbidden tracked paths found."
fi

# ── Check 2: Internal link validation ────────────────────────────────────────
header "Internal Link / Reference Validation"

# Collect all tracked .md files
MD_FILES=()
while IFS= read -r FILE; do
    MD_FILES+=("$FILE")
done < <(find "$ROOT_DIR" -path '*/.git' -prune -o -name '*.md' -type f -print)

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
    warn "No Markdown files found to check."
else
    LINK_ERRORS=0
    for FILE in "${MD_FILES[@]}"; do
        REL_PATH="${FILE#${ROOT_DIR}/}"
        # Extract markdown links: [text](path)
        while IFS= read -r LINK; do
            # Skip external URLs and anchors
            if echo "$LINK" | grep -qE '^(https?|ftp)://'; then
                continue
            fi
            if echo "$LINK" | grep -qE '^#'; then
                continue
            fi

            # Resolve relative link from the file's directory
            FILE_DIR="$(dirname "$FILE")"
            TARGET="$(cd "$FILE_DIR" 2>/dev/null && realpath -m "$LINK" 2>/dev/null || echo "")"

            if [[ -n "$TARGET" ]] && [[ ! -e "$TARGET" ]] && [[ ! "$LINK" =~ ^https?:// ]]; then
                fail "${REL_PATH}: broken link '${LINK}'"
                LINK_ERRORS=$((LINK_ERRORS + 1))
            fi
        done < <(grep -oP '\[([^\]]+)\]\(([^)]+)\)' "$FILE" | sed -n 's/.*(\([^)]*\)).*/\1/p' 2>/dev/null || true)
    done

    if [[ $LINK_ERRORS -eq 0 ]]; then
        pass "All internal links resolve."
    fi
fi

# ── Check 3: Markdown formatting (basic) ─────────────────────────────────────
header "Markdown Formatting"

MD_ERRORS=0
for FILE in "${MD_FILES[@]}"; do
    REL_PATH="${FILE#${ROOT_DIR}/}"

    # Check: headings have a space after #
    if grep -qnP '^#{2,}([^ #]|$)' "$FILE" 2>/dev/null; then
        fail "${REL_PATH}: headings must have a space after '#' markers"
        MD_ERRORS=$((MD_ERRORS + 1))
    fi

    # Check: no trailing whitespace
    if grep -qnP '[[:space:]]+$' "$FILE" 2>/dev/null; then
        warn "${REL_PATH}: trailing whitespace found (auto-fix with your editor)"
    fi

    # Check: file ends with a newline
    if [[ -s "$FILE" ]] && [[ "$(tail -c 1 "$FILE" | wc -l)" -eq 0 ]]; then
        fail "${REL_PATH}: file does not end with a newline"
        MD_ERRORS=$((MD_ERRORS + 1))
    fi
done

if [[ $MD_ERRORS -eq 0 ]]; then
    pass "Markdown formatting checks passed."
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}[OK] All checks passed.${NC}"
else
    echo -e "${RED}[FAIL] One or more checks failed. Review the output above.${NC}"
fi

exit $EXIT_CODE
