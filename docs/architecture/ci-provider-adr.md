# ADR-003: CI Provider + Quality-Gate Wiring

**Status:** Accepted

**Date:** 2026-08-02

## Context

Control-plane quality gates were local-only (`scripts/check-workspace.sh`) and manual, and `docs/runbooks/quality-gates.md` claimed the repo was private while it is public. ADR-001 explicitly deferred "CI provider and toolchain version decisions (documented in this repo when selected)". The first PR that needs CI has arrived: we need an automated gate that checks every pull request and blocks merges on red, without provisioning Frappe or adding secrets.

Options considered:

- **GitHub Actions (native)** — workflow YAML in-repo; zero new infrastructure; server-side triggers sidestep the git-credential mismatch that blocks local `git push` to this repo; native PR status checks and branch-protection integration.
- **Local githooks / pre-commit** — catches issues earliest but is bypassable, must be installed per machine, and provides no server-side enforcement.
- **Hosted CI (CircleCI / Buildkite / GitLab CI)** — richer features but new accounts, extra auth friction, and no native PR-status integration without setup.

## Decision

Adopt **GitHub Actions** as the CI provider, wired as a single minimal `quality-gate` workflow in `.github/workflows/quality-gates.yml`.

| Aspect | Decision |
|--------|----------|
| Provider | GitHub Actions, one `quality-gate` job on `ubuntu-latest` |
| Triggers | `pull_request` (all) + `push` to `develop`, `qa`, `uat`, `main` |
| Workspace gate | `./scripts/check-workspace.sh` (links, forbidden paths, markdown) |
| Shell quality gate | `ludeeus/action-shellcheck` pinned to SHA `00cae500b08a931fb5698e11e79bfbd38e612a38` (tag 2.0.0), `severity: warning` |
| Permissions | `contents: read` — no secrets, safe on a public repo |
| Action pinning | Immutable refs only (`actions/checkout@v4`, shellcheck SHA) |
| Branch protection | Manual, post-first-green; the workflow never automates repo settings |

The spec originally named `koalaman/shellcheck-action`; that repository does not exist on GitHub (verified via `git ls-remote`). `ludeeus/action-shellcheck` is the canonical Marketplace action that preserves the intent (ShellCheck on `scripts/*.sh`, severity warning, immutable pin, no Node runner). `step-security/action-shellcheck` is the documented hardened drop-in alternative.

## Consequences

### Positive

- Automated health gate on every PR and integration-branch push, with zero new infrastructure.
- Server-side triggers make the git-credential mismatch irrelevant — delivery continues via GitHub API/MCP.
- Native PR status check (`quality-gate`) blocks merges wherever it is required.
- Public repo → unlimited free Actions minutes; tiny workflow keeps cost near zero.

### Negative

- Workflow YAML is new surface; action versions must stay pinned (drift risk managed by pinning policy).
- Mild GitHub lock-in; migrating providers later means rewriting one small YAML file.

### Neutral

- Resolves the ADR-001 deferral "CI provider and toolchain version decisions".
- ShellCheck is CI-only authority today; local `brew install shellcheck` is optional for parity.
- Repo stays public until the owner makes it private — a GitHub-side action, not automated here.

## Frappe Roadmap

This gate intentionally does not provision Frappe or bench. The roadmap below records how the gate scales once Frappe runtime work lands — decisions recorded here, no skeleton until each slice is proposed.

| Slice | When | Requires |
|-------|------|----------|
| markdownlint-cli2 + commitlint | Before stricter doc/commit policy | Node runner + config slice |
| Branch-protection automation | After first green run, when settings drift | repo-settings action slice (cannot live in this PR) |
| Matrix builds + secrets | Frappe multi-version or runtime tests | Matrix config + secret management ADR |
| App-repo CI (`earaya-barriofarma/creativadigital_app`) | When the app needs gates | Separate change in that repository |

## References

- [ADR-001: Control-Plane Repository Topology](../architecture/control-plane-adr.md)
- [ADR-002: Frontend Integration Boundary](../architecture/frontend-api-boundary.md)
- [Quality Gates Runbook](../runbooks/quality-gates.md)
- [Workflow: quality-gates.yml](../../.github/workflows/quality-gates.yml)
