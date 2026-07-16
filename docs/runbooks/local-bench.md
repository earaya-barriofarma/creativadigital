# Local Bench Lifecycle Runbook

**Audience**: Developers bootstrapping local Frappe runtime for a client or product.

**Purpose**: Create, use, and tear down a disposable local Bench under `benches/`. Treat the Bench as runtime state — never commit it.

---

## Prerequisites

| Requirement | Check |
|-------------|-------|
| Docker & Compose | `docker compose version` |
| Frappe Bench CLI installed | `bench --version` |
| Python 3.10+ and `pip` | `python3 --version` |

> **Note**: Supported Frappe version and toolchain are not yet pinned in this repository (see [Deferrals](../../README.md#deferrals)). Verify compatibility before bootstrapping.
>
> Docker is required for the backing infrastructure (MariaDB, Redis). The Bench itself runs natively for speed and simplicity.

---

## Infrastructure

Before creating a Bench, start the shared backing services:

```bash
# From repository root
docker compose up -d
```

This launches:
| Service | Port | Purpose |
|---------|------|---------|
| MariaDB | `3306` | Database for all sites |
| Redis Cache | `6379` | Frappe cache backend |
| Redis Queue | `6380` | Frappe background job queue |

Ports `3306`, `6379`, and `6380` must be free on your host. If something else uses them, stop the conflicting service or update `docker-compose.yml`.

Stop infra when you're done developing:
```bash
docker compose down        # preserves data volumes
docker compose down -v     # destroys all data
```

---

## Create a Bench

### Automated (recommended)

```bash
./scripts/bootstrap-bench.sh <client>
```

The script:
1. Validates `<client>` is a safe alphanumeric name.
2. Confirms the target path resolves under `benches/<client>-bench/`.
3. Checks that `bench` is on `PATH`.
4. Checks that Docker infra services are reachable (MariaDB port `3306`).
5. Creates the directory and runs `bench init`.

> 💡 Run `docker compose up -d` first if you haven't started the infrastructure yet.

### Manual

```bash
# From repository root
mkdir -p benches/<client>-bench
bench init benches/<client>-bench
```

---

## Use a Bench

Always enter the Bench directory and use bare `bench` commands:

```bash
cd benches/<client>-bench
```

### Fetch and install a custom app

```bash
bench get-app <repository-url>
bench --site <site-name> install-app <app-name>
```

### Common operations

| Action | Command |
|--------|---------|
| Create a development site | `bench new-site <site-name> --db-type mariadb` |
| Start development server | `bench start` |
| Run migrations | `bench --site <site-name> migrate` |
| Run console | `bench --site <site-name> console` |
| List apps in site | `bench --site <site-name> list-apps` |
| Build frontend assets | `bench build` |

### Explicit `--site <site>` Rule

**Every site-scoped command MUST include `--site <site-name>`.** Do not rely on a default site context. This keeps operations explicit, auditable, and prevents accidental operations on the wrong site.

Correct:
```bash
bench --site client-x-dev migrate
bench --site client-x-dev console
```

Incorrect (no explicit site):
```bash
bench migrate        # WRONG — which site?
bench console        # WRONG — ambiguous target
```

### DocType Creation — Never Manual

Frappe migrations create DocType directories. **Never create a DocType folder by hand.** Always use:

```bash
bench --site <site-name> make-app <app-name>
# then define the DocType via the app's doctypes/ directory
# and run:
bench --site <site-name> migrate
```

---

## Manage Multiple Sites

A single Bench can host multiple development sites:

```bash
bench new-site site-alpha --db-type mariadb
bench new-site site-beta --db-type mariadb
bench --site site-alpha install-app my-app
bench --site site-beta install-app my-app
bench --site site-alpha migrate
```

Each site is isolated within the Bench's `sites/` directory.

---

## Teardown a Bench

### Automated (recommended)

```bash
./scripts/remove-bench.sh <client>
```

The script:
1. Validates the client name.
2. Confirms the path is under `benches/`.
3. Asks for explicit confirmation (`yes`).
4. Removes the entire Bench directory.

### Manual

```bash
rm -rf benches/<client>-bench
```

> **Warning**: This permanently deletes all sites, databases, apps, and configuration within the Bench. There is no recovery.

---

## Troubleshooting

| Issue | Likely Cause | Resolution |
|-------|--------------|------------|
| `bench: command not found` | Bench CLI not installed or not on PATH | `pip install frappe-bench` |
| `bench init` fails | Missing system dependencies | Check Python, Node.js, Redis, MariaDB versions |
| Site creation fails | Database server not running | `docker compose ps` — should show `mariadb` as healthy |
| Port already in use | Another service running on `3306`, `6379`, or `6380` | Stop the conflicting service or change port mapping in `docker-compose.yml` |
| Docker socket error | Docker Desktop not running | Start Docker Desktop, then `docker compose up -d` |
| Migration errors | App incompatibility or DB schema drift | Verify Frappe version matches app requirements |

---

## References

- [Architecture: Control-Plane Topology](../architecture/control-plane-adr.md)
- [Infrastructure Compose](../../docker-compose.yml)
- [Script: bootstrap-bench.sh](../../scripts/bootstrap-bench.sh)
- [Script: remove-bench.sh](../../scripts/remove-bench.sh)
