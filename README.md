# Creativa Digital — Development Workspace

**Control-plane repository** for consultancy standards, reusable templates, architecture decisions, runbooks, and quality checks.

This repository does **not** contain client applications, Frappe runtimes, or production artifacts. Each custom Frappe app lives in its own independent Git repository; each local Bench is disposable runtime under an ignored `benches/` directory.

## Topology

```
Tracked control plane (this repo)
  ├── docs/          — ADRs, runbooks, governance
  ├── templates/     — environment stubs, reusable assets
  ├── scripts/       — guarded bootstrap helpers
  └── quality policy — CONTRIBUTING, PR template, checks
          │
          │ bootstrap guidance
          v
Ignored benches/<client>-bench/  ── bare bench ──> local site/runtime
          │                                              │
          └─────────── never committed ──────────────────┘

Future frontend ── versioned /api/v1 contract ──> independent Frappe app repo
```

## Deferrals

The following decisions are deferred to later changes:

| Topic | Deferred Until |
|-------|----------------|
| Frappe major version & supported OS/toolchain | Before first Bench bootstrap |
| Git host & private-repo policy | Before first client app |
| CI provider & provider-specific workflow | Before first PR that needs CI |
| API schema, auth, error envelope design | Before first frontend integration |
| Containers / dev containers | Team consensus on parity needs |
| Production hosting, deployment, monitoring | Client onboarding |

## Quick Links

| Resource | Description |
|----------|-------------|
| [Architecture Decisions](docs/architecture/) | ADR-001: Control-plane topology, ADR-002: Frontend API boundary |
| [Runbooks](docs/runbooks/) | Local Bench lifecycle, quality gates |
| [Contributing](CONTRIBUTING.md) | Commit policy, PR review budget, test evidence |
| [Templates](templates/) | Environment stubs and reusable assets |
