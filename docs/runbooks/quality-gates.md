# Quality Gates Runbook

**Audience**: Contributors preparing changes for review.

**Purpose**: Define the local quality gate workflow and document how to hand off checks to a future CI provider.

---

## Local Gate Workflow

Run the following checks **before** opening a pull request. These are lightweight, dependency-light validations that run without provisioning Frappe or any runtime.

### 1. Workspace Check

```bash
./scripts/check-workspace.sh
```

Validates:
- **No forbidden tracked paths** — `benches/`, `.env`, `venv/`, `node_modules/` must not be tracked.
- **Internal link resolution** — all `[text](path)` references in Markdown files point to existing files.
- **Markdown formatting** — headings have space after `#`, files end with newline, no trailing whitespace flagged.

### 2. Manual Review Checklist

Before submitting a PR, confirm:

- [ ] `git diff` shows only intended changes (no stray files, no runtime artifacts).
- [ ] `git diff --stat` fits within the 400-line review budget (additions + deletions).
- [ ] Conventional Commit format is used: `type(scope): description`.
- [ ] No secrets, credentials, or `.env` files are staged.
- [ ] New scripts are executable (`chmod +x`).
- [ ] Internal documentation links resolve correctly.
- [ ] PR template sections are filled: scope, verification evidence, rollback plan.
- [ ] If adding a runbook or spec, verify cross-references from `README.md` or `CONTRIBUTING.md` are updated.

### 3. Test Evidence

Include test evidence in the PR body. For this repository's control-plane scope:

| Change Type | Expected Evidence |
|-------------|-------------------|
| Script change | Dry-run output or shell-check lint pass |
| Governance policy | Link to the updated document section |
| ADR / runbook | Reviewer walkthrough of the new document |
| Template change | Rendered template output or diff |

---

## Gate by Scope

| Scope | Gate |
|-------|------|
| `scripts/` change | `shellcheck` all modified scripts, run `check-workspace.sh` |
| `docs/` change | Link validation, spell-check recommended |
| `templates/` change | Verify template renders without secrets |
| `.github/` change | Compare against GitHub's template syntax reference |
| `.gitignore` or `.editorconfig` | Verify with `git check-ignore` and editorconfig-checker |

---

## CI Provider Handoff

The local gates are designed to run identically in CI. No Frappe provisioning or remote service is required.

### Handoff Checklist

When a CI provider is chosen:

1. **Enable `scripts/check-workspace.sh`** — wire it as a pre-build job step. Zero dependencies beyond bash/find/grep.
2. **Add Markdown linting** — integrate `markdownlint-cli` or similar for deeper structural checks.
3. **Enforce Conventional Commits** — add a commit-message lint step (e.g., `commitlint`).
4. **Add `shellcheck`** — run on all `.sh` files under `scripts/`.
5. **Configure branch protection** — require checks to pass before merging.

### Provider-Specific Config (placeholder)

```yaml
# Example: GitHub Actions — check-workspace job
# jobs:
#   quality-gate:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Workspace checks
#         run: ./scripts/check-workspace.sh
```

> Replace the block above with the actual CI provider configuration when chosen.

### Provider Selection Criteria

| Criterion | Notes |
|-----------|-------|
| Free-tier minutes | Enough for pre-build quality gates |
| Matrix support | Needed once Frappe multi-version tests are added |
| Secret management | Required for any Frappe runtime tests later |
| Private repo support | This repo is private |

---

## References

- [Script: check-workspace.sh](../../scripts/check-workspace.sh)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — Commit and PR policy
- [PR Template](../../.github/pull_request_template.md)
