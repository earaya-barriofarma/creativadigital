# ADR-001: Control-Plane Repository Topology

**Status:** Accepted

**Date:** 2026-07-15

## Context

Creativa Digital operates as a consultancy that builds Frappe-based solutions for multiple clients. Before any client application exists, we need a workspace that:

1. Versions reusable consultancy standards, templates, and quality policies.
2. Keeps disposable Bench runtimes outside version control.
3. Keeps each custom Frappe app in its own independent repository.
4. Prevents accidental coupling of runtime state, secrets, or client data with consultancy governance.

We considered two approaches:

- **Monorepo**: Commit Bench, sites, apps, and standards together under one repository.
- **Control-plane repo**: Version only governance assets; ignore runtimes; maintain independent app repos.

## Decision

Adopt the **control-plane repository** approach:

| Aspect | Decision |
|--------|----------|
| Source topology | This repository tracks only standards, templates, ADRs, runbooks, and quality policy. |
| Frappe apps | Each custom Frappe app resides in its own independent Git repository. No submodules. |
| Bench runtimes | Every local Bench lives under `benches/<client>-bench/` and is gitignored. |
| Frontend integration | Future frontends are separate products consuming versioned APIs (see ADR-002). |
| DocType creation | Only Frappe migrations create DocType directories; never manual. |

## Consequences

### Positive

- Clean separation of concerns: governance vs. runtime vs. application.
- Disposable Benches: delete a Bench directory without affecting tracked assets.
- Independent release cadence per Frappe app.
- Smaller, focused PRs per repository.
- Explicit integration contracts between layers.

### Negative

- Requires explicit Bench bootstrap workflow (documented in runbooks).
- Developers must clone multiple repositories for full-context work.
- Cross-repo changes need coordinated PRs.

### Neutral

- CI provider and toolchain version decisions are deferred (documented in this repo when selected).
- API contract governance depends on a future ADR for the first client frontend.

## References

- [ADR-002: Frontend API Boundary](../architecture/frontend-api-boundary.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — App-repository rule
- [Local Bench Runbook](../runbooks/local-bench.md)
