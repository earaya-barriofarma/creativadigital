# Quality Gates Runbook

**Audience**: Contributors preparing changes for review.

**Purpose**: Define the local quality gate workflow and the automated CI gate that runs on every pull request and on pushes to integration branches (see [ADR-003](../architecture/ci-provider-adr.md)).

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

## CI Quality Gate (GitHub Actions)

The local gates above now run automatically in CI via [GitHub Actions](https://github.com/features/actions) (see [ADR-003](../architecture/ci-provider-adr.md)). The workflow triggers on every pull request and on every push to `develop`, `qa`, `uat`, or `main`, and reports a single `quality-gate` status check. No Node runner, no secrets, no Frappe provisioning.

### Workflow

```yaml
name: quality-gate

on:
  pull_request:
  push:
    branches: [develop, qa, uat, main]

permissions:
  contents: read

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Workspace checks
        run: ./scripts/check-workspace.sh
      - uses: ludeeus/action-shellcheck@00cae500b08a931fb5698e11e79bfbd38e612a38
        with:
          severity: warning
```

### ShellCheck Authority

ShellCheck runs **in CI** on the hosted runner via the pinned `ludeeus/action-shellcheck` action. ShellCheck is not installed locally by default; `brew install shellcheck` is optional for local parity but CI remains the authority.

### Merge Blocking (manual, post-first-green)

A red `quality-gate` blocks merges wherever the check is **required** on the target branch. Enabling the required check on `develop` is a one-time manual step, performed **after the first green run**:

1. Repository **Settings → Branches → Add branch protection rule** for `develop`.
2. Enable **Require status checks to pass before merging** and select the `quality-gate` check.

Do not enable the required check before the first green run, or the branch becomes unmergeable.

### Repo Visibility

This repo is **public** on GitHub (unlimited Actions minutes apply; repository content is world-readable). Making the repo **private** is a GitHub-side owner action (Settings → General → Danger Zone), not automated here — this workflow contains no secrets and is safe to run either way.

### Deferred (future slices)

- **markdownlint / commitlint** — require a Node runner; deferred.
- **Branch-protection automation** — a repo-settings action cannot live in this PR; the manual step above is the path.

---

## References

- [Script: check-workspace.sh](../../scripts/check-workspace.sh)
- [ADR-003: CI Provider + Quality-Gate Wiring](../architecture/ci-provider-adr.md)
- [CI workflow: quality-gates.yml](../../.github/workflows/quality-gates.yml)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — Commit and PR policy
- [PR Template](../../.github/pull_request_template.md)
